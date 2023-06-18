defmodule Orbit do
  @moduledoc """
  A simple Gemini app framework.

  ## Quick Start

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
