# THIS PACKAGE IS UNMAINTAINED, AND RETIRED FROM HEX.PM

![Elixir CI](https://github.com/loopsocial/eredis_sub/actions/workflows/elixir.yml/badge.svg)
![Hex.pm Version](https://img.shields.io/hexpm/v/eredis_sub?color=blue)

# EredisSub

Wraps [`eredis`](https://hexdocs.pm/eredis/) and [`eredis_sub`](https://github.com/Nordix/eredis/blob/master/src/eredis_sub.erl) functionallity for Elixir usage.

- Publishes binary messages to Redis Pub/Sub channels.
- Subscribes to channels and calls a handler function when a message is received.

## Usage

### Publish

```elixir
EredisSub.publish("my_channel", "Hello, world!")
```

### Subscribe

Implement the behaviour to be called when a message is received:

```elixir
defmodule MyModule do
  @behaviour EredisSub.Handler

  @impl EredisSub.Handler
  def handle_pubsub_message(message, metadata) do
    # Do something...
  end
end
```

Subscribe to a channel:

```elixir
metadata_example = %{subscribed_at: DateTime.utc_now()}
EredisSub.subscribe("my_channel", MyModule, metadata_example)
```

## Installation

```elixir
def deps do
  [
    {:eredis_sub, "~> 0.1.0"}
  ]
end
```

Add the following to your supervision tree on `application.ex`:

```elixir
children = [
  EredisSub
]
```

Optional configuration can be passed to `eredis` and `eredis_sub`, check [their docs](https://hexdocs.pm/eredis/readme.html#connect-a-client-start_link-1):

```elixir
children = [
  {EredisSub, [database: 2, username: "foo", password: "bar"]}
]
```

## Motivations

### Why not use `Phoenix.PubSub`?

Because multiple applications in many programming languages can use Redis Pub/Sub,
but they don't serialize their binary messages according to `Phoenix` schema.

### Why not use `eredis` directly?

That's also a great option. With `EredisSub` Elixir abstraction we intend to hide
Erlang specific knowledge, for example Erlang strings and OTP processes. We changed
the API to let clients subscribe a handler function to a Pub/Sub channel, similar
to how [`:telemetry`](https://hexdocs.pm/telemetry/readme.html) attaches handlers.

We sacrificed flexibility on client process architecture, for a simpler mental model.
If you need to handle message passing or a pool of processes, for example to handle
heavier loads, use [`eredis`](https://hexdocs.pm/eredis/) directly.

### Why not use [`Redix`](https://hexdocs.pm/redix/Redix.html)?

Because it doesn't support Redis Cluster. Since our project already depends on
`eredis_cluster` (thus also depends on `eredis`), we wanted to stick with it.
