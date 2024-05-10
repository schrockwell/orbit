defmodule Orbit.Endpoint do
  @moduledoc """
  The main endpoint supervisor.

  ## Usage

  Define the module:

      # lib/my_app_capsule/endpoint.ex
      defmodule MyAppCapsule.Endpoint do
        use Orbit.Endpoint, otp_app: :my_app
        use Orbit.Router

        # ...define pipes and routes (see Orbit.Router docs)...
      end

  Then add config:

      # config/config.exs
      config :my_app, MyAppCapsule.Endpoint,
        certfile: "path/to/hostname.crt",
        keyfile: "path/to/hostname.key"

  Finally, add it to the supervision tree:

      # lib/my_app/application.ex
      children = [
        MyAppCapsule.Endpoint
      ]

  ## Options for `use Orbit.Endpoint`

  ### Required

  - `:otp_app` - the OTP application name

  ### Optional

  - `:entrypoint` - the initial pipe to handle incoming requests; defaults to the calling module

  ## Configuration

  ### Required

  - One of:
    - `:certfile` - path to a TLS certificatefile in the PEM format
    - `:cert` - a DER-encoded certificate binary
    - `:cert_pem` - a PEM-encoded certificate binary

  - One of:
    - `:keyfile` - path to a TLS private key file in the PEM format
    - `:key` - a DER-encoded private key binary
    - `:key_pem` - a PEM-encoded private key binary

  ### Optional

  - `:ip` - the IP to listen on; defaults to `"0.0.0.0"`
  - `:port` - the port to listen on; defaults to `1965`
  - `:debug_errors` - if true, returns stack traces for server errors; defaults to `false`

  """
  use Supervisor

  require Logger

  @default_port 1965

  defmacro __using__(opts) do
    otp_app = opts[:otp_app] || raise("the :otp_app option is required")
    entrypoint = opts[:entrypoint] || __CALLER__.module

    quote do
      @otp_app unquote(otp_app)
      @entrypoint unquote(entrypoint)

      def config do
        default_config = [
          otp_app: @otp_app,
          entrypoint: @entrypoint
        ]

        Keyword.merge(default_config, Application.get_env(@otp_app, __MODULE__, []))
      end

      def child_spec(_) do
        Orbit.Endpoint.child_spec(config())
      end
    end
  end

  @doc """
  Starts the Capsule supervisor.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    entrypoint = opts[:entrypoint] || raise("the :entrypoint option is required")

    port = opts[:port] || @default_port
    ip = parse_address!(opts[:ip] || "0.0.0.0")
    debug_errors = Keyword.get(opts, :debug_errors, false)

    ti_opts = [
      port: port,
      handler_module: Orbit.Handler,
      handler_options: %{entrypoint: entrypoint, debug_errors: debug_errors},
      transport_module: ThousandIsland.Transports.SSL,
      transport_options:
        [
          ip: ip,
          verify_fun: {&verify_peer/3, %{}},
          verify: :verify_peer,
          fail_if_no_peer_cert: false
        ] ++ cert_opts!(opts) ++ key_opts!(opts)
    ]

    children = [
      {ThousandIsland, ti_opts}
    ]

    with {:ok, sup} <- Supervisor.init(children, strategy: :one_for_one) do
      Logger.info("Orbit capsule is listening at #{bound_address(ip, port)}")
      {:ok, sup}
    end
  end

  defp cert_opts!(opts) do
    opts =
      cond do
        certfile = opts[:certfile] ->
          [certfile: certfile]

        cert = opts[:cert] ->
          [cert: cert]

        cert_pem = opts[:cert_pem] ->
          [cert: decode_pem!(:Certificate, cert_pem)]

        :else ->
          raise "the certificate was not provided; specify one of: :cert, :cert_pem, :certfile"
      end

    # :public_key.cacerts_get/0 is only available in OTP 25+
    with {:module, _} <- Code.ensure_loaded(:public_key),
         true <- function_exported?(:public_key, :cacerts_get, 0) do
      [{:cacerts, apply(:public_key, :cacerts_get, [])} | opts]
    else
      _ -> opts
    end
  end

  defp key_opts!(opts) do
    cond do
      keyfile = opts[:keyfile] ->
        [keyfile: keyfile]

      key = opts[:key] ->
        [key: {:PrivateKeyInfo, key}]

      key_pem = opts[:key_pem] ->
        [key: {:PrivateKeyInfo, decode_pem!(:PrivateKeyInfo, key_pem)}]

      :else ->
        raise "the private key was not provided; specify one of: :key, :key_pem, :keyfile"
    end
  end

  defp decode_pem!(type, pem) when is_binary(pem) do
    case :public_key.pem_decode(pem) do
      [{^type, der, _}] -> der
      _ -> raise "could not decode #{type} PEM"
    end
  end

  defp parse_address!(ip) when is_binary(ip) do
    ip
    |> String.to_charlist()
    |> :inet.parse_address()
    |> case do
      {:ok, ip} -> ip
      _ -> raise "could not parse :ip option #{inspect(ip)}"
    end
  end

  defp parse_address!(ip), do: raise("invalid :ip option #{inspect(ip)}")

  defp bound_address(ip, @default_port) do
    "gemini://#{encode_address(ip)}/"
  end

  defp bound_address(ip, port) do
    "gemini://#{encode_address(ip)}:#{port}/"
  end

  defp encode_address(ip), do: ip |> :inet.ntoa() |> to_string()

  # https://stackoverflow.com/a/32198900
  defp verify_peer(cert, {:bad_cert, :selfsigned_peer}, state) do
    {:valid, Map.put(state, :cert, cert)}
  end

  defp verify_peer(_cert, {:bad_cert, _} = event, _state) do
    # TODO: Respond with :certificate_not_valid status
    {:fail, event}
  end

  defp verify_peer(_cert, {:extension, _}, state) do
    {:unknown, state}
  end

  defp verify_peer(cert, :valid, state) do
    {:valid, Map.put(state, :cert, cert)}
  end

  defp verify_peer(cert, :valid_peer, state) do
    {:valid, Map.put(state, :cert, cert)}
  end

  @doc """
  Returns metadata about the capsule's TLS listener.
  """
  def listener_info(capsule_pid) do
    capsule_pid
    |> Supervisor.which_children()
    |> Enum.flat_map(fn
      {{ThousandIsland, _ref}, pid, _, _} -> [pid]
      _ -> []
    end)
    |> case do
      [pid] -> ThousandIsland.listener_info(pid)
      _ -> :error
    end
  end
end
