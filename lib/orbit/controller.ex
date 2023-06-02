defmodule Orbit.Controller do
  @moduledoc """
  Process requests and render responses.

  ## Options

  - `:view` - a view module used to render actions

  ## Usage

  The `use Orbit.Controller` macro injects the following into the module:

      @behaviour Orbit.Pipe

      def call(transaction, arg)
      def action(transaction, action) # overridable

  The `call/2` function implements the `Orbit.Pipe` callback, making the controller behave like any other pipe. The
  `arg` is the action name, as an atom. If the `:view` option has been specified, then the view is
  automatically set by calling a function on the view module with the same name as the controller action. Finally,
  `action/2` is called.

  The `action/2` function is overridable. It's an easy way to extend the controller's default behavior, or to customize
  the signature of the action functions to something other than `action_name(trans, params)`. Its default implementation is:

      def action(trans, action) do
        apply(__MODULE__, action, [trans, trans.params])
      end

  ## Layouts

  Layouts are simply views that are provided an `@inner_content` assign which contains the content of the child view
  to render within the layout. Layouts can be nested by pushing additional layouts to the Transaction.

      def outer_layout(assigns) do
        ~G\"\"\"
        begin outer
        <%= @inner_content %>
        end outer
        \"\"\"
      end

      def inner_layout(assigns) do
        ~G\"\"\"
        begin inner
        <%= @inner_content %>
        end inner
        \"\"\"
      end

      trans
      |> push_layout(&outer_layout/1)
      |> push_layout(&inner_layout/1)
      |> render()

      # =>
      \"\"\"
      begin outer
      begin inner
      ...view...
      end inner
      end outer
      \"\"\"

  ## Example

      # Router
      route "/users", MyApp.UserController, :index
      route "/users/:id", MyApp.UserController, :show

      # Controller
      defmodule MyApp.UserController do
        use Orbit.Controller, view: MyApp.UserView

        def index(trans, _params), do: ...
        def show(trans, %{"id" => id}), do: ...
      end

  """
  import Orbit.Transaction
  import Orbit.Internal, only: [is_view: 1]

  alias Orbit.Gemtext
  alias Orbit.Status
  alias Orbit.Transaction

  @orbit_view :orbit_view
  @orbit_layouts :orbit_layouts

  defmacro __using__(opts) do
    view_module = opts[:view]

    quote do
      @behaviour Orbit.Pipe

      @doc false
      @impl Orbit.Pipe
      def call(%Transaction{} = trans, action) when is_atom(action) do
        trans =
          if unquote(view_module) do
            Orbit.Controller.put_new_view(trans, fn ->
              Function.capture(unquote(view_module), action, 1)
            end)
          else
            trans
          end

        action(trans, action)
      end

      @doc false
      def action(trans, action) do
        apply(__MODULE__, action, [trans, trans.params])
      end

      defoverridable action: 2
    end
  end

  @doc """
  Puts Gemtext content as the body of a successful response.
  """
  def gmi(%Transaction{} = trans, body) do
    Status.success(trans, body, Gemtext.mime_type())
  end

  @doc """
  Puts the Gemtext view to be rendered.
  """
  def put_view(%Transaction{} = trans, view) when is_function(view, 1) do
    put_private(trans, @orbit_view, view)
  end

  @doc """
  Puts a Gemtext view to be rendered if one has not already been set.
  """
  def put_new_view(%Transaction{} = trans, fun) when is_function(fun, 0) do
    if view(trans) do
      trans
    else
      put_private(trans, @orbit_view, fun.())
    end
  end

  @doc """
  Gets the Gemtext view to be rendered.
  """
  def view(%Transaction{} = trans), do: trans.private[@orbit_view]

  @doc """
  Renders the Gemtext view and layouts as a successful response.
  """
  def render(%Transaction{} = trans) do
    trans = assign(trans, :trans, %{trans | assigns: :no_assigns})

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

  @doc """
  Adds a nested layout view.

  Layouts are rendered outer-to-inner, so the first layout pushed onto the stack will be the outermost
  layout, and the next layout pushed will be nested inside that, and so on.

  This is typically used directly in a router as a pipe, e.g.

      pipe {Orbit.Controller, :push_layout}, {MyApp.LayoutView, :main}
  """
  def push_layout(%Transaction{} = trans, layout) when is_view(layout) do
    put_private(trans, @orbit_layouts, [layout | layouts(trans)])
  end

  @doc """
  Removes the innermost layout view.
  """
  def pop_layout(%Transaction{} = trans, _arg \\ []) do
    put_private(trans, @orbit_layouts, tl(layouts(trans)))
  end

  @doc """
  Removes all layout views.
  """
  def clear_layouts(%Transaction{} = trans, _arg \\ []) do
    put_private(trans, @orbit_layouts, [])
  end

  @doc """
  Returns a list of all layouts.
  """
  def layouts(%Transaction{} = trans) do
    trans.private[@orbit_layouts] || []
  end

  defp call_view({mod, fun}, assigns) when is_atom(mod) and is_atom(fun) do
    apply(mod, fun, [assigns])
  end

  defp call_view(fun, assigns) when is_function(fun, 1) do
    fun.(assigns)
  end

  @doc """
  Sends a file as a binary stream.

  ## Options

  - `:mime_type` - the MIME type of the file; if unspecified, it is determined from the file extension
  """
  def send_file(%Transaction{} = trans, path, opts \\ []) do
    mime_type = opts[:mime_type] || MIME.from_path(path)
    Status.success(trans, File.stream!(path, [], 1024), mime_type)
  end
end
