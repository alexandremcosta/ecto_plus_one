# EctoPlusOne

Logs N+1 queries via telemetry events.

Use on `:dev` or `:test` environment to warn performance issues. On test environment,
you should run tests synchronously, since it uses a global counter for all tests.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_plus_one` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_plus_one, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ecto_plus_one>.


# Usage

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    ecto_telemetry_event = [:my_app, :repo, :query]

    if Application.get_env(:my_app, :env) in [:dev, :test] do
      EctoPlusOne.start(ecto_telemetry_event)
    end

    # ...
  end
end
"""

