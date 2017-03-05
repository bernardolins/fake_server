defmodule FakeServer.Mixfile do
  use Mix.Project

  def project do
    [app: :fake_server,
     version: "0.5.0",
     elixir: "~> 1.3",
     description: description(),
     package: package(),
     aliases: aliases(),
     test_coverage: [tool: ExCoveralls],
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :cowboy, :httpoison], mod: {FakeServer.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:excoveralls, "~> 0.5", only: :test},
     {:mock, "~> 0.2.0", only: :test},
     {:credo, "~> 0.5.0", only: [:dev, :test]},
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:httpoison, "~> 0.10.0", only: :test},
     {:inch_ex, only: :docs},
     {:cowboy, "~> 1.1.0"}]
  end

	defp description do
    """
    Mock HTTP requests.
    """
  end

  defp package do
    [name: :fake_server,
     maintainers: ["Bernardo Lins"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/bernardolins/fake_server"}]
  end

  defp aliases do
    [test: "test --no-start"]
  end

  defp elixirc_paths(:test), do: ["lib", "test/integration/support"]
  defp elixirc_paths(_), do: ["lib"]
end
