defmodule Pyc.Test do
  use Pyc, constraints: [%{matches: %{foo: 42, bar: ~Q[bar]}, guards: %{check_bar: "is_map(bar)"}}],
 definition: [foo: 42, bar: %{}, baz: []]

  defpym :put_foo, [value] when foo < 100 and length(baz) > 0 do
    %__MODULE__{this | foo: value, baz: [42 | baz]}
  end

  defpym :put_bar, [key, value] do
    %__MODULE__{this | bar: Map.put(this.bar, key, value), baz: [42 | baz]}
  end

  defpym :put_baz, [<<"foo", _::binary>> = s] do
    %__MODULE__{this | baz: s}
  end
end

defmodule Pyc.TestEmptyRules do
  use Pyc, definition: [foo: 42, bar: %{}, baz: []]

  defpym :put_bar, [key, value] do
    %__MODULE__{this | bar: Map.put(this.bar, key, value), baz: [42 | baz]}
  end

  defpym :put_foo, [value] when foo < 100 and length(baz) > 0 do
    %__MODULE__{this | foo: value, baz: [42 | baz]}
  end
end
