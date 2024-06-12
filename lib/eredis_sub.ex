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
        def handle_pubsub_message(message, metadata) do
          # Do something...
        end
      end

  Subscribe to a channel:

      metadata_example = %{subscribed_at: DateTime.utc_now()}
      EredisSub.Server.subscribe("my_channel", MyModule, metadata_example)

  ### Add the following to your supervision tree:

      children = [
        EredisSub
      ]

  Optional configuration can be passed to `eredis` and `eredis_sub`, check [their docs](https://hexdocs.pm/eredis/readme.html#connect-a-client-start_link-1).
  """
  alias EredisSub.Server

  def start_link(config \\ []), do: Server.start_link(config)
  def child_spec(config), do: Server.child_spec(config)

  @doc """
  Publish a message to a channel.
  If successfull, returns the number of subscribers that received the message.
  It should never error, unless there is a connection problem.

  ## Examples

      iex> EredisSub.publish("my_channel", "Hello, world!")
      {:ok, 0}
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
      ...>   def handle_pubsub_message(_message, _metadata) do
      ...>     # Do something...
      ...>   end
      ...> end
      ...>
      ...> EredisSub.subscribe(channel, FooBar, metadata)
      :ok
  """
  def subscribe(channel, handler_module, metadata) do
    Server.subscribe(channel, handler_module, metadata)
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
