defmodule Orbit.Router do
  import Orbit.Transaction

  alias Orbit.Transaction

  defmacro __using__(_) do
    quote do
      @before_compile Orbit.Router
      @behaviour Orbit.Pipe
      @pipeline [[]]

      import Orbit.Router, only: [route: 2, route: 3, group: 1, pipe: 1, pipe: 2]

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

  defmacro route(path, pipe, arg \\ []) do
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

  defmacro group(do: block) do
    quote do
      @pipeline [[] | @pipeline]

      unquote(block)

      @pipeline tl(@pipeline)
    end
  end

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

  def call(router, %Transaction{} = trans, _arg) do
    request_comps = components(trans.uri.path)

    route =
      Enum.find(router.__routes__(), fn route ->
        request_comps
        |> split_request_path(route.path_spec)
        |> path_matches?(route.path_spec)
      end)

    if route do
      path_params = path_params(request_comps, route.path_spec)
      all_params = URI.decode_query(trans.uri.query || "", path_params, :rfc3986)
      trans = %{trans | params: all_params}

      call_pipeline(trans, route.pipeline)
    else
      trans
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

  defp call_pipe(mod, trans, arg) when is_atom(mod) do
    mod.call(trans, arg)
  end

  defp call_pipe({mod, fun}, trans, arg) when is_atom(mod) and is_atom(fun) do
    apply(mod, fun, [trans, arg])
  end

  defp call_pipe(fun, trans, arg) when is_function(fun, 2) do
    fun.(trans, arg)
  end

  defp call_pipeline(trans, pipeline) do
    Enum.reduce_while(pipeline, trans, fn {pipe, arg}, trans ->
      case call_pipe(pipe, trans, arg) do
        %Transaction{halted?: true} = next_trans ->
          {:halt, next_trans}

        %Transaction{} = next_trans ->
          {:cont, next_trans}
      end
    end)
  end
end
