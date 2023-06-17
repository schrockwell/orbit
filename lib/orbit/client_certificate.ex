defmodule Orbit.ClientCertificate do
  @moduledoc """
  Stores commonly-used fields from the TLS client certificate.

  The original `OTPCertificate` record is available in the `otp_certificate` field. The [X509](https://hexdocs.pm/x509/)
  library is included and can be used to extract additional values from the `otp_certificate`.

  ## Fields

  - `common_name` - the common name (CN) string
  - `fingerprints` - a map of base-16 fingerprints for various hashes
    - `:sha` for SHA-1
    - `:sha256` for SHA-256
  - `not_valid_after` - the UTC DateTime at the end of validitiy
  - `not_valid_before` - the UTC DateTime at the beginning of validitiy
  - `otp_certificate` - the underlying `OTPCertificate` record
  - `self_signed?` - if the certificate has been self-signed (issuer is the same as the subject)
  - `serial_number` - the serial number integer

  """
  defstruct [
    :common_name,
    :fingerprints,
    :not_valid_after,
    :not_valid_before,
    :otp_certificate,
    :self_signed?,
    :serial_number
  ]

  @type t :: %__MODULE__{
          common_name: String.t(),
          otp_certificate: X509.Certificate.t(),
          serial_number: non_neg_integer(),
          not_valid_before: DateTime.t(),
          not_valid_after: DateTime.t(),
          self_signed?: boolean(),
          fingerprints: %{
            sha: String.t(),
            sha256: String.t()
          }
        }

  @doc """
  Returns a new `%ClientCertificate{}` from a DER-encoded binary.
  """
  @spec from_der(binary) :: {:ok, t()} | {:error, :malformed}
  def from_der(der) when is_binary(der) do
    case X509.Certificate.from_der(der) do
      {:ok, otp_cert} ->
        {:Validity, not_before, not_after} = X509.Certificate.validity(otp_cert)
        not_before = decode_time(not_before)
        not_after = decode_time(not_after)

        fingerprints =
          for algo <- [:sha, :sha256], into: %{} do
            {algo, algo |> :crypto.hash(der) |> Base.encode16()}
          end

        %__MODULE__{
          common_name: otp_cert |> X509.Certificate.subject() |> X509.RDNSequence.get_attr("CN") |> hd(),
          fingerprints: fingerprints,
          not_valid_after: not_after,
          not_valid_before: not_before,
          otp_certificate: otp_cert,
          self_signed?: X509.Certificate.issuer(otp_cert) == X509.Certificate.subject(otp_cert),
          serial_number: otp_cert |> X509.Certificate.serial()
        }

      error ->
        error
    end
  end

  # https://www.erlang.org/doc/apps/public_key/public_key_records.html#data-types
  # utc_time() = {utcTime, "YYMMDDHHMMSSZ"}
  # general_time() = {generalTime, "YYYYMMDDHHMMSSZ"}
  defp decode_time({:utcTime, charlist}) when is_list(charlist) do
    century = (DateTime.utc_now().year / 100) |> floor() |> to_charlist()
    decode_time({:generalTime, [century | charlist]})
  end

  defp decode_time({:generalTime, charlist}) when is_list(charlist) do
    <<
      year::binary-4,
      month::binary-2,
      day::binary-2,
      hour::binary-2,
      minute::binary-2,
      second::binary-2,
      "Z"
    >> = to_string(charlist)

    date =
      Date.new!(
        String.to_integer(year),
        String.to_integer(month),
        String.to_integer(day)
      )

    time = Time.new!(String.to_integer(hour), String.to_integer(minute), String.to_integer(second))

    DateTime.new!(date, time)
  end
end
