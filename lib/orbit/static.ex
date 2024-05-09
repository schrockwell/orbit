defmodule Orbit.Static do
  @moduledoc """
  Serve static content from "priv/".

  The `:path` or `*path` URL parameter must be specified when defining the route, e.g.

      route "/static/*path", Orbit.Static, from: :my_app

  ## Options

  - `:from` (required) - the name of the OTP application where the static files are located
  - `:dir` - the name of the directory within priv/ where the static files are located; defaults to "static"
  """
  @behaviour Orbit.Pipe

  import Orbit.Controller
  import Orbit.Request

  alias Orbit.Request

  def call(%Request{} = req, opts) do
    otp_app = opts[:from] || "the :from option is required"
    dir = opts[:dir] || "static"
    request_path = req.params["path"] || raise "the :path param must be specified in the route"

    static_path = otp_app |> :code.priv_dir() |> Path.join(dir)

    static_segs = Path.split(static_path)
    request_segs = String.split(request_path, "/")

    file_path = Path.join(static_segs ++ request_segs)

    cond do
      # File exists -> return it
      File.exists?(file_path) and not File.dir?(file_path) ->
        send_file(req, file_path)

      # "/dir" or "/dir/" requested, and "/dir/index.gmi" exists -> return "/dir/index.gmi"
      File.dir?(file_path) and File.exists?(Path.join(file_path, "index.gmi")) ->
        send_file(req, Path.join(file_path, "index.gmi"))

      # Not found
      :else ->
        put_status(req, :not_found)
    end
  end
end
