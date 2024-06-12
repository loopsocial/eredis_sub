defmodule EredisSub.Server do
  @moduledoc """
  Holds internal state for `EredisSub`, which are: a connection to publish,
  a connection to subscribe and a map of subscriptions.

  Also, it converts Elixir strings to Erlang charlists used by `eredis`.

  **Do not use this module directly. Instead, use `EredisSub`.**
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

  def subscribe(channel, handler_module, metadata \\ %{}, name \\ __MODULE__) do
    GenServer.call(name, {:subscribe, channel, handler_module, metadata})
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
    command = Enum.map(["PUBLISH", channel, message], &String.to_charlist/1)

    response =
      with {:ok, number_of_subscribers} <- :eredis.q(state.pub_conn, command) do
        {:ok, String.to_integer(number_of_subscribers)}
      end

    {:reply, response, state}
  end

  def handle_call({:subscribe, channel, handler_module, metadata}, _from, state) do
    response = :eredis_sub.subscribe(state.sub_conn, [String.to_charlist(channel)])

    subscriptions =
      if response == :ok do
        Map.update(state.subscriptions, channel, [{handler_module, metadata}], fn subscriptions ->
          [{handler_module, metadata} | subscriptions]
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
    channel = to_string(channel)
    subscriptions = Map.get(state.subscriptions, channel, [])

    Enum.each(subscriptions, fn {handler_module, metadata} ->
      apply_no_link(channel, handler_module, to_string(msg), metadata)
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

  defp apply_no_link(channel, handler_module, message, metadata) do
    Task.start(fn ->
      try do
        handler_module.handle(message, metadata)
      rescue
        e ->
          error =
            "Error from channel #{channel} handler #{inspect(handler_module)}: #{inspect(e)}."

          Logger.error(error)
      end
    end)
  end
end
