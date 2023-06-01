defmodule Orbit.View do
  defmacro __using__(_) do
    quote do
      import Orbit.Gemtext, only: [sigil_G: 2]
      import Orbit.View

      require EEx
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

  defmacro embed_templates(path) when is_binary(path) do
    absolute_path = Path.join(Path.dirname(__CALLER__.file), path)

    absolute_path
    |> Path.wildcard()
    |> Enum.map(fn template_path ->
      template_name =
        template_path
        |> Path.basename()
        |> String.split(".")
        |> hd()
        |> String.to_atom()

      quote do
        EEx.function_from_file(:def, unquote(template_name), unquote(template_path), [:assigns])
      end
    end)
  end
end
