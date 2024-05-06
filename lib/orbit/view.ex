defmodule Orbit.View do
  @moduledoc """
  Render Gemtext content.

  A **template** is any 1-arity function that accepts an `assigns` map and returns a string of rendered Gemtext.

  The `~G` sigil is used to precompile EEx templates as strings when an `assigns` variable or argument is
  in scope.

  Templates can be defined as functions, or embedded from `.gmi.eex` files into view module via `embed_templates/1`.

  ## Usage

  Add these imports to the view module:

      import Orbit.Gemtext, only: [sigil_G: 2]
      import Orbit.View

  ## Example

      defmodule MyApp.MyView do
        import Orbit.Gemtext, only: [sigil_G: 2]
        import Orbit.View

        embed_templates "my_view/*"

        def list(assigns) do
          ~G\"\"\"
          <%= for item <- @items do %>
          * <%= item %>
          <% end %>
          \"\"\"
        end
      end
  """

  @doc false
  defmacro render(template) do
    quote do
      unquote(template).(%{})
    end
  end

  @doc false
  defmacro render(template, do: block) do
    quote do
      unquote(template).(%{inner_content: unquote(block)})
    end
  end

  @doc false
  defmacro render(template, assigns) do
    quote do
      unquote(template).(Enum.into(unquote(assigns), %{}))
    end
  end

  @doc """
  Renders a template.

  The `assigns` and `block` arguments are optional.

  If a block is passed, its contents are renderd and set to `@inner_content` assign of the template.

  ## Examples

      <%= render &my_template/1 %>

      <%= render &my_template/1, title: @title %>

      <%= render &my_component/1 do %>
        inner content
      <% end %>
  """
  defmacro render(view, assigns, _block = [do: block]) do
    quote do
      unquote(view).(Map.put(Enum.into(unquote(assigns), %{}), :inner_content, unquote(block)))
    end
  end

  @doc """
  Define template functions from external files.

  Every file found in the wildcard `path` is compiled as EEx and injected as a template function into the view
  module, using the file basename as the function name. For example, `index.gmi.eex` will be defined as
  `def index(assigns)`.
  """
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

      quoted = EEx.compile_file(template_path, trim: true)

      quote do
        require EEx

        @external_resource unquote(template_path)

        # Previously: EEx.function_from_file(:def, unquote(template_name), unquote(template_path), [:assigns], trim: true)
        def unquote(template_name)(var!(assigns)) do
          # No-op to shut up warnings on templates that don't access assigns
          var!(assigns)

          unquote(quoted)
        end
      end
    end)
  end
end
