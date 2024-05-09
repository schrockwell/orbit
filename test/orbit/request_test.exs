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

  for {status, atom} <- Orbit.Status.statuses() do
    test "#{status}/1 responds with a #{inspect(atom)} status" do
      # GIVEN
      req = %Orbit.Request{}

      # WHEN
      req = Orbit.Request.unquote(status)(req)

      # THEN
      assert req.status == unquote(status)
      assert req.meta == nil
    end

    test "#{status}/2 responds with a #{inspect(atom)} status and metadata" do
      # GIVEN
      req = %Orbit.Request{}
      meta = "meta"

      # WHEN
      req = Orbit.Request.unquote(status)(req, meta)

      # THEN
      assert req.status == unquote(status)
      assert req.meta == meta
    end
  end
end
