defmodule EctoPlusOne.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_plus_one,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test", "test/support"]

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
      {:telemetry, "~> 0.4"},
      {:ecto_sql, "~> 3.9", only: :test},
      {:postgrex, "~> 0.16.5", only: :test}
    ]
  end
end
