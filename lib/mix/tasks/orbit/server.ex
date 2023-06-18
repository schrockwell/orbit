defmodule Mix.Tasks.Orbit.Server do
  @moduledoc """
  Run the Orbit server.

      $ mix orbit.server
  """

  @shortdoc "Run the Orbit server"

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    Mix.Task.run("run", ["--no-halt"])
  end
end
