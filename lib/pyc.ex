defmodule Pyc do
  @moduledoc """
  Documentation for Pyc.
  """

  defmacro __using__(opts) do
    quote do
      import Pyc

      @constraints Keyword.get(unquote(opts), :constraints, [])
      def constraints(), do: @constraints

      defp validate(result) do
        case __MODULE__.Validator.valid?(result) do
          {:ok, _} -> {:ok, result}
          :error -> {:error, result}
        end
      end
    end
  end

  defmacro defpyc(fields) do
    quote do
      @init unquote(fields)
      @fields if Keyword.keyword?(@init), do: Keyword.keys(@init), else: @init
      @after_compile ({Pyc.Helpers.Hooks, :after_pyc})
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

      defmacrop __suppress_warnings__(additional \\ []) do
        all = [:this | @fields] ++ Enum.map(additional, fn {v, _, _} -> v end)
        {:=, [],
         [
           Enum.map(all, fn _ -> {:_, [], nil} end),
           Enum.map(all, &Macro.var(&1, nil))
         ]}
      end
    end
  end

  defmacro defpym(name, {:when, _, [params, guards]}, do: block) do
    quote do
      def unquote(name)(__this__() = var!(this), unquote_splicing(params)) when unquote(guards) do
        __suppress_warnings__()
        validate(unquote(block))
      end
      def unquote(name)({:ok, __this__() = var!(this)}, unquote_splicing(params)) when unquote(guards) do
        __suppress_warnings__()
        validate(unquote(block))
      end
      def unquote(name)({:error, __this__() = var!(this)} = error, unquote_splicing(params)) when unquote(guards) do
        __suppress_warnings__(unquote(params))
        error
      end
      def unquote(:"#{name}!")(__this__() = var!(this), unquote_splicing(params)) when unquote(guards) do
        __suppress_warnings__()
        case validate(unquote(block)) do
          {:ok, result} -> result
          {:error, _result} -> raise ArgumentError # , result: result
        end
      end
    end
  end

  defmacro defpym(name, params, do: block) do
    quote do
      def unquote(name)(__this__() = var!(this), unquote_splicing(params)) do
        __suppress_warnings__()
        validate(unquote(block))
      end
      def unquote(name)({:ok, __this__() = var!(this)}, unquote_splicing(params)) do
        __suppress_warnings__()
        validate(unquote(block))
      end
      def unquote(name)({:error, __this__() = var!(this)} = error, unquote_splicing(params)) do
        __suppress_warnings__(unquote(params))
        error
      end
      def unquote(:"#{name}!")(__this__() = var!(this), unquote_splicing(params)) do
        __suppress_warnings__()
        case validate(unquote(block)) do
          {:ok, result} -> result
          {:error, _result} -> raise ArgumentError # , result: result
        end
      end
    end
  end
end
