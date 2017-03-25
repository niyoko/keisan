module Keisan
  module AST
    class Builder
      # Build from parser
      def initialize(string: nil, parser: nil, components: nil)
        if [string, parser, components].select(&:nil?).size != 2
          raise Keisan::Exceptions::InternalError.new("Require one of string, parser or components")
        end

        if !string.nil?
          @components = Keisan::Parser.new(string: string).components
        elsif !parser.nil?
          @components = parser.components
        else
          @components = Array.wrap(components)
        end

        @nodes = nodes_split_by_operators(@components)
        @operators = @components.select {|component| component.is_a?(Keisan::Parsing::Operator)}

        consume_operators!

        unless @nodes.count == 1
          raise Keisan::Exceptions::ASTError.new("Should end up with a single node")
        end
      end

      def node
        @nodes.first
      end

      def ast
        node
      end

      private

      def nodes_split_by_operators(components)
        components.split {|component|
          component.is_a?(Keisan::Parsing::Operator)
        }.map {|group_of_components|
          node_from_components(group_of_components)
        }
      end

      def node_from_components(components)
        unary_components, node, postfix_components = *unarys_node_postfixes(components)

        # Apply postfix operators
        postfix_components.each do |postfix_component|
          node = apply_postfix_component_to_node(postfix_component, node)
        end

        # Apply prefix unary operators
        unary_components.reverse.each do |unary_component|
          node = unary_component.node_class.new(node)
        end

        node
      end

      def apply_postfix_component_to_node(postfix_component, node)
        case postfix_component
        when Keisan::Parsing::Indexing
          postfix_component.node_class.new(
            node,
            postfix_component.arguments.map {|parsing_argument|
              Builder.new(components: parsing_argument.components).node
            }
          )
        when Keisan::Parsing::DotWord
          Keisan::AST::Function.build(
            postfix_component.name,
            [node]
          )
        when Keisan::Parsing::DotOperator
          Keisan::AST::Function.build(
            postfix_component.name,
            [node] + postfix_component.arguments.map {|parsing_argument|
              Builder.new(components: parsing_argument.components).node
            }
          )
        else
          raise Keisan::Exceptions::ASTError.new("Invalid postfix component #{postfix_component}")
        end
      end

      # Returns an array of the form
      # [unary_operators, middle_node, postfix_operators]
      # unary_operators is an array of Keisan::Parsing::UnaryOperator objects
      # middle_node is the main node which will be modified by prefix and postfix operators
      # postfix_operators is an array of Keisan::Parsing::Indexing, DotWord, and DotOperator objects
      def unarys_node_postfixes(components)
        index_of_unary_components = components.map.with_index {|c,i| [c,i]}.select {|c,i| c.is_a?(Keisan::Parsing::UnaryOperator)}.map(&:last)
        # Must be all in the front
        unless index_of_unary_components.map.with_index.all? {|i,j| i == j}
          raise Keisan::Exceptions::ASTError.new("unary operators must be in front")
        end

        index_of_postfix_components = components.map.with_index {|c,i| [c,i]}.select {|c,i|
          c.is_a?(Keisan::Parsing::Indexing) || c.is_a?(Keisan::Parsing::DotWord) || c.is_a?(Keisan::Parsing::DotOperator)
        }.map(&:last)
        unless index_of_postfix_components.reverse.map.with_index.all? {|i,j| i + j == components.size - 1 }
          raise Keisan::Exceptions::ASTError.new("postfix components must be in back")
        end

        num_unary   = index_of_unary_components.size
        num_postfix = index_of_postfix_components.size

        unless num_unary + 1 + num_postfix == components.size
          raise Keisan::Exceptions::ASTError.new("have too many components")
        end

        [
          index_of_unary_components.map {|i| components[i]},
          node_of_component(components[index_of_unary_components.size]),
          index_of_postfix_components.map {|i| components[i]}
        ]
      end

      def node_of_component(component)
        case component
        when Keisan::Parsing::Number
          Keisan::AST::Number.new(component.value)
        when Keisan::Parsing::String
          Keisan::AST::String.new(component.value)
        when Keisan::Parsing::Null
          Keisan::AST::Null.new
        when Keisan::Parsing::Variable
          Keisan::AST::Variable.new(component.name)
        when Keisan::Parsing::Boolean
          Keisan::AST::Boolean.new(component.value)
        when Keisan::Parsing::List
          Keisan::AST::List.new(
            component.arguments.map {|parsing_argument|
              Builder.new(components: parsing_argument.components).node
            }
          )
        when Keisan::Parsing::Group
          Builder.new(components: component.components).node
        when Keisan::Parsing::Function
          Keisan::AST::Function.build(
            component.name,
            component.arguments.map {|parsing_argument|
              Builder.new(components: parsing_argument.components).node
            }
          )
        when Keisan::Parsing::DotWord
          Keisan::AST::Function.build(
            component.name,
            [node_of_component(component.target)]
          )
        when Keisan::Parsing::DotOperator
          Keisan::AST::Function.build(
            component.name,
            [node_of_component(component.target)] + component.arguments.map {|parsing_argument|
              Builder.new(components: parsing_argument.components).node
            }
          )
        else
          raise Keisan::Exceptions::ASTError.new("Unhandled component, #{component}")
        end
      end

      def consume_operators!
        while @operators.count > 0
          priorities = @operators.map(&:priority)
          max_priority = priorities.uniq.max
          consume_operators_with_priority!(max_priority)
        end
      end

      def consume_operators_with_priority!(priority)
        # Treat back-to-back operators with same priority as one single call (e.g. 1 + 2 + 3 is add(1,2,3))
        while @operators.any? {|operator| operator.priority == priority}
          next_operator_group = @operators.each.with_index.to_a.split {|operator,i|
            operator.priority != priority
          }.select {|ops| !ops.empty?}.first
          operator_group_indexes = next_operator_group.map(&:last)

          first_index = operator_group_indexes.first
          last_index  = operator_group_indexes.last

          replacement_node = next_operator_group.first.first.node_class.new(
            children = @nodes[first_index..(last_index+1)],
            parsing_operators = @operators[first_index..last_index]
          )

          @nodes.delete_if.with_index {|node, i| i >= first_index && i <= last_index+1}
          @operators.delete_if.with_index {|node, i| i >= first_index && i <= last_index}
          @nodes.insert(first_index, replacement_node)
        end
      end
    end
  end
end
