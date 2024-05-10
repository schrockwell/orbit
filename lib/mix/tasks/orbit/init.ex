defmodule Mix.Tasks.Orbit.Init do
  @moduledoc """
  Initialize an Orbit capsule.

      $ mix orbit.init OTP_APP MODULE

  The `OTP_APP` argument is the name of the existing OTP application under which the capsule will be hosted, e.g. `my_app`.

  The `MODULE` argument is the namespace under which the capsule files will be generated, e.g. `MyAppCapsule`.

  ## Example

      $ mix orbit.init my_app MyAppCapsule
  """

  @shortdoc "Initialize an Orbit capsule in an existing application."

  use Mix.Task

  @impl Mix.Task
  def run([otp_app, module]) do
    namespace = Macro.camelize(module)
    underscored = Macro.underscore(module)

    source_dir = Path.join([:code.priv_dir(:orbit), "templates", "init"])

    assigns = [
      namespace: namespace,
      otp_app: ":#{otp_app}"
    ]

    {source_dir, assigns}
    |> copy_template("root.ex.eex", ["lib", "#{underscored}.ex"])
    |> copy_template("endpoint.ex.eex", ["lib", underscored, "endpoint.ex"])
    |> copy_template("page_controller.ex.eex", ["lib", underscored, "page_controller.ex"])
    |> copy_template("page_gmi.ex.eex", ["lib", underscored, "page_gmi.ex"])
    |> copy_template("layout_gmi.ex.eex", ["lib", underscored, "layout_gmi.ex"])
    |> copy_template(["page_gmi", "home.gmi.eex.eex"], ["lib", underscored, "page_gmi", "home.gmi.eex"])
    |> copy_template(["layout_gmi", "main.gmi.eex.eex"], ["lib", underscored, "layout_gmi", "main.gmi.eex"])
    |> copy_template(["test", "support", "capsule_case.ex.eex"], ["test", "support", "capsule_case.ex"])
    |> copy_template(["test", "my_app_capsule", "page_controller_test.exs.eex"], [
      "test",
      underscored,
      "page_controller_test.exs"
    ])

    Mix.Task.run("orbit.gen.cert")

    Mix.shell().info("""
    Next steps:

    1. Add the capsule to your application's supervision tree:

        # lib/application.ex
        children = [
          #{namespace}.Endpoint
        ]

    2. Add configuration:

        # config/config.exs
        config :mime, :types, %{
          "text/gemini" => ["gmi"]
        }

        # config/runtime.exs
        config #{inspect(otp_app)}, #{namespace}.Endpoint,
          certfile: Path.join([Application.app_dir(#{inspect(otp_app)}, "priv"), "tls", "localhost.crt"]),
          keyfile: Path.join([Application.app_dir(#{inspect(otp_app)}, "priv"), "tls", "localhost.key"])

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
