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
      handler_options: [router: router],
      transport_module: ThousandIsland.Transports.SSL,
      transport_options: [
        certfile: certfile,
        keyfile: keyfile,
        ip: :any
      ]
    ]

    children = [
      {ThousandIsland, ti_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
