defmodule Orbit.Request do
  @moduledoc """
  Encapsulate the request-response cycle.

  Analogous to `%Plug.Conn{}`.

  ## Request Fields

  - `client_cert` - an `Orbit.ClientCertificate` for the client TLS certificate, if provided
  - `params` - combined request parameters from the URI and query params
    - bare query strings (e.g. `"?foo"`) are assigned to the `"_query"` key
  - `uri` - the parsed request `URI` struct

  ## Response Fields

  - `body` - the response body; may be an iolist or a stream
  - `halted?` - if the current response pipeline should be stopped prematurely
  - `meta` - the response meta field; its meaning depends on the status code
  - `status` - the response status code, may be an integer or an atom (see `Orbit.Status`)
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

  defguardp is_meta(meta) when is_nil(meta) or is_binary(meta)

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
  Puts the body for a successful response.

  The MIME type is specified via the `meta` argument of `put_status/3`.
  """
  def put_body(%__MODULE__{} = req, body) do
    %{req | body: body}
  end

  @doc """
  Responds with a :input status.
  """
  @doc section: :status
  def input(req, prompt \\ nil) when is_meta(prompt) do
    put_status(req, :input, prompt)
  end

  @doc """
  Responds with a :sensitive_input status.
  """
  @doc section: :status
  def sensitive_input(req, prompt \\ nil) when is_meta(prompt) do
    put_status(req, :sensitive_input, prompt)
  end

  @doc """
  Responds with a :success status.
  """
  @doc section: :status
  def success(req, mime_type \\ nil) when is_meta(mime_type) do
    put_status(req, :success, mime_type)
  end

  @doc """
  Responds with a :redirect_temporary status.
  """
  @doc section: :status
  def redirect_temporary(req, uri \\ nil) when is_meta(uri) do
    put_status(req, :redirect_temporary, uri)
  end

  @doc """
  Responds with a :redirect_permanent status.
  """
  @doc section: :status
  def redirect_permanent(req, uri \\ nil) when is_meta(uri) do
    put_status(req, :redirect_permanent, uri)
  end

  @doc """
  Responds with a :temporary_failure status.
  """
  @doc section: :status
  def temporary_failure(req, message \\ nil) when is_meta(message) do
    put_status(req, :temporary_failure, message)
  end

  @doc """
  Responds with a :server_unavailable status.
  """
  @doc section: :status
  def server_unavailable(req, message \\ nil) when is_meta(message) do
    put_status(req, :server_unavailable, message)
  end

  @doc """
  Responds with a :cgi_error status.
  """
  @doc section: :status
  def cgi_error(req, message \\ nil) when is_meta(message) do
    put_status(req, :cgi_error, message)
  end

  @doc """
  Responds with a :proxy_error status.
  """
  @doc section: :status
  def proxy_error(req, message \\ nil) when is_meta(message) do
    put_status(req, :proxy_error, message)
  end

  @doc """
  Responds with a :slow_down status.
  """
  @doc section: :status
  def slow_down(req, message \\ nil) when is_meta(message) do
    put_status(req, :slow_down, message)
  end

  @doc """
  Responds with a :permanent_failure status.
  """
  @doc section: :status
  def permanent_failure(req, message \\ nil) when is_meta(message) do
    put_status(req, :permanent_failure, message)
  end

  @doc """
  Responds with a :not_found status.
  """
  @doc section: :status
  def not_found(req, message \\ nil) when is_meta(message) do
    put_status(req, :not_found, message)
  end

  @doc """
  Responds with a :gone status.
  """
  @doc section: :status
  def gone(req, message \\ nil) when is_meta(message) do
    put_status(req, :gone, message)
  end

  @doc """
  Responds with a :proxy_request_refused status.
  """
  @doc section: :status
  def proxy_request_refused(req, message \\ nil) when is_meta(message) do
    put_status(req, :proxy_request_refused, message)
  end

  @doc """
  Responds with a :bad_request status.
  """
  @doc section: :status
  def bad_request(req, message \\ nil) when is_meta(message) do
    put_status(req, :bad_request, message)
  end

  @doc """
  Responds with a :client_certificate_required status.
  """
  @doc section: :status
  def client_certificate_required(req, message \\ nil) when is_meta(message) do
    put_status(req, :client_certificate_required, message)
  end

  @doc """
  Responds with a :certificate_not_authorized status.
  """
  @doc section: :status
  def certificate_not_authorized(req, message \\ nil) when is_meta(message) do
    put_status(req, :certificate_not_authorized, message)
  end

  @doc """
  Responds with a :certificate_not_valid status.
  """
  @doc section: :status
  def certificate_not_valid(req, message \\ nil) when is_meta(message) do
    put_status(req, :certificate_not_valid, message)
  end
end
