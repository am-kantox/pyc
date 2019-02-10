defmodule Pyc.MixProject do
  use Mix.Project

  def project do
    [
      app: :pyc,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:exvalibur, "~> 0.6"},
      {:exvalibur, path: "../exvalibur"},

      {:credo, "~> 1.0", only: :dev, runtime: :false}
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
