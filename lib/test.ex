defmodule Pyc.Test do
  use Pyc

  defpyc(foo: 42, bar: %{}, baz: [])

  defpym :put_bar, [key, value] do
    %__MODULE__{this | bar: Map.put(this.bar, key, value), baz: [42 | baz]}
  end

  defpym :put_foo, [key, value] when foo < 100 and length(baz) > 0 do
    {key, value}
  end
end
