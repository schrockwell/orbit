defmodule Orbit.ClientCertificateTest do
  use ExUnit.Case

  defp pem_to_der(pem_content) do
    # Regex to find base64 content between the PEM headers and footers
    pattern = ~r/-----BEGIN [^-]+-----\n?(.*?)\n?-----END [^-]+-----/sm

    # Extract and decode the base64 content
    [[_, base64_content]] = Regex.scan(pattern, pem_content)
    :base64.decode(base64_content)
  end

  test "from_der/1 decodes a valid certificate" do
    # GIVEN
    pem = File.read!("test/support/tls/client.pem")
    der = pem_to_der(pem)

    # WHEN
    result = Orbit.ClientCertificate.from_der(der)

    # THEN
    assert {:ok, _} = result
  end

  test "from_der/1 returns an error for an invalid certificate" do
    # GIVEN
    der = <<0, 1, 2, 3, 4, 5, 6, 7>>

    # WHEN
    result = Orbit.ClientCertificate.from_der(der)

    # THEN
    assert {:error, :malformed} = result
  end
end
