module SymbolicMath
  module Tokens
    class BitwiseOperator < Token
      AND = /(?:\&)/
      OR = /(?:\|)/
      XOR = /(?:\^)/
      NOT = /(?:\~+)/

      REGEX = /(#{AND}|#{OR}|#{XOR}|#{NOT})/

      def self.regex
        REGEX
      end

      def operator_type
        case string
        when AND
          :"&"
        when OR
          :"|"
        when XOR
          :"^"
        when NOT
          string.count("~").even? ? :"~~" : :"~"
        end
      end
    end
  end
end
