defmodule Becomics_load.Mixfile do
  use Mix.Project

  def project do
    [
      app: :becomics_load,
      version: "0.1.0",
      elixir: "~> 1.5",
      escript: [main_module: Becomics_load],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:httpoison, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:poison, "~> 2.2 or ~> 3.0"}
    ]
  end
end
