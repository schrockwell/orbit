defmodule Orbit.Capsule do
  @moduledoc """
  The main endpoint supervisor.

  ## Options

  ### Required

  - `:endpoint` - the `Orbit.Pipe` entry point that gets called on every request, typically an `Orbit.Router`

  - One of:
    - `:certfile` - path to a TLS certificatefile in the PEM format
    - `:cert` - a DER-encoded certificate binary
    - `:cert_pem` - a PEM-encoded certificate binary

  - One of:
    - `:keyfile` - path to a TLS private key file in the PEM format
    - `:key` - a DER-encoded private key binary
    - `:key_pem` - a PEM-encoded private key binary

  ### Optional

  - `:ip` - the IP to listen on; could be `:any`, `:loopback`, or an address string; defaults to `:any`
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
    endpoint = opts[:endpoint] || "the :endpoint option is required"

    port = opts[:port] || 1965
    ip = parse_address!(opts[:ip] || :any)

    ti_opts = [
      port: port,
      handler_module: Orbit.Handler,
      handler_options: %{endpoint: endpoint},
      transport_module: ThousandIsland.Transports.SSL,
      transport_options:
        [
          ip: ip,
          verify_fun: {&verify_peer/3, %{}},
          verify: :verify_peer
        ] ++ cert_opts!(opts) ++ key_opts!(opts)
    ]

    children = [
      {ThousandIsland, ti_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp cert_opts!(opts) do
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

  defp parse_address!(:any), do: :any
  defp parse_address!(:loopback), do: :loopback

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
