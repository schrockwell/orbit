defmodule Orbit do
  @moduledoc """
  A simple framework for a simple protocol.

  Orbit is a framework for building [Gemini](https://geminiprotocol.net/) applications, known as "capsules".

  This framework focuses primarily on the Gemini protocol itself, intent on getting a request into your application,
  handling it, and sending a Gemtext response.

  It doesn't make any assumptions about your business logic, backing database, migrations, or anything like that.
  If you need a database, you can add it manually ([see below](#module-adding-a-database)).

  ## Concepts

  Orbit borrows a lot of ideas from Plug and Phoenix.

    - `Orbit.Capsule` - the TLS server that accepts incoming requests (`Phoenix.Endpoint` + `cowboy`)
    - `Orbit.Request` - encapsulates the request-response lifecyle (`Plug.Conn`)
    - `Orbit.Pipe` - the behaviour for request middleware (`Plug`)
    - `Orbit.Router` - defines pipelines and routes (`Phoenix.Router`)
    - `Orbit.Controller` - processes requests (`Phoenix.Controller`)
    - `Orbit.Gemtext` - renders Gemtext templates (`Phoenix.Component`)

  Some additional niceties:

    - `Orbit.Static` - serves up files from `priv/statc` (`Plug.Static`)
    - `Orbit.Status` - a canonical list of all status codes
    - `Orbit.ClientCertificate` - extracts client certificates from the request

  ## Quickstart

  Orbit does not have a fancy project generator like `mix phx.new`. Instead, you add the dependency to a new
  (or existing!) application, and then run `mix orbit.init` to get started.

  Create a new application:

      $ mix new my_app --sup

  Add the dependency:

      # mix.exs
      def deps do
        [
          {:orbit, "~> #{Orbit.MixProject.project()[:version]}"}
        ]
      end

  Generate some files (don't worry, existing files won't be modified):

      $ mix deps.get
      $ mix orbit.init my_app MyAppGemini

  Follow the instructions from the task's output.

  Finally, start the application and visit `gemini://localhost/`

  ## Adding a Database

  This example for setting up Postgres was cribbed from the [Ecto](https://hexdocs.pm/ecto/Ecto.html) docs. You might
  prefer [SQLite](https://hexdocs.pm/ecto_sqlite3/Ecto.Adapters.SQLite3.html) as an alternative.

  Add the dependencies:

      # mix.exs
      def deps do
        [
          # Check hex.pm for the latest versions!
          {:ecto, "~> 3.11.2"},
          {:ecto_sql, "~> 3.11.1"},
          {:postgrex, "~> 0.17.5"}
        ]
      end

  Add some config:

      # config/config.exs
      config :my_app, ecto_repos: [MyApp.Repo]

      # config/runtime.exs
      config :my_app, MyApp.Repo, url: System.fetch_env!("DATABASE_URL")

  Create the repo module:

      # lib/my_app/repo.ex
      defmodule MyApp.Repo do
        use Ecto.Repo,
          otp_app: :my_app,
          adapter: Ecto.Adapters.Postgres
      end

  Add the repo to the supervision tree:

      # lib/application.ex
      children = [
        MyApp.Repo
      ]

  Finally, create the DB.

      $ mix ecto.create

  Migrations can be generated with `mix ecto.gen.migration`, and schemas are written by hand.
  """
end
