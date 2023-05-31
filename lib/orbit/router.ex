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
    match_spec = match_spec(path)
    path_spec = path_spec(path)

    quote do
      @routes %{
        path: unquote(path),
        match_spec: unquote(match_spec),
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

      call_pipeline(trans, route.pipeline)
    else
      trans
      |> put_status(:not_found)
      |> halt()
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
