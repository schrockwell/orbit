defmodule Orbit.Controller do
  import Orbit.Transaction

  alias Orbit.Gemtext
  alias Orbit.Transaction

  @orbit_view :orbit_view

  defmacro __using__(opts) do
    view_module = opts[:view]

    quote do
      @behaviour Orbit.Middleware

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
      gmi(trans, view.(trans.assigns))
    else
      raise "view not set"
    end
  end
end
