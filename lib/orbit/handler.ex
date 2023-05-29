defmodule Orbit.Handler do
  use ThousandIsland.Handler

  alias Orbit.Transaction

  @impl ThousandIsland.Handler
  def handle_connection(_socket, state) do
    # Nothing right now...
    {:continue, state}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    with true <- String.ends_with?(data, "\r\n"),
         uri_string = String.trim_trailing(data),
         true <- byte_size(uri_string) <= 1024,
         uri = %URI{scheme: "gemini"} <- URI.parse(uri_string) do
      trans = %Transaction{uri: uri}
      router = state[:router]

      trans
      |> router.call([])
      |> Transaction.send(socket)
    else
      _ ->
        %Transaction{}
        |> Transaction.put_status(:bad_request)
        |> Transaction.send(socket)
    end

    {:close, state}
  end
end
