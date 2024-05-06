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
  to render within the layout.

      def outer_layout(assigns) do
        ~G\"\"\"
        begin outer
        <%= @inner_content %>
        end outer
        \"\"\"
      end

      req
      |> put_layout(&outer_layout/1)
      |> render()

      # =>
      \"\"\"
      begin outer
      ...view...
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
  alias Orbit.Request

  @orbit_view :orbit_view
  @orbit_layout :orbit_layout

  defmacro __using__(_opts) do
    quote do
      @before_compile Orbit.Controller
      @behaviour Orbit.Pipe

      import Orbit.Controller

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
    req
    |> Request.put_body(body)
    |> Request.success(Gemtext.mime_type())
  end

  @doc """
  Puts the Gemtext view to be rendered.
  """
  def put_view(%Request{} = req, view) when is_function(view, 1) do
    put_private(req, @orbit_view, view)
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
      views = Enum.reject([view, get_layout(req)], &is_nil/1)
      render_nested_views(req, views)
    else
      raise "view not set"
    end
  end

  defp render_nested_views(req, views) do
    body =
      Enum.reduce(views, nil, fn inner_view, inner_content ->
        inner_assigns = Map.put(req.assigns, :inner_content, inner_content)
        call_view(inner_view, inner_assigns)
      end)

    gmi(req, body)
  end

  @doc """
  Sets the layout view.

  Layouts receive an `@inner_content` assign that contains the content of the child view to render within the layout.

  This is typically used directly in a router as a pipe, e.g.

      pipe &Orbit.Controller.put_layout/2, &MyApp.LayoutView.main/1}
  """
  def put_layout(%Request{} = req, layout) when is_view(layout) or is_nil(layout) do
    put_private(req, @orbit_layout, layout)
  end

  @doc """
  Returns a list of all layouts.
  """
  def get_layout(%Request{} = req) do
    req.private[@orbit_layout]
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
    mime_type = opts[:mime_type] || mime_type(path)

    req
    |> Request.success(mime_type)
    |> put_body(File.stream!(path, [], 1024))
  end

  defp mime_type(path) do
    if Path.extname(path) == "gmi" do
      Gemtext.mime_type()
    else
      MIME.from_path(path)
    end
  end
end
