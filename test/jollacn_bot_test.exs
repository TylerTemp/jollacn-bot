defmodule JollaCNBotTest do
  use ExUnit.Case
  doctest JollaCNBot

  test "greets the world" do
    assert JollaCNBot.hello() == :world
  end
end
