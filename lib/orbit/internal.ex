defmodule Orbit.Internal do
  @moduledoc false

  defguard is_pipe(pipe) when is_function(pipe, 2) or is_atom(pipe)
  defguard is_template(template) when is_function(template, 1)
end
