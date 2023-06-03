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
    dest_dir = "lib"

    assigns = [
      namespace: camelized
    ]

    {source_dir, dest_dir, assigns}
    |> copy_template("root.ex.eex", "#{underscored}.ex")
    |> copy_template("router.ex.eex", [underscored, "router.ex"])
    |> copy_template("page_controller.ex.eex", [underscored, "page_controller.ex"])
    |> copy_template("page_view.ex.eex", [underscored, "page_view.ex"])
    |> copy_template("layout_view.ex.eex", [underscored, "layout_view.ex"])
    |> copy_template(["page_view", "home.gmi.eex.eex"], [underscored, "page_view", "home.gmi.eex"])
    |> copy_template(["layout_view", "main.gmi.eex.eex"], [
      underscored,
      "layout_view",
      "main.gmi.eex"
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
            endpoint: #{camelized}.Router,
            certfile: Path.join(Application.app_dir(:my_app, "priv"), "cert.pem"],
            keyfile: Path.join(Application.app_dir(:my_app, "priv"), "key.pem")
          }
        ]

    3. Start the application and visit gemini://localhost/
    """)
  end

  def run(_) do
    Mix.Task.run("help", ["orbit.init"])
  end

  defp copy_template({source_dir, dest_dir, assigns} = arg, source_path, dest_path) do
    Mix.Generator.copy_template(
      Path.join([source_dir] ++ List.wrap(source_path)),
      Path.join([dest_dir] ++ List.wrap(dest_path)),
      assigns
    )

    arg
  end
end
