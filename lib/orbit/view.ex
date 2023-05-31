defmodule Orbit.View do
  defmacro sigil_G({:<<>>, _, [binary]}, _modifier) do
    compiled = EEx.compile_string(binary)

    quote do
      {result, _binding} = Code.eval_quoted(unquote(compiled), assigns: var!(assigns))
      result
    end
  end
end
