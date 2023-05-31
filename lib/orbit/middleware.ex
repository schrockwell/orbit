defmodule Orbit.Middleware do
  alias Orbit.Transaction

  @callback call(trans :: Transaction.t(), arg :: any) :: Transaction.t()
end
