defmodule OrbitTest.Test do
  use ExUnit.Case

  require OrbitTest

  test "build_client_cert/2" do
    # WHEN
    cert = OrbitTest.build_client_cert("schrockwell")

    # THEN
    assert %Orbit.ClientCertificate{common_name: "schrockwell", self_signed?: true} = cert
    assert DateTime.diff(cert.not_valid_after, DateTime.utc_now()) <= 60 * 60 * 24
    assert DateTime.diff(DateTime.utc_now(), cert.not_valid_before) <= 5 * 60
  end

  test "status/1" do
    # GIVEN
    request = %Orbit.Request{status: 20}

    # WHEN
    status = OrbitTest.status(request)

    # THEN
    assert :success == status
  end

  test "meta/1" do
    # GIVEN
    request = %Orbit.Request{meta: "meta"}

    # WHEN
    meta = OrbitTest.meta(request)

    # THEN
    assert "meta" == meta
  end

  test "body/1 with a non-20 response code" do
    # GIVEN
    request = %Orbit.Request{status: 30}

    # WHEN
    body = OrbitTest.body(request)

    # THEN
    assert nil == body
  end

  test "body/1 with a Stream or File.Stream body" do
    # GIVEN
    request = %Orbit.Request{body: File.stream!("priv/static/index.gmi"), status: 20}

    # WHEN
    body = OrbitTest.body(request)

    # THEN
    assert body == "# Hello, world!"
  end

  test "request/1 with a map of query params" do
    # GIVEN
    pipe = fn req, _ ->
      Orbit.Controller.gmi(req, inspect(req.params))
    end

    # WHEN
    req = OrbitTest.request("test", router: pipe, query: %{name: "schrockwell"})

    # THEN
    assert req.uri.query == "name=schrockwell"
  end

  test "request/1 with a query string" do
    # GIVEN
    pipe = fn req, _ ->
      Orbit.Controller.gmi(req, inspect(req.params))
    end

    # WHEN
    req = OrbitTest.request("test", router: pipe, query: "foobar")

    # THEN
    assert req.uri.query == "foobar"
  end

  test "request/1 with an invalid query opt" do
    # GIVEN
    pipe = fn req, _ ->
      Orbit.Controller.gmi(req, inspect(req.params))
    end

    # WHEN/THEN
    assert_raise RuntimeError, fn ->
      OrbitTest.request("test", router: pipe, query: 123)
    end
  end
end
