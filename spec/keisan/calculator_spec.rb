require "spec_helper"

RSpec.describe Keisan::Calculator do
  let(:calculator) { described_class.new }

  it "calculates correctly" do
    expect(calculator.evaluate("1 + 2")).to eq 3
    expect(calculator.evaluate("2*x + 4", x: 3)).to eq 10
    expect(calculator.evaluate("2 / 3 ** 2")).to eq Rational(2,9)
  end

  it "does nothing for blank strings" do
    expect(calculator.evaluate("  ")).to eq nil
  end

  it "ignores comments" do
    expect(calculator.evaluate("# Hello world")).to eq nil
    expect(calculator.evaluate("2 + 3 # 4")).to eq 5
    expect(calculator.evaluate("# Initial comment\n 1+2\n 123 # Real result\n# Trailing comment\n")).to eq 123
  end

  it "can handle custom functions" do
    expect(calculator.evaluate("2*f(x) + 4", x: 3, f: Proc.new {|x| x**2})).to eq 2*9+4
  end

  context "direct concatenation is multiplication" do
    it "works as expected in regular math notation" do
      calculator.evaluate("x = 2; y = 3; z = 4")
      expect(calculator.evaluate("(x+1)(y + 2z)")).to eq (2+1)*(3+2*4)
    end
  end

  context "list operations" do
    it "evaluates lists" do
      expect(calculator.evaluate("[2, 3, 5, 8]")).to eq [2,3,5,8]
    end

    it "can index lists" do
      expect(calculator.evaluate("[[1,2,3],[4,5,6],[7,8,9]][1][2]")).to eq 6
    end

    it "can concatenate lists using +" do
      expect(calculator.evaluate("[3, 5] + [10, 11]")).to eq [3, 5, 10, 11]
    end

    it "can change elements of lists" do
      calculator.evaluate("a = [[1,2,3], [4,5,6], [7,8,9]]")
      calculator.evaluate("a[0] = 10")
      calculator.evaluate("a[1] = [40,50,60]")
      calculator.evaluate("a[2][0] = 11")
      expect{calculator.evaluate("a[3] = 5")}.to raise_error(Keisan::Exceptions::InvalidExpression)

      expect(calculator.evaluate("a")).to eq([10, [40,50,60], [11,8,9]])
    end

    it "can change elements of lists using other list elements" do
      calculator.evaluate("a = [[1,2,3], [4,5,6], [7,8,9]]")

      calculator.evaluate("a[0][0] = a[1][1]")
      expect(calculator.evaluate("a")).to eq([[5,2,3], [4,5,6], [7,8,9]])

      calculator.evaluate("a[2] = a[0]")
      calculator.evaluate("a[2][0] = 10")
      expect(calculator.evaluate("a")).to eq([[5,2,3], [4,5,6], [10,2,3]])
    end

    it "can mix lists and hashes" do
      calculator.evaluate("a = [5, 11, {'a': 20, 'b': 33}]")
      calculator.evaluate("h = {'c': [1,2,3], 'd': 4}")

      calculator.evaluate("a[2]['c'] = h['d']")
      calculator.evaluate("a[2]['a'] = h['c'][0]")
      expect(calculator.evaluate("a").value).to eq [5, 11, {"a" => 1, "b" => 33, "c" => 4}]
      calculator.evaluate("h['c'][1] = a[2]['b']")
      expect(calculator.evaluate("h").value).to eq({"c" => [1,33,3], "d" => 4})
    end
  end

  context "hash operations" do
    it "evaluates hashes" do
      expect(calculator.evaluate("{'a': 1, 'b': 2}")).to eq({"a" => 1, "b" => 2})
    end

    it "can index hashes" do
      expect(calculator.evaluate("{'foo': 1, 'bar': 2}['foo']")).to eq 1
      expect(calculator.evaluate("{'foo': 1, 'bar': 2}['b'+'ar']")).to eq 2
      expect(calculator.evaluate("{'foo': 1, 'bar': 2}['baz']")).to eq nil
    end

    it "can change elements of hashes" do
      calculator.evaluate("h = {'foo': 100, 'bar': 200}")

      expect {
        calculator.evaluate("h['foo'] = 99")
      }.to change {
        calculator.evaluate("h['foo']")
      }.from(100).to(99)

      expect {
        calculator.evaluate("h['baz'] = 300")
      }.to change {
        calculator.evaluate("h['baz']")
      }.from(nil).to(300)

      calculator.evaluate("my_string = 'fo'")
      expect(calculator.evaluate("h[my_string + 'o']")).to eq 99
    end

    it "can change elements of hashes using other list elements" do
      calculator.evaluate("h = {'a': 1, 'b': 2, 'c': 3}")

      calculator.evaluate("h['a'] = h['c']")
      expect(calculator.evaluate("h").value).to eq ({"a" => 3, "b" => 2, "c" => 3})
      calculator.evaluate("h['a'] = h['b']")
      expect(calculator.evaluate("h").value).to eq ({"a" => 2, "b" => 2, "c" => 3})
    end

    it "can use anything as keys" do
      calculator.evaluate("h = {'a': 1, 10: 2, true: 3}")
      expect(calculator.evaluate("h").value).to eq({"a" => 1, 10 => 2, true => 3})
      calculator.evaluate("h[10] = h[true]")
      calculator.evaluate("h[true] = 'hello'")
      expect(calculator.evaluate("h").value).to eq({"a" => 1, 10 => 3, true => "hello"})
    end

    describe "#to_s" do
      it "outputs correct hash format" do
        hash_string = "{'a': 1, 'b': 2}"
        expect(calculator.ast(hash_string).to_s).to eq hash_string
      end
    end
  end

  describe "#simplify" do
    it "allows for undefined variables to still exist and returns a string representation of the expression" do
      expect{calculator.evaluate("0*x+1")}.to raise_error(Keisan::Exceptions::UndefinedVariableError)
      expect(calculator.simplify("0*x+1").to_s).to eq "1"
    end
  end

  describe "#ast" do
    it "returns the abstract syntax tree parsed from the expression" do
      ast = calculator.ast("x**2+1")
      expect(ast).to be_a(Keisan::AST::Plus)

      expect(ast.children[0]).to be_a(Keisan::AST::Exponent)
      expect(ast.children[0].children[0]).to be_a(Keisan::AST::Variable)
      expect(ast.children[0].children[0].name).to eq "x"
      expect(ast.children[0].children[1]).to be_a(Keisan::AST::Number)
      expect(ast.children[0].children[1].value).to eq 2

      expect(ast.children[1]).to be_a(Keisan::AST::Number)
      expect(ast.children[1].value).to eq 1
    end
  end

  describe "defining variables and functions" do
    it "saves them in the calculators context" do
      calculator.define_variable!("x", 5)
      expect(calculator.evaluate("x + 1")).to eq 6
      expect(calculator.evaluate("x + 1", x: 10)).to eq 11
      expect(calculator.evaluate("x + 1")).to eq 6

      calculator.define_function!("f", Proc.new {|x| 3*x})
      expect(calculator.evaluate("f(2)")).to eq 6
      expect(calculator.evaluate("f(2)", f: Proc.new {|x| 10*x})).to eq 20
      expect(calculator.evaluate("f(2)")).to eq 6
      expect(calculator.evaluate("2.f")).to eq 6
      expect(calculator.evaluate("2.f()")).to eq 6
    end
  end

  context "dot operators mixed with list indexings" do
    it "parses in correct order" do
      calculator.define_function!("f", Proc.new {|x| [[x-1,x+1], [x-2,x,x+2]]})
      expect(calculator.evaluate("4.f")).to eq [[3,5], [2,4,6]]
      expect(calculator.evaluate("4.f[0]")).to eq [3,5]
      expect(calculator.evaluate("4.f[0].size+0")).to eq 2
      expect(calculator.evaluate("4.f[1]")).to eq [2,4,6]
      expect(calculator.evaluate("4.f[1].size*2")).to eq 6
    end
  end

  context "modulo operator" do
    it "works as expected" do
      expect(calculator.evaluate("95 % 7 % 5")).to eq 4
      expect(calculator.evaluate("(95 % 7) % 5")).to eq 4
      expect(calculator.evaluate("95 % (7 % 5)")).to eq 1
    end
  end

  describe "defining variables" do
    it "raises an error if there is an undefined variable" do
      expect{calculator.evaluate("x = y")}.to raise_error(Keisan::Exceptions::UndefinedVariableError)
    end

    it "can define variables" do
      expect(calculator.evaluate("y = 2")).to eq 2
      expect(calculator.evaluate("y")).to eq 2

      expect(calculator.evaluate("x = 2*y")).to eq 4
      expect(calculator.evaluate("3*x + y**2")).to eq 12 + 4
    end

    context "with definitions" do
      it "raises an error if there is an undefined variable" do
        calculator.evaluate("x = n", n: 10)
        expect{calculator.evaluate("n")}.to raise_error(Keisan::Exceptions::UndefinedVariableError)
        expect(calculator.evaluate("x")).to eq 10
      end
    end
  end

  describe "defining functions" do
    it "raises an error if there is an undefined variable" do
      expect{calculator.evaluate("f(x) = n*x")}.to raise_error(Keisan::Exceptions::InvalidExpression)
    end

    it "can define functions" do
      calculator.evaluate("f(x) = 4*x")
      expect(calculator.evaluate("f(3)")).to eq 12

      calculator.evaluate("g(x,y) = -2*x + f(y)")
      expect(calculator.evaluate("g(7, 5)")).to eq -2*7 + 4*5
    end

    context "with definitions" do
      it "local variables are evaluated, i.e. only function arguments remain variables" do
        calculator.evaluate("a = 2")
        calculator.evaluate("f(x) = a*n*x + g(x)", n: 10, g: Proc.new {|x| x**2})
        expect(calculator.evaluate("f(3)")).to eq (60 + 3**2)
        calculator.evaluate("a = 3")
        calculator.evaluate("g(x) = 0")
        expect(calculator.evaluate("f(3)")).to eq (90 + 3**2)
      end
    end

    context "recursive" do
      context "cannot define recursive functions" do
        let(:calculator) { described_class.new(allow_recursive: false) }

        it "can define factorial" do
          expect {
            calculator.evaluate("my_fact(n) = if (n > 1, n*my_fact(n-1), 1)")
          }.to raise_error(Keisan::Exceptions::InvalidExpression)
        end
      end

      context "can define recursive functions" do
        let(:calculator) { described_class.new(allow_recursive: true) }

        it "can define factorial" do
          calculator.evaluate("my_fact(n) = if (n > 1, n*my_fact(n-1), 1)")
          expect(calculator.evaluate("my_fact(0)")).to eq 1
          expect(calculator.evaluate("my_fact(1)")).to eq 1
          expect(calculator.evaluate("my_fact(5)")).to eq 120
        end
      end
    end
  end
end
