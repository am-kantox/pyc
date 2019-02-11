defmodule Pyc.MixProject do
  use Mix.Project

  @app :pyc
  @github "am-kantox/#{@app}"
  @version "0.2.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      xref: [exclude: []]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exvalibur, "~> 0.6"},
      {:credo, "~> 1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:stream_data, "~> 0.4", only: :test},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end

  defp description do
    """
    Struct on steroids: insertion validation, handy pipelining and more.
    """
  end

  defp package do
    [
      name: @app,
      files: ["lib", "config", "mix.exs", "README*"],
      maintainers: ["Aleksei Matiushkin"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/#{@github}",
        "Docs" => "http://hexdocs.pm/@{app}"
      }
    ]
  end

  defp docs() do
    [
      # main: "intro",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/#{@app}",
      # logo: "stuff/images/logo.png",
      source_url: "https://github.com/#{@github}",
      # extras: ["stuff/pages/intro.md"],
      groups_for_modules: [
        # Pyc

        # Extras: [
        #   Iteraptor.Iteraptable,
        #   Iteraptor.Extras
        # ],
      ]
    ]
  end
end
