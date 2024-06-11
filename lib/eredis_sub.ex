defmodule EredisSub do
  @moduledoc """
  Documentation for `EredisSub`.
  """

  def start_link(config \\ []) do
    EredisSub.Server.start_link(config)
  end

  def child_spec(config) do
    EredisSub.Server.child_spec(config)
  end

  @doc """
  Publish a message to a channel.

  ## Examples

      iex> EredisSub.publish("my_channel", "Hello, world!")
      :ok
  """
  def publish(channel, message) do
    EredisSub.Server.publish(channel, message)
  end

  @doc """
  Subscribe to a channel.

  ## Examples

      iex> channel = "my channel"
      ...> metadata = %{}
      ...>
      ...> defmodule FooBar do
      ...>   def handle("foo", _metadata) do
      ...>     # Do something...
      ...>   end
      ...> end
      ...>
      ...> EredisSub.subscribe(channel, {FooBar, :handle, metadata})
      :ok
  """
  def subscribe(channel, handler) do
    EredisSub.Server.subscribe(channel, handler)
  end

  @doc """
  Unsubscribe all handlers from a channel.

  ## Examples

      iex> EredisSub.unsubscribe_all("my_channel")
      :ok
  """
  def unsubscribe_all(channel) do
    EredisSub.Server.unsubscribe_all(channel)
  end
end
