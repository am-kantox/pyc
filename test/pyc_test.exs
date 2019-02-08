defmodule PycTest do
  use ExUnit.Case
  doctest Pyc

  test "defpym/3" do
    assert Pyc.Test.put_bar(%Pyc.Test{}, :pi, 3.14159265) == %Pyc.Test{
             foo: 42,
             bar: %{pi: 3.14159265},
             baz: [42]
           }

    assert_raise FunctionClauseError, fn ->
      Pyc.Test.put_foo(%Pyc.Test{}, :pi, 3.14159265)
    end
  end
end
