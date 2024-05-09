defmodule Orbit.StaticTest do
  use ExUnit.Case

  test "call/2 returns a file if it exists" do
    # GIVEN
    req = %Orbit.Request{params: %{"path" => "index.gmi"}, uri: %URI{path: "/static/index.gmi"}}
    opts = [from: :orbit]

    # WHEN
    req = Orbit.Static.call(req, opts)

    # THEN
    assert req.status == :success
    assert %File.Stream{path: local_path} = req.body
    assert String.ends_with?(local_path, "/priv/static/index.gmi")
  end

  test "call/2 returns a :not_found status if the file does not exist" do
    # GIVEN
    req = %Orbit.Request{params: %{"path" => "nonexistent.txt"}, uri: %URI{path: "/static/nonexistent.txt"}}
    opts = [from: :orbit]

    # WHEN
    req = Orbit.Static.call(req, opts)

    # THEN
    assert req.status == :not_found
    assert req.body == []
  end

  test "call/2 returns index.gmi for '/dir/' if it exists" do
    # GIVEN
    req = %Orbit.Request{params: %{"path" => "dir/"}, uri: %URI{path: "/static/dir/"}}
    opts = [from: :orbit]

    # WHEN
    req = Orbit.Static.call(req, opts)

    # THEN
    assert req.status == :success
    assert %File.Stream{path: local_path} = req.body
    assert String.ends_with?(local_path, "/priv/static/dir/index.gmi")
  end

  test "call/2 returns index.gmi for '/dir' if it exists" do
    # GIVEN
    req = %Orbit.Request{params: %{"path" => "dir"}, uri: %URI{path: "/static/dir"}}
    opts = [from: :orbit]

    # WHEN
    req = Orbit.Static.call(req, opts)

    # THEN
    assert req.status == :success
    assert %File.Stream{path: local_path} = req.body
    assert String.ends_with?(local_path, "/priv/static/dir/index.gmi")
  end
end
