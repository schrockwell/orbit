defmodule Orbit.GemtextTest do
  use ExUnit.Case

  import Orbit.Gemtext

  test "render/1 renders a template" do
    # GIVEN
    template = fn assigns -> ~G"hello" end

    # WHEN
    result = render(template)

    # THEN
    assert result == "hello"
  end

  test "render/2 renders a template with assigns" do
    # GIVEN
    template = fn assigns -> ~G"hello <%= @name %>" end

    # WHEN
    result = render(template, name: "world")

    # THEN
    assert result == "hello world"
  end

  test "render/2 renders a template with block" do
    # GIVEN
    template = fn assigns -> ~G"hello <%= @inner_content %>" end

    # WHEN
    assigns = %{}
    result = ~G"<%= render template do %>world<% end %>"

    # THEN
    assert result == "hello world"
  end

  test "render/2 renders a template with assigns and block" do
    # GIVEN
    template = fn assigns -> ~G"hello <%= @name %> <%= @inner_content %>" end

    # WHEN
    assigns = %{name: "world"}
    result = ~G"<%= render template, name: @name do %>inner content<% end %>"

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

  test "sigil_G t modifier trims the trailing newline" do
    # GIVEN
    template1 = fn assigns ->
      ~G"""
      hello
      """
    end

    template2 = fn assigns ->
      ~G"""
      hello
      """t
    end

    template3 = fn assigns ->
      ~G"""
      hello

      """t
    end

    # WHEN
    result1 = render(template1)
    result2 = render(template2)
    result3 = render(template3)

    # THEN
    assert result1 == "hello\n"
    assert result2 == "hello"
    assert result3 == "hello\n"
  end
end
