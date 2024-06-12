defmodule EredisSub.MixProject do
  use Mix.Project

  @source_url "https://github.com/loopsocial/eredis_sub/"
  @version "0.1.0"

  def project do
    [
      app: :eredis_sub,
      description: "Elixir wrapper for Eredis pub/sub functionality ",
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
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
      {:eredis, "~> 1.7"},
      {:ex_doc, "~> 0.34.0", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      organization: "loopsocial",
      maintainers: ["Alexandre Costa"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
