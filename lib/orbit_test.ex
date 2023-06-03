defmodule OrbitTest do
  @moduledoc """
  Test helpers.
  """

  alias Orbit.Request
  alias Orbit.Status

  @doc """
  Performs a request against a router and returns the processed request.
  """
  def request(router, path) do
    router.call(build_req(path), [])
  end

  @doc """
  Performs a request against `@router` and returns the processed request.
  """
  defmacro request(path) do
    quote do
      request(@router, unquote(path))
    end
  end

  @doc """
  Returns a new `Orbit.Request` struct for testing.

  The `path` should begin with "/".
  """
  def build_req(path) do
    %Request{uri: URI.parse("gemini://localhost#{path}")}
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
end
