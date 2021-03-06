module Keisan
  class Tokenizer
    TOKEN_CLASSES = [
      Tokens::Group,
      Tokens::String,
      Tokens::Null,
      Tokens::Boolean,
      Tokens::Word,
      Tokens::Number,
      Tokens::Assignment,
      Tokens::LogicalOperator,
      Tokens::ArithmeticOperator,
      Tokens::BitwiseOperator,
      Tokens::Comma,
      Tokens::Colon,
      Tokens::Dot,
      Tokens::LineSeparator,
      Tokens::Unknown
    ]

    TOKEN_REGEX = Regexp::new(
      TOKEN_CLASSES.map(&:regex).join("|")
    )

    attr_reader :expression, :tokens

    def initialize(expression)
      @expression = self.class.normalize_expression(expression)
      @scan = @expression.scan(TOKEN_REGEX)
      @tokens = tokenize!
    end

    def self.normalize_expression(expression)
      expression = normalize_line_delimiters(expression)
      expression = remove_comments(expression)
    end

    private

    def self.normalize_line_delimiters(expression)
      expression.gsub(/\n/, ";")
    end

    def self.remove_comments(expression)
      expression.gsub(/#[^;]*/, "")
    end

    def tokenize!
      @scan.map do |scan_result|
        i = scan_result.find_index {|token| !token.nil?}
        token_string = scan_result[i]
        token = TOKEN_CLASSES[i].new(token_string)
        if token.is_a?(Tokens::Unknown)
          raise Keisan::Exceptions::TokenizingError.new("Unexpected token: \"#{token.string}\"")
        end
        token
      end
    end
  end
end
