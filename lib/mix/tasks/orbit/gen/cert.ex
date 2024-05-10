defmodule Mix.Tasks.Orbit.Gen.Cert do
  @moduledoc """
  Create a self-signed certificate.

      $ mix orbit.gen.cert [hostname]

  The `hostname` is optional and defaults to "localhost".

  The following files will be created:

  - `priv/tls/<hostname>.crt` - the certificate
  - `priv/tls/<hostname>.key` - the private key
  """

  @shortdoc "Create a self-signed certificate"

  use Mix.Task

  @impl Mix.Task
  def run([]) do
    run(["localhost"])
  end

  def run([hostname]) do
    Mix.Generator.create_directory(Path.join(["priv", "tls"]))

    Mix.Generator.create_file(Path.join(["priv", "tls", ".gitignore"]), "*")

    Mix.shell().cmd(
      "openssl req -new -x509 -days 365 -nodes -out 'priv/tls/#{hostname}.crt' -keyout 'priv/tls/#{hostname}.key' -subj \"/CN=#{hostname}\""
    )

    Mix.shell().info(
      "Generated self-signed certificate and private key for #{hostname} in priv/tls/#{hostname}.{crt,key}"
    )
  end
end
