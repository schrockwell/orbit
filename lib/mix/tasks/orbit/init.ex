defmodule Mix.Tasks.Orbit.Init do
  @moduledoc """
  Initialize an Orbit capsule.

      $ mix orbit.init NAME

  The `NAME` argument is the CamelCase or underscore_case namespace under which the files will be generated, e.g.
  "my_app_gem" or "MyAppGem".
  """

  @shortdoc "Initialize an Orbit capsule"

  use Mix.Task

  @impl Mix.Task
  def run([name]) do
    camelized = Macro.camelize(name)
    underscored = Macro.underscore(name)

    source_dir = Path.join([:code.priv_dir(:orbit), "templates", "init"])

    assigns = [
      namespace: camelized
    ]

    {source_dir, assigns}
    |> copy_template("root.ex.eex", ["lib", "#{underscored}.ex"])
    |> copy_template("router.ex.eex", ["lib", underscored, "router.ex"])
    |> copy_template("page_controller.ex.eex", ["lib", underscored, "page_controller.ex"])
    |> copy_template("page_view.ex.eex", ["lib", underscored, "page_view.ex"])
    |> copy_template("layout_view.ex.eex", ["lib", underscored, "layout_view.ex"])
    |> copy_template(["page_view", "home.gmi.eex.eex"], ["lib", underscored, "page_view", "home.gmi.eex"])
    |> copy_template(["layout_view", "main.gmi.eex.eex"], ["lib", underscored, "layout_view", "main.gmi.eex"])
    |> copy_template(["test", "support", "gem_case.ex.eex"], ["test", "support", "gem_case.ex"])
    |> copy_template(["test", "my_app_gem", "page_controller_test.exs.eex"], [
      "test",
      underscored,
      "page_controller_test.exs"
    ])

    Mix.shell().info("""
    Next steps:

    1. Generate a self-signed certificate:

        $ mix orbit.gen.cert

    2. Add the capsule to your application's supervision tree:

        # application.ex
        children = [
          # ...
          {
            Orbit.Capsule,
            entrypoint: #{camelized}.Router,
            certfile: Path.join([Application.app_dir(:my_app, "priv"), "tls", "localhost.pem"]),
            keyfile: Path.join([Application.app_dir(:my_app, "priv"), "tls", "localhost-key.pem"])
          }
        ]

    3. Add the following to `mix.exs`:

        def project do
          [
            elixirc_paths: elixirc_paths(Mix.env())
          ]
        end

        defp elixirc_paths(:test), do: ["lib", "test/support"]
        defp elixirc_paths(_), do: ["lib"]

    4. Add configuration to `.formatter.exs`:

        [
          import_deps: [:orbit]
        ]

    5. Start the application and visit `gemini://localhost/`

        mix orbit.server

    """)
  end

  def run(_) do
    Mix.Task.run("help", ["orbit.init"])
  end

  defp copy_template({source_dir, assigns} = arg, source_path, dest_path) do
    Mix.Generator.copy_template(
      Path.join([source_dir] ++ List.wrap(source_path)),
      Path.join(List.wrap(dest_path)),
      assigns
    )

    arg
  end
end
