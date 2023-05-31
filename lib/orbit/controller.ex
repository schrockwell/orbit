defmodule Orbit.Controller do
  import Orbit.Transaction

  alias Orbit.Gemtext
  alias Orbit.Transaction

  defmacro __using__(_) do
    quote do
      @behaviour Orbit.Middleware

      def call(%Transaction{} = trans, action) when is_atom(action) do
        apply(__MODULE__, action, [trans, trans.params])
      end
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
end
