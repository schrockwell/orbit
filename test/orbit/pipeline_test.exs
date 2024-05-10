defmodule Orbit.PipelineTest do
  use ExUnit.Case

  alias Orbit.Pipeline

  test "call/2 halts the pipeline when a pipe returns a halted request" do
    # GIVEN
    increment_pipe = fn req, _ -> Orbit.Request.assign(req, :counter, req.assigns.counter + 1) end
    halt_pipe = fn req, _ -> Orbit.Request.halt(req) end
    req = %Orbit.Request{assigns: %{counter: 0}}

    pipeline = [
      {increment_pipe, nil},
      {increment_pipe, nil},
      {halt_pipe, nil},
      {increment_pipe, nil}
    ]

    # WHEN
    req = Pipeline.call(req, pipeline)

    # THEN
    assert req.halted?
    assert req.assigns.counter == 2
  end
end
