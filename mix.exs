defmodule Bitgraph.MixProject do
  use Mix.Project

  def project do
    [
      app: :bitgraph,
      version: "0.1.6",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description()
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
      {:libgraph, "~> 0.16.0", only: :dev, runtime: false},
      {:arrays, "~> 2.1"},
      {:arrays_aja, "~> 0.2.0"},
      {:math, "~> 0.7.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:replbug, "~> 1.0.2", only: :dev}
    ]
  end

  defp description() do
    "Mutable directed graph"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "bitgraph",
      # These are the default files included in the package
      files: ~w(lib src test .formatter.exs mix.exs README* LICENSE*
                ),
      exclude_patterns: ["misc/**", "scripts/**", "**/*._exs", "**/*._ex"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bokner/bitgraph"}
    ]
  end
end
