defmodule Orbit.RequestTest do
  use ExUnit.Case

  test "halt/1 sets halted? to true" do
    # GIVEN
    req = %Orbit.Request{}

    # WHEN
    req = Orbit.Request.halt(req)

    # THEN
    assert req.halted? == true
  end

  test "assign/2 sets multiple assigns on the request" do
    # GIVEN
    req = %Orbit.Request{}
    assigns = %{a: 1, b: 2}

    # WHEN
    req = Orbit.Request.assign(req, assigns)

    # THEN
    assert req.assigns == assigns
  end

  test "assign/3 sets a single assign on the request" do
    # GIVEN
    req = %Orbit.Request{}
    key = :a
    value = 1

    # WHEN
    req = Orbit.Request.assign(req, key, value)

    # THEN
    assert req.assigns == %{a: 1}
  end

  test "put_private/3 sets a single private value on the request" do
    # GIVEN
    req = %Orbit.Request{}
    key = :a
    value = 1

    # WHEN
    req = Orbit.Request.put_private(req, key, value)

    # THEN
    assert req.private == %{a: 1}
  end

  test "put_status/3 puts the status and metadata for a response" do
    # GIVEN
    req = %Orbit.Request{}
    status = 20
    meta = "text/plain"

    # WHEN
    req = Orbit.Request.put_status(req, status, meta)

    # THEN
    assert req.status == 20
    assert req.meta == "text/plain"
  end

  test "put_body/2 puts the body for a successful response" do
    # GIVEN
    req = %Orbit.Request{}
    body = "Hello, World!"

    # WHEN
    req = Orbit.Request.put_body(req, body)

    # THEN
    assert req.body == "Hello, World!"
  end

  test "input/2 responds with a :input status" do
    # GIVEN
    req = %Orbit.Request{}
    prompt = "Enter your name"

    # WHEN
    req = Orbit.Request.input(req, prompt)

    # THEN
    assert req.status == :input
    assert req.meta == "Enter your name"
  end

  test "sensitive_input/2 responds with a :sensitive_input status" do
    # GIVEN
    req = %Orbit.Request{}
    prompt = "Enter your password"

    # WHEN
    req = Orbit.Request.sensitive_input(req, prompt)

    # THEN
    assert req.status == :sensitive_input
    assert req.meta == "Enter your password"
  end

  test "success/2 responds with a :success status" do
    # GIVEN
    req = %Orbit.Request{}
    mime_type = "text/plain"

    # WHEN
    req = Orbit.Request.success(req, mime_type)

    # THEN
    assert req.status == :success
    assert req.meta == "text/plain"
  end

  test "redirect_temporary/2 responds with a :redirect_temporary status" do
    # GIVEN
    req = %Orbit.Request{}
    uri = "/new"

    # WHEN
    req = Orbit.Request.redirect_temporary(req, uri)

    # THEN
    assert req.status == :redirect_temporary
    assert req.meta == "/new"
  end

  test "redirect_permanent/2 responds with a :redirect_permanent status" do
    # GIVEN
    req = %Orbit.Request{}
    uri = "/new"

    # WHEN
    req = Orbit.Request.redirect_permanent(req, uri)

    # THEN
    assert req.status == :redirect_permanent
    assert req.meta == "/new"
  end

  test "temporary_failure/2 responds with a :temporary_failure status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Server is down"

    # WHEN
    req = Orbit.Request.temporary_failure(req, message)

    # THEN
    assert req.status == :temporary_failure
    assert req.meta == "Server is down"
  end

  test "server_unavailable/2 responds with a :server_unavailable status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Server is down"

    # WHEN
    req = Orbit.Request.server_unavailable(req, message)

    # THEN
    assert req.status == :server_unavailable
    assert req.meta == "Server is down"
  end

  test "cgi_error/2 responds with a :cgi_error status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "CGI error"

    # WHEN
    req = Orbit.Request.cgi_error(req, message)

    # THEN
    assert req.status == :cgi_error
    assert req.meta == "CGI error"
  end

  test "proxy_error/2 responds with a :proxy_error status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Proxy error"

    # WHEN
    req = Orbit.Request.proxy_error(req, message)

    # THEN
    assert req.status == :proxy_error
    assert req.meta == "Proxy error"
  end

  test "slow_down/2 responds with a :slow_down status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Slow down"

    # WHEN
    req = Orbit.Request.slow_down(req, message)

    # THEN
    assert req.status == :slow_down
    assert req.meta == "Slow down"
  end

  test "permanent_failure/2 responds with a :permanent_failure status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Permanent failure"

    # WHEN
    req = Orbit.Request.permanent_failure(req, message)

    # THEN
    assert req.status == :permanent_failure
    assert req.meta == "Permanent failure"
  end

  test "not_found/2 responds with a :not_found status and a message" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Resource not found"

    # WHEN
    req = Orbit.Request.not_found(req, message)

    # THEN
    assert req.status == :not_found
    assert req.meta == "Resource not found"
  end

  test "gone/2 responds with a :gone status and a message" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Resource is gone"

    # WHEN
    req = Orbit.Request.gone(req, message)

    # THEN
    assert req.status == :gone
    assert req.meta == "Resource is gone"
  end

  test "proxy_request_refused/2 responds with a :proxy_request_refused status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Proxy request refused"

    # WHEN
    req = Orbit.Request.proxy_request_refused(req, message)

    # THEN
    assert req.status == :proxy_request_refused
    assert req.meta == "Proxy request refused"
  end

  test "bad_request/2 responds with a :bad_request status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Bad request"

    # WHEN
    req = Orbit.Request.bad_request(req, message)

    # THEN
    assert req.status == :bad_request
    assert req.meta == "Bad request"
  end

  test "client_certificate_required/2 responds with a :client_certificate_required status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Client certificate required"

    # WHEN
    req = Orbit.Request.client_certificate_required(req, message)

    # THEN
    assert req.status == :client_certificate_required
    assert req.meta == "Client certificate required"
  end

  test "certificate_not_authorized/2 responds with a :certificate_not_authorized status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Certificate not authorized"

    # WHEN
    req = Orbit.Request.certificate_not_authorized(req, message)

    # THEN
    assert req.status == :certificate_not_authorized
    assert req.meta == "Certificate not authorized"
  end

  test "certificate_not_valid/2 responds with a :certificate_not_valid status" do
    # GIVEN
    req = %Orbit.Request{}
    message = "Certificate not valid"

    # WHEN
    req = Orbit.Request.certificate_not_valid(req, message)

    # THEN
    assert req.status == :certificate_not_valid
    assert req.meta == "Certificate not valid"
  end
end
