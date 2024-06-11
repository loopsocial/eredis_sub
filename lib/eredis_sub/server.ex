defmodule EredisSub.Server do
  @moduledoc """
  Publishes binary messages to Redis Pub/Sub channels.
  Subscribes to channels and calls a handler function when a message is received.

  ## Usage

  ### Publish

  ```elixir
  EredisSub.Server.publish("my_channel", "Hello, world!")
  ```

  ### Subscribe

  Implement the behaviour to be called when a message is received:

  ```elixir
  defmodule MyModule do
    @behaviour EredisSub.Handler

    @impl EredisSub.Handler
    def handle(message, metadata) do
      # Do something...
    end
  end
  ```

  Subscribe to a channel:

  ```elixir
  metadata_example = %{subscribed_at: DateTime.utc_now()}
  EredisSub.Server.subscribe("my_channel", {MyModule, :handle, metadata_example})
  ```
  """

  use GenServer
  require Logger

  # Public API
  def start_link(config, name \\ __MODULE__) when is_list(config) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def publish(channel, message, name \\ __MODULE__)
      when is_binary(channel) and is_binary(message) do
    GenServer.call(name, {:publish, channel, message})
  end

  def subscribe(channel, {mod, fun, metadata}, name \\ __MODULE__) do
    GenServer.call(name, {:subscribe, channel, {mod, fun, metadata}})
  end

  def unsubscribe_all(channel, name \\ __MODULE__) do
    GenServer.call(name, {:unsubscribe_all, channel})
  end

  # Private API
  def init(config) do
    eredis_config = Enum.map(config, &convert_elixir_to_erlang_option/1)
    {:ok, pub_conn} = :eredis.start_link(eredis_config)
    {:ok, sub_conn} = :eredis_sub.start_link(eredis_config)
    :ok = :eredis_sub.controlling_process(sub_conn)

    {:ok, %{pub_conn: pub_conn, sub_conn: sub_conn, subscriptions: %{}}}
  end

  defp convert_elixir_to_erlang_option({key, value}) do
    cond do
      is_binary(value) -> {key, String.to_charlist(value)}
      is_list(value) -> {key, Enum.map(value, &convert_elixir_to_erlang_option/1)}
      true -> {key, value}
    end
  end

  def handle_call({:publish, channel, message}, _from, state) do
    args = for s <- ["PUBLISH", channel, message], do: String.to_charlist(s)
    {:ok, _count_subs} = :eredis.q(state.pub_conn, args)
    {:reply, :ok, state}
  end

  # Simplify this for brevity, keep the same functionality
  def handle_call({:subscribe, channel, mfa}, _from, state) do
    response = :eredis_sub.subscribe(state.sub_conn, [String.to_charlist(channel)])

    subscriptions =
      if response == :ok do
        Map.update(state.subscriptions, channel, [mfa], fn subscriptions ->
          [mfa | subscriptions]
        end)
      else
        state.subscriptions
      end

    {:reply, response, %{state | subscriptions: subscriptions}}
  end

  def handle_call({:unsubscribe_all, channel}, _from, state) do
    response = :eredis_sub.unsubscribe(state.sub_conn, [String.to_charlist(channel)])

    subscriptions =
      if response == :ok do
        Map.delete(state.subscriptions, channel)
      else
        state.subscriptions
      end

    {:reply, response, %{state | subscriptions: subscriptions}}
  end

  def handle_info({:message, channel, msg, _client_pid}, state) do
    subscriptions = Map.get(state.subscriptions, channel, [])

    Enum.each(subscriptions, fn {mod, fun, metadata} ->
      apply_no_link(channel, {mod, fun, [to_string(msg), metadata]})
    end)

    :eredis_sub.ack_message(state.sub_conn)
    {:noreply, state}
  end

  def handle_info({:subscribed, _channel, _client_pid}, state) do
    :eredis_sub.ack_message(state.sub_conn)
    {:noreply, state}
  end

  def handle_info({:unsubscribed, _channel, _client_pid}, state) do
    :eredis_sub.ack_message(state.sub_conn)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("[#{__MODULE__}] Unhandled message: #{inspect(msg)}.")
    {:noreply, state}
  end

  defp apply_no_link(channel, {mod, fun, args}) do
    Task.start(fn ->
      try do
        apply(mod, fun, args)
      rescue
        e ->
          msg = "Error from channel #{channel} on #{inspect(mod)}:#{inspect(fun)}: #{inspect(e)}."
          Logger.error(msg)
      end
    end)
  end
end
