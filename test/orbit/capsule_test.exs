defmodule Orbit.CapsuleTest do
  use ExUnit.Case

  import Orbit.Controller
  import OrbitTest

  setup do
    entrypoint = fn req, _ ->
      gmi(req, "Hello, world!")
    end

    {:ok,
     %{
       entrypoint: entrypoint,
       config: [
         entrypoint: entrypoint,
         certfile: "test/support/tls/localhost.pem",
         keyfile: "test/support/tls/localhost-key.pem"
       ]
     }}
  end

  test "it can be started with cert and key files", %{config: config} do
    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    resp = tls_request("localhost", "/whatever")

    # THEN
    assert resp == "20 text/gemini; charset=utf-8\r\nHello, world!"
  end

  test "it can be started with cert and key PEM", %{entrypoint: entrypoint} do
    # GIVEN
    config = [
      entrypoint: entrypoint,
      cert_pem: File.read!("test/support/tls/localhost.pem"),
      key_pem: File.read!("test/support/tls/localhost-key.pem")
    ]

    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    resp = tls_request("localhost", "/whatever")

    # THEN
    assert resp == "20 text/gemini; charset=utf-8\r\nHello, world!"
  end

  test "it can be started with a DER-encoded cert and key" do
    # GIVEN
    entrypoint = fn req, _ ->
      gmi(req, "Hello, world!")
    end

    config = [
      entrypoint: entrypoint,
      cert: File.read!("test/support/tls/localhost.pem") |> :public_key.pem_decode() |> hd() |> elem(1),
      key: File.read!("test/support/tls/localhost-key.pem") |> :public_key.pem_decode() |> hd() |> elem(1)
    ]

    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    resp = tls_request("localhost", "/whatever")

    # THEN
    assert resp == "20 text/gemini; charset=utf-8\r\nHello, world!"
  end

  test "it can be started on a separate port", %{config: config} do
    # GIVEN
    config = Keyword.put(config, :port, 1900)

    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    resp =
      tls_request("localhost", "/whatever", port: 1900)

    # THEN
    assert resp == "20 text/gemini; charset=utf-8\r\nHello, world!"
  end

  test "raises if a cert is not provided", %{config: config} do
    # GIVEN
    config = Keyword.delete(config, :certfile)

    # WHEN
    result = start_supervised({Orbit.Capsule, config})

    # THEN
    assert {:error,
            {{%RuntimeError{
                message: "the certificate was not provided; specify one of: :cert, :cert_pem, :certfile"
              }, _}, _}} = result
  end

  test "raises if a key is not provided", %{config: config} do
    # GIVEN
    config = Keyword.delete(config, :keyfile)

    # WHEN
    result = start_supervised({Orbit.Capsule, config})

    # THEN
    assert {:error,
            {{%RuntimeError{
                message: "the private key was not provided; specify one of: :key, :key_pem, :keyfile"
              }, _}, _}} = result
  end

  test "raises if an entrypoint is not provided", %{config: config} do
    # GIVEN
    config = Keyword.delete(config, :entrypoint)

    # WHEN
    result = start_supervised({Orbit.Capsule, config})

    # THEN
    assert {:error,
            {{%RuntimeError{
                message: "the :entrypoint option is required"
              }, _}, _}} = result
  end

  test "listener_info/1", %{config: config} do
    # WHEN
    {{:ok, pid}, _} =
      ExUnit.CaptureLog.with_log(fn ->
        start_supervised({Orbit.Capsule, config})
      end)

    info = Orbit.Capsule.listener_info(pid)

    # THEN
    assert info == {:ok, {{0, 0, 0, 0}, 1965}}
  end

  test "invalid :ip string", %{config: config} do
    # GIVEN
    config = Keyword.put(config, :ip, "invalid")

    # WHEN
    result = start_supervised({Orbit.Capsule, config})

    # THEN
    assert {:error,
            {{%RuntimeError{
                message: "could not parse :ip option \"invalid\""
              }, _}, _}} = result
  end

  test "invalid :ip option", %{config: config} do
    # GIVEN
    config = Keyword.put(config, :ip, {127, 0, 0, 1})

    # WHEN
    result = start_supervised({Orbit.Capsule, config})

    # THEN
    assert {:error,
            {{%RuntimeError{
                message: "invalid :ip option {127, 0, 0, 1}"
              }, _}, _}} = result
  end

  test "self-signed client certificate", %{config: config} do
    # GIVEN
    ssl_opts = [
      certfile: "test/support/tls/client.pem",
      keyfile: "test/support/tls/client-key.pem"
    ]

    parent = self()

    config =
      Keyword.put(config, :entrypoint, fn req, _ ->
        send(parent, {:request, req})
        gmi(req, "Hello, world!")
      end)

    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    resp = tls_request("localhost", "/whatever", ssl: ssl_opts)

    # THEN
    assert resp == "20 text/gemini; charset=utf-8\r\nHello, world!"
    assert_received {:request, %Orbit.Request{} = req}
    assert %Orbit.ClientCertificate{common_name: "client"} = req.client_cert
  end

  test "returns an error if the URI is too long", %{config: config} do
    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    resp = tls_request("localhost", "/#{String.duplicate("a", 1024)}")

    # THEN
    assert resp == "59 URI too long\r\n"
  end

  test "returns an error if the URI is malformed", %{config: config} do
    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    resp = tls_request("localhost", "foobar://bat/bax")

    # THEN
    assert resp == "59 Malformed URI\r\n"
  end

  test "returns a stacktrace if :debug_errors is true", %{config: config} do
    # GIVEN
    config = Keyword.merge(config, debug_errors: true, entrypoint: fn _, _ -> raise "boom" end)

    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    {resp, _} =
      ExUnit.CaptureLog.with_log(fn ->
        tls_request("localhost", "/")
      end)

    # THEN
    assert String.starts_with?(resp, "20 text/gemini; charset=utf-8\r\n")
    assert String.contains?(resp, "Orbit.CapsuleTest")
  end

  test "returns :temporary_failure on an exception", %{config: config} do
    # GIVEN
    config = Keyword.put(config, :entrypoint, fn _, _ -> raise "boom" end)

    # WHEN
    {resp, _} =
      ExUnit.CaptureLog.with_log(fn ->
        {:ok, _pid} = start_supervised({Orbit.Capsule, config})
        tls_request("localhost", "/")
      end)

    # THEN
    assert resp == "40 Internal server error\r\n"
  end

  test "raises if the response is sent twice", %{config: config} do
    # GIVEN
    config =
      Keyword.put(config, :entrypoint, fn req, _ ->
        # this is a contrived example...
        req
        |> Map.put(:sent?, true)
        |> gmi("Hello, world!")
      end)

    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    {resp, _} =
      ExUnit.CaptureLog.with_log(fn ->
        tls_request("localhost", "/")
      end)

    # THEN
    assert resp == "40 Internal server error\r\n"
  end

  test "raises if the response status code is not set", %{config: config} do
    # GIVEN
    config =
      Keyword.put(config, :entrypoint, fn req, _ ->
        req
      end)

    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    {resp, _} =
      ExUnit.CaptureLog.with_log(fn ->
        tls_request("localhost", "/")
      end)

    # THEN
    assert resp == "40 Internal server error\r\n"
  end

  test "handles responses with nil meta", %{config: config} do
    # GIVEN
    config =
      Keyword.put(config, :entrypoint, fn req, _ ->
        req
        |> gmi("Hello, world!")
        |> Map.put(:meta, nil)
      end)

    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    resp = tls_request("localhost", "/")

    # THEN
    assert resp == "20\r\nHello, world!"
  end

  test "sends files", %{config: config} do
    # GIVEN
    config =
      Keyword.put(config, :entrypoint, fn req, _ ->
        req
        |> send_file("priv/static/index.gmi")
      end)

    # WHEN
    ExUnit.CaptureLog.capture_log(fn ->
      {:ok, _pid} = start_supervised({Orbit.Capsule, config})
    end)

    {resp, _} =
      ExUnit.CaptureLog.with_log(fn ->
        tls_request("localhost", "/")
      end)

    # THEN
    assert resp == "20 text/gemini; charset=utf-8\r\n# Hello, world!"
  end
end
