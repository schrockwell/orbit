defmodule Orbit.Router do
  @moduledoc """
  Sort out incoming requests.

  ## Usage

  `use Orbit.Router` injects the following into the module:

      import Orbit.Router

      def call(req, arg)

  ## Example

      defmodule MyApp.Router do
        use Orbit.Router

        pipe &Orbit.Controller.push_layout/2, {MyApp.LayoutView, :main}
        pipe MyApp.SetCurrentUser

        route "/static/*path", Orbit.Static, from: "priv/static"

        group do
          pipe MyApp.RequireCurrentUser

          route "/messages", MyApp.MessageController, :index
          route "/messages/:id", MyApp.MessageController, :show
        end
      end

  """
  import Orbit.Request

  alias Orbit.Pipeline
  alias Orbit.Request

  defmacro __using__(_) do
    quote do
      @before_compile Orbit.Router
      @behaviour Orbit.Pipe
      @pipeline [[]]

      import Orbit.Router

      Module.register_attribute(__MODULE__, :routes, accumulate: true)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def call(%Orbit.Request{} = req, _arg) do
        Orbit.Router.__call__(__MODULE__, req, [])
      end

      @reversed_routes Enum.reverse(@routes)
      def __routes__, do: @reversed_routes
    end
  end

  @doc """
  Defines a route that sends a request to a designated pipe.

  Path segments can contain parameters which are merged into the `params` field of the request. A wildcard parameter
  can exist at the very end of a path match.

      route "/users/:id/edit", UserController, :edit # => %{"id" => "123"}
      route "/posts/*slug", PostController, :show # => %{"slug" => "favorite/cat/pictures"}

  The `pipe` argument may be either:

  - a module that implements the `Orbit.Pipe` behaviour
  - a 2-arity function capture that accepts the request and an arugment

  If no route matches the request path, the router responds with a `:not_found` status.
  """
  defmacro route(path, pipe, arg \\ nil) do
    path_spec = path_spec(path)

    quote do
      @routes %{
        path: unquote(path),
        path_spec: unquote(path_spec),
        pipeline:
          [
            {unquote(pipe), unquote(arg)}
            | @pipeline
          ]
          |> List.flatten()
          |> Enum.reverse(),
        arg: unquote(arg)
      }
    end
  end

  @doc """
  Defines a group of routes with a shared pipeline.

  Groups have their own pipelines that append any existing pipes from parent groups, or from the router. Groups
  can be nested.

  ## Example

      pipe SetCurrentUser

      route "/", HomeController, :show
      # ...more routes for all users...

      group do
        pipe RequireUser

        route "/profile", ProfileController, :show
        # ...more routes for authenticated users...

        group do
          pipe RequireAdminRole

          route "/admin/users", UserController, :index
          # ...more routes for authenticated admin users...
        end
      end
  """
  defmacro group(do: block) do
    quote do
      @pipeline [[] | @pipeline]

      unquote(block)

      @pipeline tl(@pipeline)
    end
  end

  @doc """
  Defines a pipe through which requests are processed.

  The `pipe` argument may be either:

  - a module that implements `Orbit.Pipe`
  - a function capture of a 2-arity function
  - a `{module, function}` tuple that points to a 2-arity public function in a module

  If the pipe halts the request, the router does not process any further pipes or route matches.

  Pipelines (sets of pipes) may be constructed by defining pipes inside `group/1` blocks.
  """
  defmacro pipe(pipe, arg \\ []) do
    quote do
      @pipeline [
        [{unquote(pipe), unquote(arg)} | hd(@pipeline)]
        | tl(@pipeline)
      ]
    end
  end

  defp components(path) do
    path
    |> String.split("/")
    |> Enum.reject(&(&1 == ""))
  end

  defp path_spec(path) do
    path
    |> components()
    |> Enum.reduce_while([], fn
      ":" <> param, list -> {:cont, [{:param, param} | list]}
      "*" <> param, list -> {:halt, [{:wildcard_param, param} | list]}
      comp, list -> {:cont, [comp | list]}
    end)
    |> Enum.reverse()
  end

  @doc false
  def __call__(router, %Request{} = req, _arg) do
    request_comps = components(req.uri.path)

    route =
      Enum.find(router.__routes__(), fn route ->
        request_comps
        |> split_request_path(route.path_spec)
        |> path_matches?(route.path_spec)
      end)

    if route do
      path_params = path_params(request_comps, route.path_spec)
      all_params = URI.decode_query(req.uri.query || "", path_params, :rfc3986)
      req = %{req | params: all_params}

      Pipeline.call(req, route.pipeline)
    else
      req
      |> put_status(:not_found)
      |> halt()
    end
  end

  defp split_request_path(request_components, path_spec) do
    if match?({:wildcard_param, _}, List.last(path_spec)) do
      {path_comps, wildcard_comps} = Enum.split(request_components, length(path_spec) - 1)

      path_comps ++ [Enum.join(wildcard_comps, "/")]
    else
      request_components
    end
  end

  defp path_matches?(path_comps, path_spec) do
    if length(path_comps) == length(path_spec) do
      path_spec
      |> Enum.zip(path_comps)
      |> Enum.all?(fn
        {{:param, _}, _any} -> true
        {{:wildcard_param, _}, _any} -> true
        {string, string} when is_binary(string) -> true
        _ -> false
      end)
    else
      false
    end
  end

  defp path_params(path_comps, path_spec) do
    components = split_request_path(path_comps, path_spec)

    path_spec
    |> Enum.zip(components)
    |> Enum.flat_map(fn
      {{:param, key}, value} -> [{key, value}]
      {{:wildcard_param, key}, value} -> [{key, value}]
      _ -> []
    end)
    |> Map.new()
  end
end
