defmodule Orbit.Capsule do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg)
  end

  @impl true
  def init(opts) do
    port = opts[:port] || 1965
    router = opts[:router] || "the :router option is required"
    certfile = opts[:certfile] || "the :certfile option is required"
    keyfile = opts[:keyfile] || "the :keyfile option is required"

    ti_opts = [
      port: port,
      handler_module: Orbit.Handler,
      handler_options: %{router: router},
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
  def verify_peer(cert, {:bad_cert, :selfsigned_peer}, state) do
    {:valid, Map.put(state, :cert, cert)}
  end

  def verify_peer(_cert, {:bad_cert, _} = event, _state) do
    {:fail, event}
  end

  def verify_peer(_cert, {:extension, _}, state) do
    {:unknown, state}
  end

  def verify_peer(_cert, :valid, state) do
    {:valid, state}
  end

  def verify_peer(_cert, :valid_peer, state) do
    {:valid, state}
  end
end
