![Elixir CI](https://github.com/loopsocial/eredis_sub/actions/workflows/elixir.yml/badge.svg)

# EredisSub

Wraps `eredis` and `eredis_sub` functionallity for Elixir usage.

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
EredisSub.subscribe("my_channel", {MyModule, :handle, metadata_example})
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
