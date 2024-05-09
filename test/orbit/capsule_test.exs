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
    {:ok, pid} = start_supervised({Orbit.Capsule, config})

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
end
