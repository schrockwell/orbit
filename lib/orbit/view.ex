defmodule Orbit.View do
  defguard is_view(view)
           when is_function(view, 1) or
                  (is_tuple(view) and is_atom(elem(view, 0)) and is_atom(elem(view, 1)))

  defmacro sigil_G({:<<>>, _, [binary]}, _modifier) do
    compiled =
      binary
      |> trim_trailing_newline()
      |> EEx.compile_string()

    quote do
      {result, _binding} = Code.eval_quoted(unquote(compiled), assigns: var!(assigns))
      result
    end
  end

  # Elixir herdocs (""") have a trailing "\n" which has will result in an undesired newline, so let's remove it
  defp trim_trailing_newline(string) do
    if String.ends_with?(string, "\n") do
      String.slice(string, 0..-2)
    else
      string
    end
  end

  defmacro render(view) do
    quote do
      unquote(view).(%{})
    end
  end

  defmacro render(view, do: block) do
    quote do
      unquote(view).(%{inner_content: unquote(block)})
    end
  end

  defmacro render(view, assigns) do
    quote do
      unquote(view).(Enum.into(unquote(assigns), %{}))
    end
  end

  defmacro render(view, assigns, do: block) do
    quote do
      unquote(view).(Map.put(Enum.into(unquote(assigns), %{}), :inner_content, unquote(block)))
    end
  end
end
