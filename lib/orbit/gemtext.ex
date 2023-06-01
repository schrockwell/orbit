defmodule Orbit.Gemtext do
  @moduledoc """
  Utility functions for processing Gemtext.
  """

  @doc """
  Returns the default MIME type for Gemtext content.
  """
  def mime_type, do: "text/gemini; charset=utf-8"

  @doc """
  Sigil for defining Gemtext content.

  The `assigns` map must be in-scope.

  A single trailing newline character `\n` will be trimmed, if it exists.

  ## Example

      def hello(assigns) do
        ~G\"\"\"
        Why hello there, <%= @name %>!
        \"\"\"
      end
  """
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
end
