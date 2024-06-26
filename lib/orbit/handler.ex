defmodule Orbit.Handler do
  @moduledoc false

  use ThousandIsland.Handler

  require Logger
  alias Orbit.ClientCertificate
  alias Orbit.Status
  alias Orbit.Request

  alias ThousandIsland.Socket

  @max_uri_size 1024
  @crlf_size 2
  @crlf "\r\n"

  @impl ThousandIsland.Handler
  def handle_connection(socket, state) do
    client_cert =
      with {:ok, der} <- :ssl.peercert(socket.socket),
           {:ok, cert} <- ClientCertificate.from_der(der) do
        cert
      else
        _ -> nil
      end

    req = %Request{client_cert: client_cert}

    {:continue, Map.merge(state, %{req: req, buffer: ""})}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %{req: %Request{} = req} = state) do
    buffer = state.buffer <> data

    with {:size, true} <- {:size, byte_size(buffer) <= @max_uri_size + @crlf_size},
         {:first_line, [uri_string, _ | _]} <- {:first_line, String.split(buffer, @crlf)},
         {:uri, uri = %URI{scheme: "gemini"}} <- {:uri, URI.parse(uri_string)} do
      req = %{req | uri: uri}
      entrypoint = state[:entrypoint]

      entrypoint
      |> Orbit.Pipe.call(req, [])
      |> send_response(socket)

      {:close, state}
    else
      {:size, _} ->
        req
        |> Request.put_status(:bad_request, "URI too long")
        |> send_response(socket)

        {:close, state}

      {:first_line, _} ->
        {:continue, %{state | buffer: buffer}}

      {:uri, _} ->
        req
        |> Request.put_status(:bad_request, "Malformed URI")
        |> send_response(socket)

        {:close, state}
    end
  rescue
    error ->
      if state[:debug_errors] do
        req
        |> Orbit.Controller.gmi("""
        # Internal server error

        ## (#{inspect(error.__struct__)}) #{Exception.message(error)}

        ```
        #{Exception.format_stacktrace(__STACKTRACE__)}
        ```
        """)
        |> send_response(socket)
      else
        req
        |> Request.put_status(:temporary_failure, "Internal server error")
        |> send_response(socket)
      end

      {:error, {error, __STACKTRACE__}, state}
  end

  @impl ThousandIsland.Handler
  def handle_error({error, stacktrace}, _socket, _state) when is_exception(error) do
    Kernel.reraise(error, stacktrace)
  end

  def handle_error(_reason, _socket, _state), do: :ok

  defp send_response(%Request{sent?: true}, _socket) do
    raise "response has already been sent"
  end

  defp send_response(%Request{status: nil}, _socket) do
    raise "response status not set"
  end

  defp send_response(%Request{} = req, socket) do
    Socket.send(socket, response_header(req))

    if Status.to_atom(req.status) == :success do
      send_body(req, socket)
    end

    %{req | sent?: true}
  end

  defp response_header(%Request{meta: nil} = req) do
    [to_string(Status.to_integer(req.status)), @crlf]
  end

  defp response_header(%Request{meta: meta} = req) do
    [to_string(Status.to_integer(req.status)), " ", meta, @crlf]
  end

  defp send_body(%Request{body: %struct{} = stream}, socket)
       when struct in [Stream, File.Stream] do
    Enum.each(stream, fn line ->
      Socket.send(socket, line)
    end)
  end

  defp send_body(%Request{body: body}, socket) do
    Socket.send(socket, body)
  end
end
