defmodule Orbit.Handler do
  use ThousandIsland.Handler

  alias Orbit.Transaction

  alias ThousandIsland.Socket

  @impl ThousandIsland.Handler
  def handle_connection(socket, state) do
    client_cert =
      case :ssl.peercert(socket.socket) do
        {:ok, der} -> :public_key.pkix_decode_cert(der, :plain)
        _ -> nil
      end

    trans = %Transaction{client_cert: client_cert}

    {:continue, Map.put(state, :trans, trans)}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %{trans: %Transaction{} = trans} = state) do
    with true <- String.ends_with?(data, "\r\n"),
         uri_string = String.trim_trailing(data),
         true <- byte_size(uri_string) <= 1024,
         uri = %URI{scheme: "gemini"} <- URI.parse(uri_string) do
      trans = %{trans | uri: uri}
      router = state[:router]

      trans
      |> router.call([])
      |> send_response(socket)
    else
      _ ->
        trans
        |> Transaction.put_status(:bad_request)
        |> send_response(socket)
    end

    {:close, state}
  rescue
    error ->
      trans
      |> Transaction.put_status(:temporary_failure, "Internal server error")
      |> send_response(socket)

      {:error, error, state}
  end

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
