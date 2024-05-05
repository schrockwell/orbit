defmodule Orbit.Pipeline do
  @moduledoc false

  alias Orbit.Request

  def call(req, pipeline) do
    Enum.reduce_while(pipeline, req, fn {pipe, arg}, req ->
      case call_pipe(pipe, req, arg) do
        %Request{halted?: true} = next_trans ->
          {:halt, next_trans}

        %Request{} = next_trans ->
          {:cont, next_trans}
      end
    end)
  end

  defp call_pipe(mod, req, arg) when is_atom(mod) do
    mod.call(req, arg)
  end

  defp call_pipe(fun, req, arg) when is_function(fun, 2) do
    fun.(req, arg)
  end
end
