defmodule Pyc do
  @moduledoc """
  Enchanced struct with validation.

  Common usage of the struct would be:

      use Pyc,
        struct:
  """

  defmacro __using__(opts) do
    quote do
      import Exvalibur.Sigils
      import Pyc

      @constraints Keyword.get(unquote(opts), :constraints, [])
      def constraints(), do: @constraints

      @validator Keyword.get(unquote(opts), :validator, __MODULE__.Validator)
      def validator(), do: @validator

      @definition Keyword.get(unquote(opts), :definition)
      if is_nil(@definition), do: raise ArgumentError
      defstruct(@definition)

      case @constraints do
        [] -> defp validate(result), do: {:ok, result}
        _ ->
          defp validate(result) do
            case @validator.valid?(result) do
              {:ok, _} -> {:ok, result}
              :error -> {:error, result}
            end
          end
      end

      @fields if Keyword.keyword?(@definition), do: Keyword.keys(@definition), else: @definition
      @after_compile ({Pyc.Helpers.Hooks, :after_pyc})

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
        all =
          Enum.reduce(additional, [:this | @fields], fn
            {v, _, nil}, acc -> [v | acc]
            {v, _, [_|_] = vars}, acc ->
              (for {v, _, nil} <- vars, do: v) ++ acc
            _, acc -> acc
          end)
        {:=, [],
         [
           Enum.map(all, fn _ -> {:_, [], nil} end),
           Enum.map(all, &Macro.var(&1, nil))
         ]}
      end

      def put(%__MODULE__{} = this, name, value) when name in @fields do
        this
        |> Map.put(name, value)
        |> validate()
      end
      def put({:ok, %__MODULE__{} = this}, name, value) when name in @fields,
        do: put(this, name, value)
      if length(@constraints) > 0 do
        def put({:error, %__MODULE__{} = this}, name, _value) when name in @fields, do: this
      end
      def put!(%__MODULE__{} = this, name, value) when name in @fields do
        case put(this, name, value) do
          {:ok, result} -> result
          {:error, _result} -> raise ArgumentError # , result: result
        end
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
      # if length(Module.get_attribute(__CALLER__.module, :constraints)) > 0 do

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
