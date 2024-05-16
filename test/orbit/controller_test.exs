defmodule Orbit.ControllerTest do
  use ExUnit.Case

  alias Orbit.Request

  import OrbitTest

  defmodule TestView do
    import Orbit.Gemtext, only: [sigil_G: 2]

    def show(assigns), do: ~G"show"
    def layout(assigns), do: ~G"content"
  end

  defmodule TestController do
    use Orbit.Controller

    import Orbit.Gemtext, only: [sigil_G: 2]

    view(TestView)

    pipe(&Orbit.Request.assign/2, pipe: :was_called)

    def index(req, _params) do
      gmi(req, "index")
    end

    def show(req, _params) do
      render(req)
    end

    def layout(req, _params) do
      req
      |> put_layout(&outer_layout/1)
      |> render()
    end

    defp outer_layout(assigns) do
      ~G"""
      begin outer
      <%= @inner_content %>
      end outer
      """t
    end
  end

  defmodule TestActionController do
    use Orbit.Controller

    def action(req, arg), do: gmi(req, inspect(arg))
  end

  defmodule NoViewController do
    use Orbit.Controller

    def no_view(req, _params), do: render(req)
  end

  test "action/2 calls the action on the controller" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = TestController.action(req, :index)

    # THEN
    assert req.body == "index"
  end

  test "action/2 is overridable" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = TestActionController.action(req, :test)

    # THEN
    assert req.body == ":test"
  end

  test "pipe/2 defines a pipe to run in the controller prior to the action" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = TestController.call(req, :index)

    # THEN
    assert req.assigns[:pipe] == :was_called
  end

  test "view/2 defines the view module for the controller" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = TestController.call(req, :show)

    # THEN
    assert req.body == "show"
  end

  test "gmi/2 generates a successful Gemtext response" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = Orbit.Controller.gmi(req, "index")

    # THEN
    assert status(req) == :success
    assert req.body == "index"
    assert req.meta == "text/gemini; charset=utf-8"
  end

  test "render/1 renders the view for the controller" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = TestController.call(req, :show)

    # THEN
    assert req.body == "show"
  end

  test "render/1 raises an error if no view is defined" do
    # GIVEN
    req = %Request{}

    # WHEN/THEN
    assert_raise RuntimeError, fn ->
      NoViewController.call(req, :no_view)
    end
  end

  test "put_layout/2 sets a layout for the controller" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = TestController.call(req, :layout)

    # THEN
    assert req.body == "begin outer\ncontent\nend outer"
  end

  test "get_layout/1 gets the layout for the controller" do
    # GIVEN
    req = Orbit.Controller.put_layout(%Request{}, &TestView.layout/1)

    # WHEN
    layout = Orbit.Controller.get_layout(req)

    # THEN
    assert layout == (&TestView.layout/1)
  end

  test "put_template/2 puts a Gemtext template to be rendered" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = Orbit.Controller.put_template(req, &TestView.show/1)

    # THEN
    assert req.private[:orbit_template] == (&TestView.show/1)
  end

  test "get_template/1 gets the Gemtext view to be rendered" do
    # GIVEN
    req = Orbit.Controller.put_template(%Request{}, &TestView.show/1)

    # WHEN
    view = Orbit.Controller.get_template(req)

    # THEN
    assert view == (&TestView.show/1)
  end

  test "send_file/3 can send a plain text file as a response" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = Orbit.Controller.send_file(req, "test/support/test.txt")

    # THEN
    assert req.meta == "text/plain"

    assert %File.Stream{
             path: "test/support/test.txt"
           } = req.body
  end

  test "send_file/3 can send a Gemtext file as a response" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = Orbit.Controller.send_file(req, "test/support/test.gmi")

    # THEN
    assert req.meta == "text/gemini; charset=utf-8"

    assert %File.Stream{
             path: "test/support/test.gmi"
           } = req.body
  end

  test "send_file/3 can send an image file as a response" do
    # GIVEN
    req = %Request{}

    # WHEN
    req = Orbit.Controller.send_file(req, "test/support/test.jpeg")

    # THEN
    assert req.meta == "image/jpeg"

    assert %File.Stream{
             path: "test/support/test.jpeg"
           } = req.body
  end
end
