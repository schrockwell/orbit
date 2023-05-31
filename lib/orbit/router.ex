defmodule Orbit.Router do
  alias Orbit.Transaction

  defmacro __using__(_) do
    quote do
      @before_compile Orbit.Router
      @behaviour Orbit.Middleware

      import Orbit.Router, only: [route: 2, route: 3]

      Module.register_attribute(__MODULE__, :routes, accumulate: true)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def call(%Orbit.Transaction{} = trans, _arg) do
        Orbit.Router.call(__MODULE__, trans, [])
      end

      @reversed_routes Enum.reverse(@routes)
      def __routes__, do: @reversed_routes
    end
  end

  defmacro route(path, middleware, arg \\ []) do
    match_spec = match_spec(path)
    path_spec = path_spec(path)

    quote do
      @routes %{
        path: unquote(path),
        match_spec: unquote(match_spec),
        path_spec: unquote(path_spec),
        middleware: unquote(middleware),
        arg: unquote(arg)
      }
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
    |> Enum.map(fn
      ":" <> param -> {:param, param}
      comp -> comp
    end)
  end

  defp match_spec(path) do
    path
    |> path_spec()
    |> Enum.map(fn
      {:param, _param} -> :param
      comp -> comp
    end)
  end

  def call(router, %Transaction{} = trans, _arg) do
    request_comp = components(trans.uri.path)

    route =
      Enum.find(router.__routes__(), fn route ->
        length(request_comp) == length(route.match_spec) and
          route.match_spec
          |> Enum.zip(request_comp)
          |> Enum.all?(fn
            {x, x} -> true
            {:param, _any} -> true
            _ -> false
          end)
      end)

    if route do
      path_params = path_params(trans, route)
      all_params = URI.decode_query(trans.uri.query || "", path_params, :rfc3986)

      trans = %{trans | params: all_params}

      call_route(route.middleware, trans, route.arg)
    else
      trans
      |> Transaction.put_status(:not_found)
      |> Transaction.halt()
    end
  end

  defp path_params(trans, route) do
    route.path_spec
    |> Enum.zip(components(trans.uri.path))
    |> Enum.flat_map(fn
      {{:param, key}, value} -> [{key, value}]
      _ -> []
    end)
    |> Map.new()
  end

  defp call_route(mod, trans, arg) when is_atom(mod) do
    mod.call(trans, arg)
  end

  defp call_route(fun, trans, arg) when is_function(fun, 2) do
    fun.(trans, arg)
  end
end
