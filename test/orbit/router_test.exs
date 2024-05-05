defmodule Orbit.RouterTest do
  use ExUnit.Case

  import OrbitTest

  defmodule TestController do
    use Orbit.Controller

    import Orbit.Controller

    def hello(req, _params) do
      gmi(req, "Hello, world!")
    end

    def inspect(req, _params) do
      gmi(req, inspect(req.assigns))
    end

    def edit_post(req, params) do
      gmi(req, """
      user_id: #{params["user_id"]}
      post_id: #{params["post_id"]}
      """)
    end

    def show_post(req, params) do
      gmi(req, """
      slug: #{params["slug"]}
      """)
    end
  end

  defmodule TestRouter do
    use Orbit.Router

    route("/hello", TestController, :hello)

    group do
      pipe(&Orbit.Request.assign/2, foo: :bar)
      pipe(&Orbit.Request.assign/2, bat: :baz)

      route("/test_groups_1", TestController, :inspect)

      group do
        pipe(&Orbit.Request.assign/2, ping: :pong)

        route("/test_groups_2", TestController, :inspect)
      end
    end

    route("/users/:user_id/posts/:post_id/edit", TestController, :edit_post)
    route("/posts/*slug", TestController, :show_post)
  end

  test "routes a basic request" do
    # WHEN
    resp = request("/hello", router: TestRouter)

    # THEN
    assert body(resp) == "Hello, world!"
  end

  test "returns a :not_found status when no route is found" do
    # WHEN
    resp = request("/goodbye", router: TestRouter)

    # THEN
    assert status(resp) == :not_found
    assert body(resp) == nil
  end

  test "pipes are applied in a group" do
    # WHEN
    resp = request("/test_groups_1", router: TestRouter)

    # THEN
    assert body(resp) == inspect(%{action: :inspect, foo: :bar, bat: :baz})
  end

  test "pipes are applied in nested groups" do
    # WHEN
    resp = request("/test_groups_2", router: TestRouter)

    # THEN
    assert body(resp) == inspect(%{ping: :pong, action: :inspect, foo: :bar, bat: :baz})
  end

  test "routes with parameters" do
    # WHEN
    resp = request("/users/123/posts/456/edit", router: TestRouter)

    # THEN
    assert body(resp) == """
           user_id: 123
           post_id: 456
           """
  end

  test "routes with wildcard parameters" do
    # WHEN
    resp = request("/posts/favorite/cat/pictures", router: TestRouter)

    # THEN
    assert body(resp) == """
           slug: favorite/cat/pictures
           """
  end
end
