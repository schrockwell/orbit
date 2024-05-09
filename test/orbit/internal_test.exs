defmodule Orbit.InternalTest do
  use ExUnit.Case

  import Orbit.Internal

  test "is_pipe/1 returns true if the argument is a function with 2 arguments" do
    assert is_pipe(&IO.puts/2)
  end

  test "is_pipe/1 returns true if the argument is an atom" do
    assert is_pipe(MyPipeModule)
  end

  test "is_pipe/1 returns false if the argument is not a function with 2 arguments or an atom" do
    refute is_pipe(&IO.puts/1)
    refute is_pipe({Mod, :fun})
  end

  test "is_template/1 returns true if the argument is a function with 1 argument" do
    assert is_template(fn _assigns -> "neat" end)
  end

  test "is_template/1 returns false if the argument is not a function with 1 argument" do
    refute is_template(&IO.puts/2)
    refute is_template({Mod, :fun})
  end
end
