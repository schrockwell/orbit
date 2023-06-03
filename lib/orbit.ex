defmodule Orbit do
  @moduledoc """
  A simple Gemini app framework.

  ## Quick Start

  Create a new application:

      mix new my_app --sup

  Add the dependency:

      # mix.exs
      def deps do
        [
          {:orbit, "~> 0.1.0"}
        ]
      end

  Generate some files:

      $ mix orbit.init my_app_gem

  Generate a self-signed certificate for localhost:

      $ mix orbit.gen.cert

  Finally, start the application and visit `gemini://localhost/`!
  """
end
