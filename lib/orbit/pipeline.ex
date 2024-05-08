defmodule Orbit.Pipeline do
  @moduledoc false

  alias Orbit.Request

  def call(req, pipeline) do
    Enum.reduce_while(pipeline, req, fn {pipe, arg}, req ->
      case Orbit.Pipe.call(pipe, req, arg) do
        %Request{halted?: true} = next_trans ->
          {:halt, next_trans}

        %Request{} = next_trans ->
          {:cont, next_trans}
      end
    end)
  end
end
