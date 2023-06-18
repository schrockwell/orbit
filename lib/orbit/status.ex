defmodule Orbit.Status do
  @moduledoc """
  The canonical list of response status codes.

  This module contains helper functions for applying any status code to an `Orbit.Request`.

  When set manually, status codes may be specified by integer or atom. They can be coerced one way or the other
  with `to_atom/1` and `to_integer/1`.

  | Status | Name |
  | ---- | ---- |
  | 10 | `:input` |
  | 11 | `:sensitive_input` |
  | 20 | `:success` |
  | 30 | `:redirect_temporary` |
  | 31 | `:redirect_permanent` |
  | 40 | `:temporary_failure` |
  | 41 | `:server_unavailable` |
  | 42 | `:cgi_error` |
  | 43 | `:proxy_error` |
  | 44 | `:slow_down` |
  | 50 | `:permanent_failure` |
  | 51 | `:not_found` |
  | 52 | `:gone` |
  | 53 | `:proxy_request_refused` |
  | 59 | `:bad_request` |
  | 60 | `:client_certificate_required` |
  | 61 | `:certificate_not_authorized` |
  | 62 | `:certificate_not_valid` |
  """

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

  @type t :: atom() | non_neg_integer()

  @doc """
  Normalizes a status code to an integer.
  """
  def to_integer(status) when status in @status_keys, do: @status_codes[status]
  def to_integer(status) when status in @status_values, do: status

  @doc """
  Normalizes a status code to an atom.
  """
  def to_atom(status) when status in @status_values, do: @inverted_status_codes[status]
  def to_atom(status) when status in @status_keys, do: status
end
