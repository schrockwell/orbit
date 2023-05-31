defmodule Orbit.Transaction do
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
          body: IO.chardata() | Stream.t() | nil,
          client_cert: any,
          halted?: boolean,
          meta: IO.chardata() | nil,
          params: %{String.t() => String.t()},
          private: %{optional(atom) => any},
          sent?: boolean,
          status: atom | non_neg_integer,
          uri: %URI{}
        }

  @crlf "\r\n"

  @status_codes %{
    input: 10,
    sensitive_input: 11,
    success: 20,
    redirect_temporary: 30,
    redirect_permanent: 31,
    temporary_failure: 40,
    server_unavailable: 41,
    cgi_error: 42,
    proxy_error: 43,
    slow_down: 44,
    permanent_failure: 50,
    not_found: 51,
    gone: 52,
    proxy_request_refused: 53,
    bad_request: 59,
    client_certificate_required: 60,
    certificate_not_authorized: 61,
    certificate_not_valid: 62
  }
  @inverted_status_codes Map.new(@status_codes, fn {k, v} -> {v, k} end)
  @status_keys Map.keys(@status_codes)
  @status_values Map.values(@status_codes)

  def numeric_status(status) when status in @status_keys, do: @status_codes[status]
  def numeric_status(status) when status in @status_values, do: status

  def human_status(status) when status in @status_values, do: @inverted_status_codes[status]
  def human_status(status) when status in @status_keys, do: status

  def put_status(%__MODULE__{} = trans, status, meta \\ nil) do
    %{trans | status: status, meta: meta}
  end

  def put_body(%__MODULE__{} = trans, body) do
    %{trans | body: body}
  end

  def response_header(%__MODULE__{meta: nil} = trans) do
    [to_string(numeric_status(trans.status)), @crlf]
  end

  def response_header(%__MODULE__{meta: meta} = trans) do
    [to_string(numeric_status(trans.status)), " ", meta, @crlf]
  end

  def input(%__MODULE__{} = trans, prompt) do
    put_status(trans, :input, prompt)
  end

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
end
