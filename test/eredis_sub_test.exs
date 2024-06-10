defmodule EredisSubTest do
  use ExUnit.Case
  doctest EredisSub

  test "greets the world" do
    assert EredisSub.hello() == :world
  end
end
