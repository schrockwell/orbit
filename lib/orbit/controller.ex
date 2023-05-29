defmodule Orbit.Controller do
  alias Orbit.Gemtext
  alias Orbit.Transaction

  def render(%Transaction{} = trans, body) do
    %{trans | body: body, status: :success, meta: Gemtext.mime_type()}
  end
end
