defmodule Orbit.Capsule do
  @moduledoc """
  The main endpoint supervisor.

  ## Options

  ### Required
  - `:certfile` - path to a TLS certificatefile in the PEM format
  - `:endpoint` - the `Orbit.Pipe` entry point that gets called on every request, typically an `Orbit.Router`
  - `:keyfile` - path to a TLS private key file in the PEM format

  ### Optional

  - `:port` - the port to listen on; defaults to 1965

  ## Example Child Specification

      {
        Orbit.Capsule,
        endpoint: MyApp.GemRouter,
        certfile: Path.join(Application.app_dir(:my_app, "priv"), "cert.pem"],
        keyfile: Path.join(Application.app_dir(:my_app, "priv"), "key.pem")
      }

  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg)
  end

  @impl true
  def init(opts) do
    port = opts[:port] || 1965
    endpoint = opts[:endpoint] || "the :endpoint option is required"
    certfile = opts[:certfile] || "the :certfile option is required"
    keyfile = opts[:keyfile] || "the :keyfile option is required"

    ti_opts = [
      port: port,
      handler_module: Orbit.Handler,
      handler_options: %{endpoint: endpoint},
      transport_module: ThousandIsland.Transports.SSL,
      transport_options: [
        certfile: certfile,
        ip: :any,
        keyfile: keyfile,
        verify_fun: {&verify_peer/3, %{}},
        verify: :verify_peer
      ]
    ]

    children = [
      {ThousandIsland, ti_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # https://stackoverflow.com/a/32198900
  defp verify_peer(cert, {:bad_cert, :selfsigned_peer}, state) do
    {:valid, Map.put(state, :cert, cert)}
  end

  defp verify_peer(_cert, {:bad_cert, _} = event, _state) do
    {:fail, event}
  end

  defp verify_peer(_cert, {:extension, _}, state) do
    {:unknown, state}
  end

  defp verify_peer(_cert, :valid, state) do
    {:valid, state}
  end

  defp verify_peer(_cert, :valid_peer, state) do
    {:valid, state}
  end
end
