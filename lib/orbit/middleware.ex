defmodule Orbit.Middleware do
  alias Orbit.Transaction

  @callback call(trans :: Transaction.t(), opts :: any) :: Transaction.t()
end
