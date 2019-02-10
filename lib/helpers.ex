defmodule Pyc.Helpers do
  defmodule Hooks do
    def after_pyc(env, _bytecode) do
      case env.module.constraints() do
        [] ->
          :ok

        constraints ->
          Exvalibur.validator!(constraints, module_name: env.module.validator())
      end
    end
  end
end
