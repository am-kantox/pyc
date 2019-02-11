# Pyc

[![CircleCI](https://circleci.com/gh/am-kantox/pyc.svg?style=svg)](https://circleci.com/gh/am-kantox/pyc)  **Struct on steroids: insertion validation, handy pipelining and more.**

## Usage

Declare the struct with `use Pyc, definition: ...` and get helper macros
to deal with the struct alongside the validation of updates for free.

Validation of updates works for all injected `MyStruct.put/3` functions that
basically substitute the generic `Map.put/3` as well as for `Collectable.into/1`
automatically implemented for the struct defined that way.

All functions declared with `defmethod/3` get `this` local variable as well as
the bunch of local variables for all the keys of the struct.

Easy monadic chaining is possible with generic pipe operator.

```elixir
defmodule MyStruct do
  use Pyc,
    definition: [foo: 42, bar: %{}, baz: []],
    constraints: [%{matches: %{foo: 42, bar: ~Q[bar]}, guards: %{check_bar: "is_map(bar)"}}]

  defmethod :foo!, [value] when foo < 100 and length(baz) > 0 do
    %__MODULE__{this | foo: value, baz: [42 | baz]}
  end
end


iex> %MyStruct{}
...> |> MyStruct.put(:baz, 42)
...> |> IO.inspect(label: "1st put")
...> |> MyStruct.put(:baz, [])
...> |> IO.inspect(label: "2nd put")
...> |> MyStruct.put(:bar, 42)
...> |> IO.inspect(label: "3rd put")
#⇒ 1st put: %MyStruct{bar: %{}, baz: 42, foo: 42}
#  2nd put: %MyStruct{bar: %{}, baz: [], foo: 42}
#  3rd put: {:error, %MyStruct{bar: 42, baz: [], foo: 42}}

iex> Enum.into([bar: %{zzz: nil}, baz: "¡Hola!"], %MyStruct)
#⇒ %MyStruct{bar: %{zzz: nil}, baz: "¡Hola!", foo: 42}

iex> Enum.into([bar: 42], %MyStruct)
#⇒ {:error, %MyStruct{bar: 42, baz: [], foo: 42}}
```

## Installation

```elixir
def deps do
  [
    {:pyc, "~> 0.1.0"}
  ]
end
```

## Docs

→ [https://hexdocs.pm/pyc](https://hexdocs.pm/pyc)
