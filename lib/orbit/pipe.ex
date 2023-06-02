defmodule Orbit.Pipe do
  @moduledoc """
  The interface for request middleware.

  Pipes are analogous to the behaviour of `Plug`. Requests enter the `Orbit.Capsule` and are passed through a series of pipes
  that sequentially process the request, and at the end of the pipeline the response is sent to the client.

  A pipe may also be simple 2-arity anonymous function that implements the same typespec as `c:call/2`.

  When you `use Orbit.Router` or `use Orbit.Controller`, the `c:call/2` callback is injected into the module,
  turning it into a Pipe.
  """

  alias Orbit.Transaction

  @doc """
  Handle a request.

  Takes in a a Transaction, potentially modifies it, and returns a Transaction. The `arg` can be any value and is
  Pipe-dependenent.
  """
  @callback call(trans :: Transaction.t(), arg :: any) :: Transaction.t()
end
