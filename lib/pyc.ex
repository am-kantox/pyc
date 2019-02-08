defmodule Pyc do
  @moduledoc """
  Documentation for Pyc.
  """

  defmacro __using__(_opts) do
    quote do
      require Pyc
      import Pyc
    end
  end

  defmacro defpyc(fields) do
    quote do
      @init unquote(fields)
      @fields if Keyword.keyword?(@init), do: Keyword.keys(@init), else: @init
      defstruct(@init)

      defmacrop __this__() do
        {:%, [],
         [
           {:__aliases__, [alias: false],
            __MODULE__ |> Module.split() |> Enum.map(&String.to_atom/1)},
           {:%{}, [],
            for(
              v <- @fields,
              do: {v, Macro.var(v, nil)}
            )}
         ]}
      end

      defmacrop __suppress_warnings__() do
        {:=, [],
         [
           Enum.map([:this | @fields], fn _ -> {:_, [], nil} end),
           Enum.map([:this | @fields], &Macro.var(&1, nil))
         ]}
      end
    end
  end

  defmacro defpym(name, {:when, _, [params, guards]}, do: block) do
    quote do
      def unquote(name)(__this__() = var!(this), unquote_splicing(params)) when unquote(guards) do
        __suppress_warnings__()
        unquote(block)
      end
    end
  end

  defmacro defpym(name, params, do: block) do
    quote do
      def unquote(name)(__this__() = var!(this), unquote_splicing(params)) do
        __suppress_warnings__()
        unquote(block)
      end
    end
  end
end
