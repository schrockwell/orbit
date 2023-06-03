defmodule Orbit do
  @moduledoc """
  A simple Gemini app framework.

  ## Quick Start

  Add the dependency:

      # mix.exs
      {:orbit, "~> 0.1.0"}

  Generate a self-signed certificate:

  ```sh
  $ openssl req -new -x509 -days 365 -nodes -out priv/cert.pem -keyout priv/key.pem
  ```

  Add the `Orbit.Capsule` supervisor to your application supervision tree:

      # application.ex
      {
        Orbit.Capsule,
        endpoint: MyAppGem.Router,
        certfile: Path.join(Application.app_dir(:my_app, "priv"), "cert.pem"],
        keyfile: Path.join(Application.app_dir(:my_app, "priv"), "key.pem")
      }

  Define a router:

      # lib/my_app_gem/router.ex
      defmodule MyAppGem.Router do
        use MyAppGem, :router

        route "/", MyAppGem.PageController, :home
      end

  Define a controller:

      # lib/my_app_gem/page_controller.ex
      defmodule MyAppGem.PageController do
        use Orbit.Controller

        import Orbit.Controller
        import Orbit.Request

        view MyAppGem.PageView

        def home(req, _) do
          req
          |> assign(name: "world")
          |> render()
        end
      end

  And a view:

      # lib/my_app_gem/page_view.ex
      defmodule MyAppGem.PageView do
        use Orbit.View

        def home(assigns) do
          ~G\"\"\"
          Hello, <%= @name %>!
          \"\"\"
        end
      end

  Finally, start the application and visit `gemini://localhost/`!
  """
end
