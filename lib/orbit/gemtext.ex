defmodule Orbit.Gemtext do
  @moduledoc """
  Render Gemtext content.

  [PrEEx.Engine](https://hexdocs.pm/preex/) is used to render Gemtext templates, instead of the default
  `EEx.SmartEngine`, which provides a more developer-friendly approach to writing preformatted, plain-text templates.

  ## Concepts

  A **template** is any 1-arity function that accepts an `assigns` map and returns a string of rendered Gemtext.

  A **view** is a module containing template functions.

  Templates can be defined directly as functions, or embedded from `.gmi.eex` files into view module via `embed_templates/1`.

  Templates can be precompiled with `sigil_G/2`, as long as the `assigns` variable is in-scope.

  ## Usage

  Add the imports to the view module:

      import Orbit.Gemtext

  ## Examples

  ### Importing templates from a directory

      defmodule MyAppCapsule.PostGmi do
        import Orbit.Gemtext

        embed_templates "post_gmi/*"
      end

  ### Writing templates directly

      defmodule MyAppCapsule.PostGmi do
        import Orbit.Gemtext

        def list(assigns) do
          ~G\"\"\"
          <%= for item <- @items do %>
          * <%= item %>
          <% end %>
          \"\"\"t
        end
      end

  """

  @doc """
  Sigil for defining Gemtext content.

  The `assigns` map must be in-scope.

  ## Modifiers

  - `t` - Trim trailing newline

  [Multi-line strings](https://hexdocs.pm/elixir/syntax-reference.html#strings) always end with a newline, which may
  be undesired. Append the `t` modifier to the `~G` sigil to trim the trailing newline.

  ## Example

      def hello(assigns) do
        ~G\"\"\"
        Why hello there, <%= @name %>!
        \"\"\"t
      end

      hello(%{name: "capsuleer"})
      # => "Why hello there, capsuleer!"
  """
  defmacro sigil_G({:<<>>, _, [binary]} = _string, modifiers) do
    compiled =
      binary
      |> trim_trailing_newline(modifiers)
      |> EEx.compile_string(engine: PrEEx.Engine)

    quote do
      {result, _binding} = Code.eval_quoted(unquote(compiled), assigns: var!(assigns))
      result
    end
  end

  defp trim_trailing_newline(string, modifiers) do
    if ?t in modifiers do
      String.replace_suffix(string, "\n", "")
    else
      string
    end
  end

  @doc """
  Renders a template.

  The `assigns` and `block` arguments are optional.

  If a block is passed, its contents set to `@inner_content` assign of the template.

  ## Examples

      <%= render &my_template/1 %>

      <%= render &my_template/1, title: @title %>

      <%= render &my_template/1 do %>
        inner content here
      <% end %>
  """
  defmacro render(template, assigns \\ [], block \\ [])

  defmacro render(template, [do: block], []) do
    quote do
      unquote(template).(%{inner_content: unquote(block)})
    end
  end

  defmacro render(template, assigns, []) do
    quote do
      unquote(template).(Enum.into(unquote(assigns), %{}))
    end
  end

  defmacro render(template, assigns, do: block) do
    quote do
      unquote(template).(Enum.into(unquote(assigns), %{inner_content: unquote(block)}))
    end
  end

  @doc """
  Precompile template functions from external files.

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

      quoted = EEx.compile_file(template_path, engine: PrEEx.Engine)

      quote do
        require EEx

        @external_resource unquote(template_path)

        # Previously: EEx.function_from_file(:def, unquote(template_name), unquote(template_path), [:assigns], trim: true)
        def unquote(template_name)(var!(assigns)) do
          # No-op to shut up warnings on templates that don't access assigns
          _ = var!(assigns)

          unquote(quoted)
        end
      end
    end)
  end
end
