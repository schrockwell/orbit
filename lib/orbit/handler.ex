defmodule Orbit.Handler do
  use ThousandIsland.Handler

  alias Orbit.Transaction

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
      |> Transaction.send(socket)
    else
      _ ->
        trans
        |> Transaction.put_status(:bad_request)
        |> Transaction.send(socket)
    end

    {:close, state}
  end
end
