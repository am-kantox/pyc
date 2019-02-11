defmodule Pyc.Test.ProtocolsBehaviours.Test do
  use ExUnit.Case

  test "into/3" do
    assert Enum.into([foo: 3.14, bar: :baz, baz: %{}], %Pyc.TestEmptyRules{}) ==
             %Pyc.TestEmptyRules{foo: 3.14, bar: :baz, baz: %{}}

    assert Enum.into([foo: 3.14, bar: :baz, baz: %{}], %Pyc.Test{}) ==
             {:error, %Pyc.Test{bar: %{}, baz: [], foo: 3.14}}
  end

  test "Access behaviour" do
    input = %Pyc.Test{}

    assert get_in(input, [:foo]) == 42
    assert put_in(input, [:bar, :baz], 42) == %Pyc.Test{bar: %{baz: 42}, baz: [], foo: 42}
    assert put_in(input, [:foo], :bar) == {:error, %Pyc.Test{bar: %{}, baz: [], foo: :bar}}
  end
end
