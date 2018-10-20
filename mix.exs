defmodule FakeServer.Mixfile do
  use Mix.Project

  def project do
    [app: :fake_server,
     version: "1.5.0",
     elixir: "~> 1.4",
     description: description(),
     package: package(),
     aliases: aliases(),
     test_coverage: [tool: ExCoveralls],
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps()]
  end

  def application do
    [applications: [:logger, :cowboy], mod: {FakeServer.Application, []}]
  end

  defp deps do
    [
      {:cowboy, "~> 2.5"},
      {:poison, ">= 1.0.0"},
      {:mock, "~> 0.3", only: :test},
      {:faker, "~> 0.9", only: :test},
      {:ex_doc, "~> 0.19", only: :dev},
      {:httpoison, "~> 0.13", only: :test},
      {:excoveralls, "~> 0.7", only: :test}
    ]
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
