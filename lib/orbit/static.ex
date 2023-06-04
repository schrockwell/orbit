defmodule Orbit.Static do
  @moduledoc """
  Serve static content from the file system.

  The `:path` or `*path` URL parameter must be specified when defining the route, e.g.

      route "/static/*path", Orbit.Static, from: "priv/static"

  ## Options

  - `:from` (required) - the directory to serve
  """
  @behaviour Orbit.Pipe

  import Orbit.Controller
  import Orbit.Request
  import Orbit.Status

  alias Orbit.Request

  def call(%Request{} = req, opts) do
    static_path = opts[:from] || "the :from option is required"
    request_path = req.params["path"] || raise "the :path param must be specified in the route"

    file_path = Path.join(static_path, request_path)

    cond do
      File.exists?(file_path) and not File.dir?(file_path) ->
        send_file(req, file_path)

      # TODO: redirect "dir" to "dir/" if "dir/index.gmi" exists
      File.dir?(file_path) and File.exists?(Path.join(file_path, "index.gmi")) ->
        send_file(req, Path.join(file_path, "index.gmi"))

      :else ->
        not_found(req)
    end
  end
end
