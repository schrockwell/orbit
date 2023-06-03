defmodule Mix.Tasks.Orbit.Gen.Cert do
  @moduledoc """
  Create a self-signed certificate.

      $ mix orbit.gen.cert [hostname]

  The `hostname` is optional and defaults to "localhost".

  The following files will be created:

  - priv/cert.pem
  - priv/key.pem
  """

  @shortdoc "Create a self-signed certificate"

  use Mix.Task

  @impl Mix.Task
  def run([]) do
    run(["localhost"])
  end

  def run([hostname]) do
    Mix.shell().cmd(
      "openssl req -new -x509 -days 365 -nodes -out priv/cert.pem -keyout priv/key.pem -subj \"/CN=localhost\""
    )

    Mix.shell().info("Generated certificate for host #{hostname} in priv/{cert,key}.pem")
  end
end
