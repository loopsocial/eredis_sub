defmodule EredisSub do
  @moduledoc """
  Publishes binary messages to Redis Pub/Sub channels.
  Subscribes to channels and calls a handler function when a message is received.

  ## Usage

  ### Publish

      EredisSub.Server.publish("my_channel", "Hello, world!")

  ### Subscribe

  Implement the behaviour to be called when a message is received:

      defmodule MyModule do
        @behaviour EredisSub.Handler

        @impl EredisSub.Handler
        def handle(message, metadata) do
          # Do something...
        end
      end

  Subscribe to a channel:

      metadata_example = %{subscribed_at: DateTime.utc_now()}
      EredisSub.Server.subscribe("my_channel", {MyModule, :handle, metadata_example})
  """
  alias EredisSub.Server

  def start_link(config \\ []), do: Server.start_link(config)
  def child_spec(config), do: Server.child_spec(config)

  @doc """
  Publish a message to a channel.

  ## Examples

      iex> EredisSub.publish("my_channel", "Hello, world!")
      :ok
  """
  def publish(channel, message) do
    Server.publish(channel, message)
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
    Server.subscribe(channel, handler)
  end

  @doc """
  Unsubscribe all handlers from a channel.

  ## Examples

      iex> EredisSub.unsubscribe_all("my_channel")
      :ok
  """
  def unsubscribe_all(channel) do
    Server.unsubscribe_all(channel)
  end
end
