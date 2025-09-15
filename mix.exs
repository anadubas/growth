defmodule Growth.MixProject do
  use Mix.Project

  def project do
    [
      app: :growth,
      version: "0.1.0",
      elixir: "~> 1.18.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/project.plt"}
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Growth.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bandit, "~> 1.8.0"},
      {:credo, "~> 1.7.10"},
      {:dns_cluster, "~> 0.2.0"},
      {:dialyxir, "~> 1.4.5", only: [:test, :dev], runtime: false},
      {:esbuild, "~> 0.10.0", runtime: Mix.env() == :dev},
      {:finch, "~> 0.20.0"},
      {:floki, "~> 0.38.0", only: :test},
      {:gettext, "~> 1.0.0"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, "~> 1.4.0"},
      {:logger_json, "~> 7.0.0"},
      {:nimble_csv, "~> 1.3.0"},
      {:phoenix, "~> 1.8.1"},
      {:phoenix_html, "~> 4.2.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.6.0", only: :dev},
      {:phoenix_live_view, "~> 1.1.0", override: true},
      {:swoosh, "~> 1.19.0"},
      {:tailwind, "~> 0.4.0", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.1.0"},
      {:telemetry_poller, "~> 1.3.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind growth", "esbuild growth"],
      "assets.deploy": [
        "tailwind growth --minify",
        "esbuild growth --minify",
        "phx.digest"
      ],
      ci: [
        "compile --force --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "dialyzer --format github --format dialyxir"
      ]
    ]
  end
end
