defmodule EredisSubTest do
  @moduledoc """
  Ensure redis server is listening port 6379 before running the tests.

  For example:

      docker pull redis
      docker run --name my-redis -p 6379:6379 -d redis
  """
  use ExUnit.Case

  doctest EredisSub

  setup do
    start_supervised!(EredisSub)
    :ok
  end

  defmodule PingPong do
    def handle("ping", metadata) do
      test_pid = Map.fetch!(metadata, :test_pid)
      send(test_pid, :pong)
    end
  end

  test "subscribes and publishes" do
    channel = "my super secret channel"
    metadata = %{test_pid: self()}

    EredisSub.subscribe(channel, {PingPong, :handle, metadata})
    EredisSub.publish(channel, "ping")

    assert_receive :pong
  end
end
