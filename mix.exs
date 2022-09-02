defmodule Membrane.RawVideo.Parser.MixProject do
  use Mix.Project

  @version "0.8.0"
  @github_url "https://github.com/membraneframework/membrane_raw_video_parser_plugin"

  def project do
    [
      app: :membrane_raw_video_parser_plugin,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: "Raw video parser plugin for Membrane Multimedia Framework",
      package: package(),
      name: "Membrane raw video parser",
      source_url: @github_url,
      docs: docs(),
      homepage_url: "https://membrane.stream/",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp docs do
    [
      main: "readme",
      extras: ["README.md", LICENSE: [title: "License"]],
      formatters: ["html"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membrane.stream/"
      }
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:membrane_file_plugin, "~> 0.9", only: :test},
      {:bunch, "~> 1.3"},
      {:membrane_core, "~> 0.10.0"},
      {:membrane_raw_video_format, "~> 0.2.0"}
    ]
  end
end
