defmodule Orbit.Controller do
  @moduledoc """
  Process requests and render responses.

  ## Options

  None.

  ## Usage

  The `use Orbit.Controller` macro injects the following functions into the module:

      def call(request, arg)
      def action(request, action) # overridable

  The `call/2` function implements the `Orbit.Pipe` callback, making the controller behave like any other pipe. The
  `arg` is the action name, as an atom, and is set to the `:action` assign. Any `pipe/2` definitions in this
  controller are called first, and then `action/2` is called.


  ### Overriding `action/2`

  The `action/2` function is overridable. It's an easy way to extend the controller's default behavior, or to customize
  the signature of the action functions to something other than `action_name(req, params)`. Its default implementation is:

      def action(req, action) do
        apply(__MODULE__, action, [req, req.params])
      end

  ## Views

  A controller can render responses directly in the controller action, or defer the rendering to an external view
  module. Define the `view/1` pipe to set the view based on the controller action name.

        view MyApp.MyView

        def index(req, _params) do
          render(req) # => MyApp.MyView.index(req.assigns)
        end

  ## Layouts

  Layouts are simply views that are provided an `@inner_content` assign which contains the content of the child view
  to render within the layout. Layouts can be nested by pushing additional layouts to the Request.

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

      req
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
        use Orbit.Controller

        view MyApp.UserView

        def index(req, _params), do: ...
        def show(req, %{"id" => id}), do: ...
      end

  """
  import Orbit.Request
  import Orbit.Internal, only: [is_view: 1]

  alias Orbit.Gemtext
  alias Orbit.Status
  alias Orbit.Request

  @orbit_view :orbit_view
  @orbit_layouts :orbit_layouts

  defmacro __using__(_opts) do
    quote do
      @before_compile Orbit.Controller
      @behaviour Orbit.Pipe

      Module.register_attribute(__MODULE__, :pipeline, accumulate: true)

      @doc false
      @impl Orbit.Pipe
      def call(%Request{} = req, action) when is_atom(action) do
        req
        |> assign(action: action)
        |> Orbit.Pipeline.call(__pipeline__())
        |> action(action)
      end

      @doc false
      def action(req, action) do
        apply(__MODULE__, action, [req, req.params])
      end

      defoverridable action: 2
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __pipeline__, do: @pipeline
    end
  end

  @doc """
  Define a pipe to run in the controller prior to the action.
  """
  defmacro pipe(pipe, arg \\ []) do
    quote do
      @pipeline {unquote(pipe), unquote(arg)}
    end
  end

  @doc """
  Define the view module for rendering controller actions.

  This is a convenience wrapper that simply wraps `Orbit.Controller.put_action_view/2` as a `pipe/2` definition.
  """
  defmacro view(view_module) do
    quote do
      pipe(&Orbit.Controller.put_action_view/2, unquote(view_module))
    end
  end

  @doc """
  Sets the response view based on the controller action name.

  The view rendered is `[view_module].[action]/2`.
  """
  def put_action_view(req, view_module) do
    put_view(req, Function.capture(view_module, req.assigns.action, 1))
  end

  @doc """
  Puts Gemtext content as the body of a successful response.
  """
  def gmi(%Request{} = req, body) do
    Status.success(req, body, Gemtext.mime_type())
  end

  @doc """
  Puts the Gemtext view to be rendered.
  """
  def put_view(%Request{} = req, view) when is_function(view, 1) do
    put_private(req, @orbit_view, view)
  end

  @doc """
  Puts a Gemtext view to be rendered if one has not already been set.
  """
  def put_new_view(%Request{} = req, fun) when is_function(fun, 0) do
    if get_view(req) do
      req
    else
      put_private(req, @orbit_view, fun.())
    end
  end

  @doc """
  Gets the Gemtext view to be rendered.
  """
  def get_view(%Request{} = req), do: req.private[@orbit_view]

  @doc """
  Renders the Gemtext view and layouts as a successful response.
  """
  def render(%Request{} = req) do
    if view = get_view(req) do
      render_views(req, [view | layouts(req)])
    else
      raise "view not set"
    end
  end

  defp render_views(req, views) do
    body =
      Enum.reduce(views, nil, fn inner_view, inner_content ->
        inner_assigns = Map.put(req.assigns, :inner_content, inner_content)
        call_view(inner_view, inner_assigns)
      end)

    gmi(req, body)
  end

  @doc """
  Adds a nested layout view.

  Layouts are rendered outer-to-inner, so the first layout pushed onto the stack will be the outermost
  layout, and the next layout pushed will be nested inside that, and so on.

  This is typically used directly in a router as a pipe, e.g.

      pipe {Orbit.Controller, :push_layout}, {MyApp.LayoutView, :main}
  """
  def push_layout(%Request{} = req, layout) when is_view(layout) do
    put_private(req, @orbit_layouts, [layout | layouts(req)])
  end

  @doc """
  Removes the innermost layout view.
  """
  def pop_layout(%Request{} = req, _arg \\ []) do
    put_private(req, @orbit_layouts, tl(layouts(req)))
  end

  @doc """
  Removes all layout views.
  """
  def clear_layouts(%Request{} = req, _arg \\ []) do
    put_private(req, @orbit_layouts, [])
  end

  @doc """
  Returns a list of all layouts.
  """
  def layouts(%Request{} = req) do
    req.private[@orbit_layouts] || []
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
  def send_file(%Request{} = req, path, opts \\ []) do
    mime_type = opts[:mime_type] || MIME.from_path(path)
    Status.success(req, File.stream!(path, [], 1024), mime_type)
  end
end
