defmodule Orbit.GemtextTest do
  use ExUnit.Case

  import Orbit.Gemtext

  test "render/1 renders a view" do
    # GIVEN
    view = fn assigns -> ~G"hello" end

    # WHEN
    result = render(view)

    # THEN
    assert result == "hello"
  end

  test "render/2 renders a view with assigns" do
    # GIVEN
    view = fn assigns -> ~G"hello <%= @name %>" end

    # WHEN
    result = render(view, name: "world")

    # THEN
    assert result == "hello world"
  end

  test "render/2 renders a view with block" do
    # GIVEN
    view = fn assigns -> ~G"hello <%= @inner_content %>" end

    # WHEN
    assigns = %{}
    result = ~G"<%= render view do %>world<% end %>"

    # THEN
    assert result == "hello world"
  end

  test "render/2 renders a view with assigns and block" do
    # GIVEN
    view = fn assigns -> ~G"hello <%= @name %> <%= @inner_content %>" end

    # WHEN
    assigns = %{name: "world"}
    result = ~G"<%= render view, name: @name do %>inner content<% end %>"

    # THEN
    assert result == "hello world inner content"
  end

  test "embed_templates/1 embeds templates" do
    # GIVEN
    defmodule MyView do
      import Orbit.Gemtext
      embed_templates("../support/my_view/*")
    end

    # THEN
    assert MyView.my_template(%{name: "bob"}) == "my view bob"
  end
end
