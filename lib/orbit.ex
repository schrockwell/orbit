defmodule Orbit do
  @moduledoc """
  A simple framework for a simple protocol.

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
    - `Orbit.Status` - applies status codes to `Orbit.Request`
    - `Orbit.ClientCertificate` - extracts client certificates from the request

  ## Quickstart

  Create a new application:

      $ mix new my_app --sup

  Add the dependency:

      # mix.exs
      def deps do
        [
          {:orbit, "~> #{Orbit.MixProject.project()[:version]}"}
        ]
      end

  Generate some files:

      $ mix deps.get
      $ mix orbit.init my_app_gem

  Generate a self-signed certificate for localhost:

      $ mix orbit.gen.cert

  Finally, start the application and visit `gemini://localhost/`!
  """
end
