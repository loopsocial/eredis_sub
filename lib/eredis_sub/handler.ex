defmodule EredisSub.Handler do
  @moduledoc """
  Behaviour for handling messages received from Redis.
  """

  @doc """
  Handles a message received from Redis.
  Receives a binary message and a metadata that can be customized upon subscription.
  Return value is ignored.
  """
  @callback handle_pubsub_message(message :: binary, metadata :: term) :: term
end
