defmodule OrbitTest do
  alias Orbit.Request

  defmacro request(path) do
    quote do
      @router.call(%Request{uri: URI.parse("gemini://localhost#{unquote(path)}")}, [])
    end
  end

  def body(%Request{body: stream = %struct{}, status: :success})
      when struct in [Stream, File.Stream] do
    stream |> Enum.to_list() |> :erlang.iolist_to_binary()
  end

  def body(%Request{body: body, status: :success}) when is_list(body) or is_binary(body) do
    :erlang.iolist_to_binary(body)
  end

  def body(_), do: nil
end
