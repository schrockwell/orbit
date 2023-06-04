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

  alias Orbit.Request

  def call(%Request{} = req, opts) do
    static_path = opts[:from] || "the :from option is required"
    request_path = req.params["path"] || raise "the :path param must be specified in the route"

    static_segs = Path.split(static_path)
    request_segs = String.split(request_path, "/")

    req_dir? = String.ends_with?(req.uri.path, "/")
    file_path = Path.join(static_segs ++ request_segs)

    cond do
      # File exists -> return it
      File.exists?(file_path) and not File.dir?(file_path) ->
        send_file(req, file_path)

      # "/dir/" requested and "/dir/index.gmi" exists -> return "/dir/index.gmi"
      File.dir?(file_path) and req_dir? and File.exists?(Path.join(file_path, "index.gmi")) ->
        send_file(req, Path.join(file_path, "index.gmi"))

      # "/dir" requested and "/dir/index.gmi" exists -> redirect to "/dir/"
      File.dir?(file_path) and not req_dir? and File.exists?(Path.join(file_path, "index.gmi")) ->
        put_status(req, :redirect_permanent, req.uri.path <> "/")

      # Not found
      :else ->
        put_status(req, :not_found)
    end
  end
end
