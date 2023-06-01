defmodule Orbit.Internal do
  @moduledoc false

  defguard is_pipe(pipe)
           when is_function(pipe, 2) or
                  is_atom(pipe) or
                  (is_tuple(pipe) and is_atom(elem(pipe, 0)) and is_atom(elem(pipe, 1)))

  defguard is_view(view)
           when is_function(view, 1) or
                  (is_tuple(view) and is_atom(elem(view, 0)) and is_atom(elem(view, 1)))
end
