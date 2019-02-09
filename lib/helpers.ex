defmodule Pyc.Helpers do
  defmodule Hooks do
    @spec after_pyc(atom() | %{module: atom() | %{rules: [any()]}}, any()) ::
            {:module, atom(), binary(), any()}
    def after_pyc(env, _bytecode) do
      Exvalibur.validator!(env.module.constraints(), module_name: Module.concat(env.module, "Validator"))
    end
  end
end
