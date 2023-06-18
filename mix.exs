defmodule Orbit.MixProject do
  use Mix.Project

  def project do
    [
      app: :orbit,
      version: "0.2.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex package
      description: "A simple Gemini app framework",
      package: [
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/schrockwell/orbit"
        }
      ],

      # Docs
      name: "Orbit",
      source_url: "https://github.com/schrockwell/orbit",
      docs: [
        main: "Orbit",
        extras: ["README.md"],
        logo: "logo.png",
        groups_for_modules: [
          Framework: [
            Orbit,
            Orbit.Capsule,
            Orbit.ClientCertificate,
            Orbit.Gemtext,
            Orbit.Pipe,
            Orbit.Request,
            Orbit.Status
          ],
          Application: [
            Orbit.Controller,
            Orbit.Router,
            Orbit.View
          ],
          Pipes: [
            Orbit.Static
          ],
          Testing: [
            OrbitTest
          ]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:thousand_island, "~> 0.6.7"},
      {:mime, "~> 2.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:x509, "~> 0.8.7"}
    ]
  end
end
