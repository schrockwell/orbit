defmodule OrbitTest do
  @moduledoc """
  Test helpers.
  """

  alias Orbit.ClientCertificate
  alias Orbit.Request
  alias Orbit.Status

  @doc """
  Performs a request and returns the processed request.

  If `path_or_url` begins with `"/"`, a path is assumed and the requested URL becomes `"gemini://localhost/<path>"`.

  ## Options

  - `:client_cert` - the client certificate, which can be constructed with `build_client_cert/2`
  - `:query` - the URL query string, or key/value pairs as a map or keyword list
  """
  def request(entrypoint, path_or_url, opts \\ []) do
    query =
      case opts[:query] do
        kvs when is_list(kvs) or is_map(kvs) -> URI.encode_query(kvs, :rfc3986)
        binary when is_binary(binary) -> binary
        nil -> nil
        _ -> raise "invalid value for `:query` option; must be a keyword list, map, string, or nil"
      end

    uri =
      path_or_url
      |> to_absolute_uri("localhost", 1965)
      |> URI.parse()
      |> Map.put(:query, query)

    request = %Request{
      uri: uri,
      client_cert: opts[:client_cert]
    }

    Orbit.Pipe.call(entrypoint, request, [])
  end

  @doc """
  Returns the response body as a binary.

  Returns `nil` if the status was not a success.
  """
  def body(%Request{status: status}) when status not in [20, :success], do: nil

  def body(%Request{body: stream = %struct{}}) when struct in [Stream, File.Stream] do
    stream |> Enum.to_list() |> :erlang.iolist_to_binary()
  end

  def body(%Request{body: body}) when is_list(body) or is_binary(body) do
    :erlang.iolist_to_binary(body)
  end

  @doc """
  Returns the response status code as an atom.
  """
  def status(%Request{status: status}), do: Status.to_atom(status)

  @doc """
  Returns the response meta field.
  """
  def meta(%Request{meta: meta}), do: meta

  @doc """
  Returns a new self-signed `Orbit.ClientCertificate` for testing.

  ## Options

  - `:days` - the number of days of validity; defaults to 1 day
  """
  def build_client_cert(common_name, opts \\ []) do
    days = opts[:days] || 1

    private_key = X509.PrivateKey.new_rsa(2048)
    otp_cert = X509.Certificate.self_signed(private_key, "CN=#{common_name}", validity: days)

    otp_cert
    |> X509.Certificate.to_der()
    |> ClientCertificate.from_der()
    |> elem(1)
  end

  @doc """
  Performs a full request to a Gemini server over TLS

  If the `uri` begins with "/", a path is assumed and the requested URL becomes `"gemini://<host>:<port><path>"`.

  ## Options

  - `:port` - the port to connect to; defaults to `1965`
  - `:ssl` - the SSL options, passed on to `:ssl.connect/3`
  """
  @spec tls_request(String.t(), String.t(), Keyword.t()) :: String.t()
  def tls_request(host, uri, opts \\ []) do
    port = opts[:port] || 1965
    ssl_opts = opts[:ssl] || []
    host = ~c"#{host}"

    uri = to_absolute_uri(uri, host, port)

    # Open TLS client
    ssl_opts = Keyword.merge([verify: :verify_none, active: false], ssl_opts)
    {:ok, socket} = :ssl.connect(host, port, ssl_opts)

    # Send request
    :ok = :ssl.send(socket, ~c"#{uri}\r\n")

    # Read response
    {:ok, response} = read_ssl_response(socket, [])

    # Convert to String
    :erlang.iolist_to_binary(response)
  end

  defp read_ssl_response(socket, acc) do
    case :ssl.recv(socket, 0, 5000) do
      {:ok, data} ->
        read_ssl_response(socket, acc ++ [data])

      {:error, :closed} ->
        # Combine all parts of the message
        {:ok, acc |> Enum.join("")}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp to_absolute_uri(uri, host, port) do
    case {to_string(uri), port} do
      {"/" <> path, 1965} ->
        "gemini://#{host}/#{path}"

      {"/" <> path, port} ->
        "gemini://#{host}:#{port}/#{path}"

      {uri, _port} ->
        uri
    end
  end
end
