defmodule FakeServer.Mixfile do
  use Mix.Project

  def project do
    [app: :fake_server,
     version: "1.4.0",
     elixir: "~> 1.4",
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
    [applications: [:logger, :cowboy], mod: {FakeServer.Application, []}]
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
    [{:excoveralls, "~> 0.7", only: :test},
     {:mock, "~> 0.3", only: :test},
     {:faker, "~> 0.9", only: :test},
     {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:httpoison, "~> 0.13", only: :test},
     {:inch_ex, "~> 0.5", only: [:dev, :test]},
     {:poison, ">= 1.0.0"},
     {:cowboy, "~> 1.1"}]
  end

	defp description do
    """
    With FakeServer you can create individual HTTP servers for each test case, allowing external requests to be tested without the need for mocks.
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
