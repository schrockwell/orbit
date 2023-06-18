defmodule Mix.Tasks.Orbit.Gen.Cert do
  @moduledoc """
  Create a self-signed certificate.

      $ mix orbit.gen.cert [hostname]

  The `hostname` is optional and defaults to "localhost".

  The following files will be created:

  - `priv/tls/<hostname>.pem` - the certificate
  - `priv/tls/<hostname>-key.pem` - the private key
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
      "openssl req -new -x509 -days 365 -nodes -out 'priv/tls/#{hostname}.pem' -keyout 'priv/tls/#{hostname}-key.pem' -subj \"/CN=#{hostname}\""
    )

    Mix.shell().info("Generated certificate for #{hostname} in priv/tls/{#{hostname},#{hostname}-key}.pem")
  end
end
