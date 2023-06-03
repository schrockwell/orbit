defmodule Orbit.Request do
  @moduledoc """
  Encapsulate the request-response cycle.

  Analgous to `%Plug.Conn{}`.

  ## Request Fields

  - `client_cert` - the client TLS certificate
  - `params` - combined request parameters from the URI and query params
  - `uri` - the parsed request URI

  ## Response Fields

  - `body` - the response body; may be an iolist or a stream
  - `halted?` - if the current response pipeline should be stopped prematurely
  - `meta` - the response meta field, meaning depends on the status code
  - `status` - the response status code, may be an integer or an atom (see below)
  - `sent?` - if the response has been transmitted back to the client

  ## Application Fields

  - `assigns` - a generic map of application-defined data to be manipulated and rendered
  - `private` - a generic map of library-defined data that should not be accessed by end-users

  """
  defstruct assigns: %{},
            body: [],
            client_cert: nil,
            halted?: false,
            meta: nil,
            params: %{},
            private: %{},
            sent?: false,
            status: nil,
            uri: %URI{}

  @type t :: %__MODULE__{
          assigns: %{atom => any},
          body: IO.chardata() | %Stream{} | nil,
          client_cert: any,
          halted?: boolean,
          meta: IO.chardata() | nil,
          params: %{String.t() => String.t()},
          private: %{optional(atom) => any},
          sent?: boolean,
          status: Orbit.Status.t(),
          uri: %URI{}
        }

  @doc """
  Stops the request pipeline from further execution.
  """
  def halt(%__MODULE__{} = req), do: %{req | halted?: true}

  @doc """
  Sets multiple assigns on the request.
  """
  def assign(%__MODULE__{} = req, assigns) do
    %{req | assigns: Enum.into(assigns, req.assigns)}
  end

  @doc """
  Sets a single assign on the request.
  """
  def assign(%__MODULE__{} = req, key, value) do
    %{req | assigns: Map.put(req.assigns, key, value)}
  end

  @doc """
  Sets a single private value on the request.
  """
  def put_private(%__MODULE__{} = req, key, value) when is_atom(key) do
    %{req | private: Map.put(req.private, key, value)}
  end

  @doc """
  Puts the status and metadata for a response.

  If the status code is non-successful, then the response body will be ignored and not sent to the client.

  The status can be an integer or an atom. See `Orbit.Status` for a list of applicable status codes and
  convenience functions.
  """
  def put_status(%__MODULE__{} = req, status, meta \\ nil) do
    %{req | status: status, meta: meta}
  end

  @doc """
  Puts the body and MIME type for a successful response.

  The MIME type is optional. If unspecified, clients will default to "text/gemini; charset=utf-8".
  """
  def put_body(%__MODULE__{} = req, body, mime_type \\ nil) do
    %{req | body: body, meta: mime_type}
  end
end
