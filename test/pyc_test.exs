defmodule PycTest do
  use ExUnit.Case
  doctest Pyc

  test "defpym/3" do
    assert Pyc.Test.put_bar!(%Pyc.Test{}, :pi, 3.14159265) == %Pyc.Test{
      foo: 42,
      bar: %{pi: 3.14159265},
      baz: [42]
    }

    assert Pyc.Test.put_bar(%Pyc.Test{}, :pi, 3.14159265) == {:ok, %Pyc.Test{
      foo: 42,
      bar: %{pi: 3.14159265},
      baz: [42]
    }}

    assert_raise FunctionClauseError, fn ->
      Pyc.Test.put_foo(%Pyc.Test{}, 3.14159265)
    end
  end

  test "successful chaining" do
    result =
      %Pyc.Test{}
      |> Pyc.Test.put_bar(:pi, 3.14)
      |> Pyc.Test.put_bar(:pi, 3.1415)
      |> Pyc.Test.put_bar(:pi, 3.14159265)

    assert result == {:ok, %Pyc.Test{
      foo: 42,
      bar: %{pi: 3.14159265},
      baz: '***'
    }}
  end

  test "errored chaining" do
    result =
      %Pyc.Test{}
      |> Pyc.Test.put_bar(:pi, 3.14)
      |> Pyc.Test.put_foo(50)
      |> Pyc.Test.put_bar(:pi, 3.14159265)

    assert result == {:error, %Pyc.Test{
      foo: 50,
      bar: %{pi: 3.14},
      baz: '**'
    }}
  end
end
