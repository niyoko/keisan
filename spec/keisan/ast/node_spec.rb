require "spec_helper"

RSpec.describe Keisan::AST::Node do
  describe "unbound_variables" do
    it "returns a Set of the undefined variable names" do
      ast = Keisan::AST::Builder.new(string: "pi").ast
      expect(ast.unbound_variables).to eq Set.new

      ast = Keisan::AST::Builder.new(string: "x").ast
      expect(ast.unbound_variables).to eq Set.new(["x"])

      ast = Keisan::AST::Builder.new(string: "x + y").ast
      expect(ast.unbound_variables).to eq Set.new(["x", "y"])

      context = Keisan::Context.new
      context.register_variable!("x", 0)
      expect(ast.unbound_variables(context)).to eq Set.new(["y"])
    end
  end

  describe "unbound_functions" do
    it "returns a Set of the undefined functions names" do
      ast = Keisan::AST::Builder.new(string: "sin").ast
      expect(ast.unbound_functions).to eq Set.new

      ast = Keisan::AST::Builder.new(string: "f(0)").ast
      expect(ast.unbound_functions).to eq Set.new(["f"])

      ast = Keisan::AST::Builder.new(string: "f(g(0), h())").ast
      expect(ast.unbound_functions).to eq Set.new(["f", "g", "h"])

      context = Keisan::Context.new
      context.register_function!("g", Proc.new { 1 })
      expect(ast.unbound_functions(context)).to eq Set.new(["f", "h"])
    end
  end


  describe "==" do
    it "is true if the AST have the same structure and nodes" do
      s = "3 * (2 + f(sin(x), g(x)))"
      s_same = "3*(2+f(sin(x),g(x)))"
      s_diff_var = "3 * (2 + f(sin(x), g(y)))"
      s_diff_expr = "3 * (1 + 1 + f(sin(x), g(y)))"

      expect(Keisan::AST::Builder.new(string: s_same).ast).to eq(Keisan::AST::Builder.new(string: s).ast)
      expect(Keisan::AST::Builder.new(string: s_diff_var).ast).not_to eq(Keisan::AST::Builder.new(string: s).ast)
      expect(Keisan::AST::Builder.new(string: s_diff_expr).ast).not_to eq(Keisan::AST::Builder.new(string: s).ast)

      expect(Keisan::AST::Builder.new(string: "1+2+3").ast).not_to eq(Keisan::AST::Builder.new(string: "1+(2+3)").ast)
    end
  end

  describe "deep_dup" do
    it "duplicates an AST recursively" do
      ast = Keisan::AST::Builder.new(string: "2 * (1 + f(sin(x), g(x)))").ast
      ast_dup = ast.deep_dup
      expect(ast_dup).not_to equal(ast)
      expect(ast_dup).to eq(ast)
    end
  end

  describe "simplify" do
    context "just numbers and arithmetic" do
      it "simplifies the expression" do
        ast = Keisan::AST::Builder.new(string: "1 + 3 + 5").ast
        ast_simple = ast.simplified
        expect(ast_simple).not_to eq(ast)
        expect(ast_simple).to be_a(Keisan::AST::Number)
        expect(ast_simple.value).to eq 9

        ast = Keisan::AST::Builder.new(string: "3 * (2+5)").ast
        ast_simple = ast.simplified
        expect(ast_simple).not_to eq(ast)
        expect(ast_simple).to be_a(Keisan::AST::Number)
        expect(ast_simple.value).to eq 21
      end
    end

    context "numbers and variables" do
      it "simplifies the expression, leaving the varible alone" do
        ast = Keisan::AST::Builder.new(string: "10 + x + 5 + y").ast
        ast_simple = ast.simplified
        expect(ast_simple).not_to eq(ast)
        expect(ast_simple).to be_a(Keisan::AST::Plus)
        expect(ast_simple.children[0].value).to eq 15
        expect(ast_simple.children[1].name).to eq "x"
        expect(ast_simple.children[2].name).to eq "y"
      end
    end
  end
end
