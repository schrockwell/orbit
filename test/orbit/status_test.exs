defmodule Orbit.StatusTest do
  use ExUnit.Case

  alias Orbit.Status

  test "to_atom/1 converts an integer status code to an atom" do
    assert Status.to_atom(10) == :input
    assert Status.to_atom(11) == :sensitive_input
    assert Status.to_atom(20) == :success
    assert Status.to_atom(30) == :redirect_temporary
    assert Status.to_atom(31) == :redirect_permanent
    assert Status.to_atom(40) == :temporary_failure
    assert Status.to_atom(41) == :server_unavailable
    assert Status.to_atom(42) == :cgi_error
    assert Status.to_atom(43) == :proxy_error
    assert Status.to_atom(44) == :slow_down
    assert Status.to_atom(50) == :permanent_failure
    assert Status.to_atom(51) == :not_found
    assert Status.to_atom(52) == :gone
    assert Status.to_atom(53) == :proxy_request_refused
    assert Status.to_atom(59) == :bad_request
    assert Status.to_atom(60) == :client_certificate_required
    assert Status.to_atom(61) == :certificate_not_authorized
    assert Status.to_atom(62) == :certificate_not_valid
  end

  test "to_integer/1 converts an atom status code to an integer" do
    assert Status.to_integer(:input) == 10
    assert Status.to_integer(:sensitive_input) == 11
    assert Status.to_integer(:success) == 20
    assert Status.to_integer(:redirect_temporary) == 30
    assert Status.to_integer(:redirect_permanent) == 31
    assert Status.to_integer(:temporary_failure) == 40
    assert Status.to_integer(:server_unavailable) == 41
    assert Status.to_integer(:cgi_error) == 42
    assert Status.to_integer(:proxy_error) == 43
    assert Status.to_integer(:slow_down) == 44
    assert Status.to_integer(:permanent_failure) == 50
    assert Status.to_integer(:not_found) == 51
    assert Status.to_integer(:gone) == 52
    assert Status.to_integer(:proxy_request_refused) == 53
    assert Status.to_integer(:bad_request) == 59
    assert Status.to_integer(:client_certificate_required) == 60
    assert Status.to_integer(:certificate_not_authorized) == 61
    assert Status.to_integer(:certificate_not_valid) == 62
  end
end
