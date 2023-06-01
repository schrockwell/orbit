defmodule Orbit.Handler do
  @moduledoc false

  use ThousandIsland.Handler

  alias Orbit.Transaction

  alias ThousandIsland.Socket

  @max_uri_size 1024
  @crlf_size 2

  @impl ThousandIsland.Handler
  def handle_connection(socket, state) do
    client_cert =
      case :ssl.peercert(socket.socket) do
        {:ok, der} -> :public_key.pkix_decode_cert(der, :plain)
        _ -> nil
      end

    trans = %Transaction{client_cert: client_cert}

    {:continue, Map.merge(state, %{trans: trans, buffer: ""})}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %{trans: %Transaction{} = trans} = state) do
    buffer = state.buffer <> data

    with {:size, true} <- {:size, byte_size(buffer) <= @max_uri_size + @crlf_size},
         {:first_line, [uri_string, _ | _]} <- {:first_line, String.split(buffer, "\r\n")},
         {:uri, uri = %URI{scheme: "gemini"}} <- {:uri, URI.parse(uri_string)} do
      trans = %{trans | uri: uri}
      endpoint = state[:endpoint]

      trans
      |> endpoint.call([])
      |> send_response(socket)

      {:close, state}
    else
      {:size, _} ->
        trans
        |> Transaction.put_status(:bad_request, "URI too long")
        |> send_response(socket)

        {:close, state}

      {:first_line, _} ->
        {:continue, %{state | buffer: buffer}}

      {:uri, _} ->
        trans
        |> Transaction.put_status(:bad_request, "Malformed URI")
        |> send_response(socket)

        {:close, state}
    end
  rescue
    error ->
      trans
      |> Transaction.put_status(:temporary_failure, "Internal server error")
      |> send_response(socket)

      {:error, {error, __STACKTRACE__}, state}
  end

  @impl ThousandIsland.Handler
  def handle_error({error, stacktrace}, _socket, _state) when is_exception(error) do
    Kernel.reraise(error, stacktrace)
  end

  def handle_error(_reason, _socket, _state), do: :ok

  defp send_response(%Transaction{sent?: true}, _socket) do
    raise "response has already been sent"
  end

  defp send_response(%Transaction{} = trans, socket) do
    Socket.send(socket, Transaction.response_header(trans))

    if Transaction.human_status(trans.status) == :success do
      send_body(trans, socket)
    end

    %{trans | sent?: true}
  end

  defp send_body(%Transaction{body: %struct{} = stream}, socket)
       when struct in [Stream, File.Stream] do
    Enum.each(stream, fn line ->
      Socket.send(socket, line)
    end)
  end

  defp send_body(%Transaction{body: body}, socket) do
    Socket.send(socket, body)
  end
end
