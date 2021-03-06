require "keisan/version"
require "keisan/exceptions"
require "keisan/util"

require "keisan/ast/node"
require "keisan/ast/cell"

require "keisan/ast/literal"
require "keisan/ast/variable"
require "keisan/ast/constant_literal"
require "keisan/ast/number"
require "keisan/ast/string"
require "keisan/ast/null"
require "keisan/ast/boolean"

require "keisan/ast/block"
require "keisan/ast/parent"
require "keisan/ast/operator"
require "keisan/ast/assignment"
require "keisan/ast/multi_line"
require "keisan/ast/unary_operator"
require "keisan/ast/unary_identity"
require "keisan/ast/unary_plus"
require "keisan/ast/unary_minus"
require "keisan/ast/unary_inverse"
require "keisan/ast/unary_bitwise_not"
require "keisan/ast/unary_logical_not"
require "keisan/ast/arithmetic_operator"
require "keisan/ast/plus"
require "keisan/ast/times"
require "keisan/ast/exponent"
require "keisan/ast/modulo"
require "keisan/ast/function"
require "keisan/ast/bitwise_operator"
require "keisan/ast/bitwise_and"
require "keisan/ast/bitwise_or"
require "keisan/ast/bitwise_xor"
require "keisan/ast/logical_operator"
require "keisan/ast/logical_and"
require "keisan/ast/logical_or"
require "keisan/ast/logical_equal"
require "keisan/ast/logical_not_equal"
require "keisan/ast/logical_less_than"
require "keisan/ast/logical_greater_than"
require "keisan/ast/logical_less_than_or_equal_to"
require "keisan/ast/logical_greater_than_or_equal_to"
require "keisan/ast/function"
require "keisan/ast/list"
require "keisan/ast/hash"
require "keisan/ast/indexing"

require "keisan/ast/line_builder"
require "keisan/ast/builder"
require "keisan/ast"

require "keisan/function"
require "keisan/functions/proc_function"
require "keisan/functions/expression_function"
require "keisan/functions/registry"
require "keisan/functions/default_registry"
require "keisan/variables/registry"
require "keisan/variables/default_registry"
require "keisan/context"

require "keisan/token"
require "keisan/tokens/comma"
require "keisan/tokens/colon"
require "keisan/tokens/dot"
require "keisan/tokens/group"
require "keisan/tokens/number"
require "keisan/tokens/operator"
require "keisan/tokens/string"
require "keisan/tokens/null"
require "keisan/tokens/boolean"
require "keisan/tokens/assignment"
require "keisan/tokens/arithmetic_operator"
require "keisan/tokens/logical_operator"
require "keisan/tokens/bitwise_operator"
require "keisan/tokens/word"
require "keisan/tokens/line_separator"
require "keisan/tokens/unknown"

require "keisan/tokenizer"

require "keisan/parsing/component"

require "keisan/parsing/element"
require "keisan/parsing/number"
require "keisan/parsing/string"
require "keisan/parsing/null"
require "keisan/parsing/boolean"
require "keisan/parsing/dot"
require "keisan/parsing/dot_word"
require "keisan/parsing/dot_operator"
require "keisan/parsing/variable"
require "keisan/parsing/function"
require "keisan/parsing/group"
require "keisan/parsing/round_group"
require "keisan/parsing/square_group"
require "keisan/parsing/curly_group"
require "keisan/parsing/list"
require "keisan/parsing/hash"
require "keisan/parsing/indexing"
require "keisan/parsing/argument"
require "keisan/parsing/line_separator"

require "keisan/parsing/operator"

require "keisan/parsing/assignment"
require "keisan/parsing/compound_assignment"

require "keisan/parsing/unary_operator"
require "keisan/parsing/unary_plus"
require "keisan/parsing/unary_minus"

require "keisan/parsing/arithmetic_operator"
require "keisan/parsing/plus"
require "keisan/parsing/minus"
require "keisan/parsing/times"
require "keisan/parsing/divide"
require "keisan/parsing/exponent"
require "keisan/parsing/modulo"
require "keisan/parsing/bitwise_operator"
require "keisan/parsing/bitwise_and"
require "keisan/parsing/bitwise_or"
require "keisan/parsing/bitwise_xor"
require "keisan/parsing/bitwise_not"
require "keisan/parsing/bitwise_not_not"
require "keisan/parsing/logical_operator"
require "keisan/parsing/logical_less_than"
require "keisan/parsing/logical_greater_than"
require "keisan/parsing/logical_less_than_or_equal_to"
require "keisan/parsing/logical_greater_than_or_equal_to"
require "keisan/parsing/logical_and"
require "keisan/parsing/logical_or"
require "keisan/parsing/logical_equal"
require "keisan/parsing/logical_not_equal"
require "keisan/parsing/logical_not"
require "keisan/parsing/logical_not_not"

require "keisan/parser"

require "keisan/calculator"
require "keisan/evaluator"

module Keisan
  def self.calculator
    @@calculator ||= Calculator.new
  end

  def self.reset
    @@calculator = nil
  end

  def self.[](expression)
    simplify(expression)
  end

  def self.evaluate(expression)
    calculator.evaluate(expression)
  end

  def self.simplify(expression)
    calculator.simplify(expression)
  end

  def self.ast(expression)
    calculator.ast(expression)
  end
end
