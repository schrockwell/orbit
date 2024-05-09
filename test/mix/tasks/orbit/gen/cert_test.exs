defmodule Mix.Tasks.Orbit.Gen.CertTest do
  use ExUnit.Case
  doctest Mix.Tasks.Orbit.Gen.Cert

  test "generates a self-signed certificate for localhost by default" do
    # WHEN
    ExUnit.CaptureIO.capture_io(fn ->
      Mix.Tasks.Orbit.Gen.Cert.run([])
    end)

    # THEN
    assert File.exists?("priv/tls/localhost.crt")
    assert File.exists?("priv/tls/localhost.key")

    # CLEANUP
    File.rm("priv/tls/localhost.crt")
    File.rm("priv/tls/localhost.key")
  end

  test "generates a self-signed certificate for a specified domain" do
    # GIVEN
    domain = "example.com"

    # WHEN
    ExUnit.CaptureIO.capture_io(fn ->
      Mix.Tasks.Orbit.Gen.Cert.run([domain])
    end)

    # THEN
    assert File.exists?("priv/tls/#{domain}.crt")
    assert File.exists?("priv/tls/#{domain}.key")

    # CLEANUP
    File.rm("priv/tls/#{domain}.crt")
    File.rm("priv/tls/#{domain}.key")
  end
end
