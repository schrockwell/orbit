defmodule Orbit.Transaction do
  @moduledoc """
  The request-response cycle.

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

  ## Other Fields

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

  def halt(%__MODULE__{} = trans), do: %{trans | halted?: true}

  def assign(%__MODULE__{} = trans, assigns) do
    %{trans | assigns: Enum.into(assigns, trans.assigns)}
  end

  def assign(%__MODULE__{} = trans, key, value) do
    %{trans | assigns: Map.put(trans.assigns, key, value)}
  end

  def put_private(%__MODULE__{} = trans, key, value) when is_atom(key) do
    %{trans | private: Map.put(trans.private, key, value)}
  end

  @doc """
  Puts the status and metadata for a response.

  If the status code is non-successful, then the response body will be ignore and not sent.

  The status can be an integer or an atom. See `Orbit.Status` for a list of applicable status codes and
  convenience functions.
  """
  def put_status(%__MODULE__{} = trans, status, meta \\ nil) do
    %{trans | status: status, meta: meta}
  end

  @doc """
  Puts the body and MIME type for a successful response.

  The MIME type is optional. If unspecified, clients will default to "text/gemini; charset=utf-8".
  """
  def put_body(%__MODULE__{} = trans, body, mime_type \\ nil) do
    %{trans | body: body, meta: mime_type}
  end
end
