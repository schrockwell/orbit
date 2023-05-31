defmodule Orbit.Controller do
  import Orbit.Transaction
  import Orbit.View, only: [is_view: 1]

  alias Orbit.Gemtext
  alias Orbit.Transaction

  @orbit_view :orbit_view
  @orbit_layouts :orbit_layouts

  defmacro __using__(opts) do
    view_module = opts[:view]

    quote do
      @behaviour Orbit.Pipe

      def call(%Transaction{} = trans, action) when is_atom(action) do
        trans =
          Orbit.Controller.put_new_view(trans, fn ->
            Function.capture(unquote(view_module), action, 1)
          end)

        action(trans, action)
      end

      def action(trans, action) do
        apply(__MODULE__, action, [trans, trans.params])
      end

      defoverridable action: 2
    end
  end

  def success(%Transaction{} = trans, body, mime_type) do
    trans
    |> put_body(body)
    |> put_status(:success, mime_type)
  end

  def gmi(%Transaction{} = trans, body) do
    success(trans, body, Gemtext.mime_type())
  end

  def view_module(controller_module) do
    module_string = to_string(controller_module)

    view_module_string =
      if String.ends_with?(module_string, "Controller") do
        String.slice(module_string, 0..-11) <> "View"
      else
        module_string <> "View"
      end

    String.to_atom(view_module_string)
  end

  def put_view(%Transaction{} = trans, view) when is_function(view, 1) do
    put_private(trans, @orbit_view, view)
  end

  def put_new_view(%Transaction{} = trans, fun) when is_function(fun, 0) do
    if view(trans) do
      trans
    else
      put_private(trans, @orbit_view, fun.())
    end
  end

  def view(%Transaction{} = trans), do: trans.private[@orbit_view]

  def render(%Transaction{} = trans) do
    # trans = assign(trans, :trans, %{trans | assigns: :no_assigns})

    if view = view(trans) do
      render_views(trans, [view | layouts(trans)])
    else
      raise "view not set"
    end
  end

  defp render_views(trans, views) do
    body =
      Enum.reduce(views, nil, fn inner_view, inner_content ->
        inner_assigns = Map.put(trans.assigns, :inner_content, inner_content)
        call_view(inner_view, inner_assigns)
      end)

    gmi(trans, body)
  end

  defguard is_pipe(pipe)
           when is_function(pipe, 2) or
                  is_atom(pipe) or
                  (is_tuple(pipe) and is_atom(elem(pipe, 0)) and is_atom(elem(pipe, 1)))

  def push_layout(%Transaction{} = trans, layout) when is_view(layout) do
    put_private(trans, @orbit_layouts, [layout | layouts(trans)])
  end

  def pop_layout(%Transaction{} = trans, _arg \\ []) do
    put_private(trans, @orbit_layouts, tl(layouts(trans)))
  end

  def clear_layouts(%Transaction{} = trans, _arg \\ []) do
    put_private(trans, @orbit_layouts, [])
  end

  def layouts(%Transaction{} = trans) do
    trans.private[@orbit_layouts] || []
  end

  defp call_view({mod, fun}, assigns) when is_atom(mod) and is_atom(fun) do
    apply(mod, fun, [assigns])
  end

  defp call_view(fun, assigns) when is_function(fun, 1) do
    fun.(assigns)
  end
end
