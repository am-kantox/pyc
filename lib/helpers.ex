defmodule Pyc.Helpers do
  defmodule Hooks do
    def after_pyc(env, _bytecode) do
      case env.module.constraints() do
        [] ->
          :ok

        constraints ->
          Exvalibur.validator!(constraints, module_name: env.module.validator())
      end

      defimpl Collectable, for: env.module do
        @doc false
        @target env.module
        def into(original) do
          {original,
           fn
             map, {:cont, {k, v}} -> @target.put(map, k, v)
             map, :done -> map
             _, :halt -> :ok
           end}
        end
      end
    end
  end
end
