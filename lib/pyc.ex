defmodule Pyc do
  @moduledoc """
  Enchanced struct with validation.

  Common usage of the struct would be:

      use Pyc,
        definition: [foo: 42, bar: %{}, baz: []],
        constraints: [
          %{matches: %{foo: 42, bar: ~Q[bar]},
            guards: %{check_bar: "is_map(bar)"}}]

  `use Pyc` keyword argument accepts two keys at the moment:

  - `definition:` the struct definition that will be passed as is to underlying `defstruct`,
  - `constrainst:` the list of constrainst the struct to be validated against on updates,
  - `inspect:` since `0.2.1` we support list of fields to derive `Inspect` algebra for;
  works on Elixir greater or equal to 1.8.0. When omitted, all the fields given via
  `definition` parameter are used.

  _Please note:_ there is no way to guarantee the validation of fields in struct in general.
  Direct assignment `%MyStruct{my | foo: :bar}` and `Map.put(%MyStruct{}, :foo, :bar)`
  will still update the struct without validation.

  ---

  The above declares the struct alongside several helper functions. The resulting
  struct exports:

  - `put/3` the sibling of `Map.put/3` but with validation against
    the constraints given to `use/1`,
  - `put!/3` the same as above but returns the value on its own _or raises_,
  - `validate/1` the low-level validation of the struct constraints

  Also the helper DSL function `defmethod/3` is injected into the struct module.
  It expects the struct instance as the first argument and allows the easy handling
  of complicated structs, exposing the struct itself as `this` local variable to
  the block _and_ all the struct members as local variables with their names.

  The block must in turn return the instance of the struct, which will be validated
  against constraints. The result of the call to the function would always be either
  `struct` or `{:error, struct}`, depending on validation.

  _Sidenote:_ to validate the struct members we use [`Exvalibur`](https://hexdocs.pm/exvalibur).
  For the syntax of constraints plese refer to its documentation.
  """

  @doc false
  defmacro __using__(opts) do
    quote do
      import Exvalibur.Sigils
      import Pyc

      @constraints Keyword.get(unquote(opts), :constraints, [])
      def constraints(), do: @constraints

      @validator Keyword.get(unquote(opts), :validator, __MODULE__.Validator)
      def validator(), do: @validator

      @definition Keyword.get(unquote(opts), :definition)
      if is_nil(@definition), do: raise(ArgumentError)

      @fields if Keyword.keyword?(@definition), do: Keyword.keys(@definition), else: @definition

      @inspect Keyword.get(unquote(opts), :inspect, @fields)
      if Version.compare(System.version(), "1.7.999") == :gt,
        do: @derive({Inspect, only: @inspect})

      defstruct(@definition)
      @after_compile {Pyc.Helpers.Hooks, :after_pyc}

      @doc ~s"""
      Validates the `%#{__MODULE__}{}` instance against the set of constraints
      specified in the keyword argument passed to `use Pyc`.
      """
      @spec validate(result :: %__MODULE__{}) :: %__MODULE__{} | {:error, any()}
      case @constraints do
        [] ->
          def validate(%__MODULE__{} = result), do: result
          def validate(result), do: {:error, result}

        _ ->
          def validate(%__MODULE__{} = result) do
            case @validator.valid?(result) do
              {:ok, _} -> result
              :error -> {:error, result}
            end
          end

          def validate(result), do: {:error, result}
      end

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
            {v, _, nil}, acc ->
              [v | acc]

            {v, _, [_ | _] = vars}, acc ->
              for({v, _, nil} <- vars, do: v) ++ acc

            _, acc ->
              acc
          end)

        {:=, [],
         [
           Enum.map(all, fn _ -> {:_, [], nil} end),
           Enum.map(all, &Macro.var(&1, nil))
         ]}
      end

      @spec put(
              this :: %__MODULE__{} | {:error, any()},
              name :: atom(),
              value :: any()
            ) ::
              %__MODULE__{} | {:error, any()}

      @doc ~s"""
      Updates #{__MODULE__} struct by assigning the `value` given
      to the key `name`, _applying_ validation.

      Returns %#{__MODULE__}{} or {:error, %#{__MODULE__}{}}, depending
      whether the validation succeeded.
      """
      def put(%__MODULE__{} = this, name, value) when name in @fields do
        this
        |> Map.put(name, value)
        |> validate()
      end

      if length(@constraints) > 0 do
        @doc ~s"""
        Monadic tail-on-fail [`#{__MODULE__}.put/3`]; accepts the first argument
        in the form `{:error, %#{__MODULE__}{}}` **and skips the assignement.
        Used in monadic chaining.
        """
        def put({:error, %__MODULE__{} = this}, name, _value) when name in @fields,
          do: {:error, this}
      end

      @doc ~s"""
      The same as [`#{__MODULE__}.put/3`], but returns the raw result _or_ raises
      if there was a validation error.
      """
      def put!(this_or_tuple, name, value) when name in @fields do
        case put(this_or_tuple, name, value) do
          {:error, result} -> raise Pyc.Invalid, source: result, reason: "Validation failed"
          result -> result
        end
      end

      @spec get(term :: %__MODULE__{}, key :: atom(), default :: any()) ::
              %__MODULE__{} | {:error, %__MODULE__{}}
      def get(%__MODULE__{} = term, key, default \\ nil) when key in @fields do
        with {:ok, value} <- fetch(term, key), nil <- value, do: default
      end

      @spec delete(term :: %__MODULE__{}, key :: atom()) ::
              %__MODULE__{} | {:error, %__MODULE__{}}
      def delete(%__MODULE__{} = term, key), do: put(term, key, nil)

      @behaviour Access

      @impl Access
      def fetch(%__MODULE__{} = term, key) when key in @fields, do: Map.fetch(term, key)

      @impl Access
      def pop(%__MODULE__{} = term, key, default \\ nil),
        do: {get(term, key, default), delete(term, key)}

      @impl Access
      def get_and_update(%__MODULE__{} = term, key, fun) when is_function(fun, 1) do
        current = get(term, key)

        case fun.(current) do
          {get, update} -> {get, put(term, key, update)}
          :pop -> {current, delete(term, key)}
          other -> raise Pyc.Invalid, source: term, reason: other
        end
      end
    end
  end

  @doc ~S"""
  Declares a function somewhat similar to 🐍 class method.

  In the block `this` variable local is available as well as all the fields are
  being mapped to local variables.

  The produced function expects the struct as the first argument, all the arguments
  specified in the call to this macro will be passed unsplatted starting with the
  second one.

  Under the hood the following definition

      use Pyc,
        definition: [:amount],
        constraints: [
          %{matches: %{amount: ~Q[amount]},
            guards: %{amount_is_float: "is_float(amount)"}}]

      defmethod :round_amount, [decimals],
        do: %MyStruct{this | amount: Float.round(amount, decimals)}

  will be expanded to the method accepting two parameters (`%MyStruct{}` and `decimals`.)

  In the block there are variables `this` and `amount` magically available. Also,
  after the block has the value returned, `validation` implied by constraints will
  be applied (in this example we’d check for `amount` value to be `float`.)
  """
  defmacro defmethod(name, {:when, _, [params, guards]}, do: block) do
    quote do
      def unquote(name)(__this__() = var!(this), unquote_splicing(params)) when unquote(guards) do
        __suppress_warnings__()
        validate(unquote(block))
      end

      def unquote(name)({:error, __this__() = var!(this)} = error, unquote_splicing(params))
          when unquote(guards) do
        __suppress_warnings__(unquote(params))
        error
      end

      def unquote(:"#{name}!")(__this__() = var!(this), unquote_splicing(params))
          when unquote(guards) do
        __suppress_warnings__()

        case validate(unquote(block)) do
          {:error, result} -> raise Pyc.Invalid, source: result, reason: "Validation failed"
          result -> result
        end
      end
    end
  end

  defmacro defmethod(name, params, do: block) do
    quote do
      def unquote(name)(__this__() = var!(this), unquote_splicing(params)) do
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
          {:error, result} -> raise Pyc.Invalid, source: result, reason: "Validation failed"
          result -> result
        end
      end
    end
  end
end
