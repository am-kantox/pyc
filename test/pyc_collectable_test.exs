defmodule Pyc.Test.Collectable.Test do
  use ExUnit.Case

  test "into/3" do
    assert Enum.into([foo: 3.14, bar: :baz, baz: %{}], %Pyc.TestEmptyRules{}) ==
             %Pyc.TestEmptyRules{foo: 3.14, bar: :baz, baz: %{}}

    assert Enum.into([foo: 3.14, bar: :baz, baz: %{}], %Pyc.Test{}) ==
             {:error, %Pyc.Test{bar: %{}, baz: [], foo: 3.14}}
  end
end
