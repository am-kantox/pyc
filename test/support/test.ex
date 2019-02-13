defmodule Pyc.Test do
  @moduledoc false
  use Pyc,
    definition: [foo: 42, bar: %{}, baz: []],
    constraints: [%{matches: %{foo: 42, bar: ~Q[bar]}, guards: %{check_bar: "is_map(bar)"}}]

  defmethod :put_foo, [value] when foo < 100 and length(baz) > 0 do
    %__MODULE__{this | foo: value, baz: [42 | baz]}
  end

  defmethod :put_bar, [key, value] do
    %__MODULE__{this | bar: Map.put(this.bar, key, value), baz: [42 | baz]}
  end

  defmethod :put_baz, [<<"foo", _::binary>> = s] do
    %__MODULE__{this | baz: s}
  end
end

defmodule Pyc.TestEmptyRules do
  @moduledoc false
  use Pyc, definition: [foo: 42, bar: %{}, baz: []]

  defmethod :put_bar, [key, value] do
    %__MODULE__{this | bar: Map.put(this.bar, key, value), baz: [42 | baz]}
  end

  defmethod :put_foo, [value] when foo < 100 and length(baz) > 0 do
    %__MODULE__{this | foo: value, baz: [42 | baz]}
  end
end

defmodule Pyc.TestInspect do
  @moduledoc false
  use Pyc, definition: [foo: 42, bar: %{key: :value}, baz: []], inspect: [:bar, :foo]
end
