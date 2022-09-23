defmodule EctoPlusOne do
  @moduledoc """
  Logs N+1 queries via telemetry events.

  Use on `:dev` or `:test` environment to warn performance issues. On test environment,
  you should run tests synchronously, since it uses a global counter for all tests.

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
  require Logger

  @doc """
  Starts storage to count repeated queries and watches telemetry events.

  ## Options

    * `:ignored_sources` - list of database tables to ignore, defaults to []
    * `:threshold` - lower bound of repeated queries to trigger log, defaults to 3
    * `:log_level` - defaults to `:warning`

  ## Examples

      EctoPlusOne.start([:my_app, :repo, :query])

      from(p in Post, where: p.id < 10)
      |> MyApp.Repo.all()
      |> Enum.map(fn %{creator_id: creator_id} ->
        from(u in User, where: u.id = ^creator_id)
        |> MyApp.Repo.one()
      end)

      # And you should see the log output here...
  """
  @spec start([atom()], Keyword.t()) :: :ok | {:error, :already_exists}
  def start(telemetry_event, opts \\ []) do
    default_opts = [ignored_sources: [], threshold: 3, log_level: :warning]
    opts = Keyword.merge(default_opts, opts)

    opts =
      opts
      |> Keyword.put(:counter, :counters.new(1, []))
      |> Keyword.update!(:ignored_sources, &MapSet.new(&1))

    :ets.new(__MODULE__, [:named_table, :public])
    :ets.insert(__MODULE__, {"counter", opts[:counter]})
    :telemetry.attach("ecto-plus-one", telemetry_event, &__MODULE__.handle/4, opts)
  end

  @doc """
  Telemetry handler function.
  This function is called by telemetry when the target event is executed.
  It shouldn't be called directly from an app.
  """
  @spec handle(
          :telemetry.event_name(),
          :telemetry.event_measurements(),
          :telemetry.event_metadata(),
          :telemetry.handler_config()
        ) :: true | nil
  def handle(_event_name, _measurements, metadata, opts) do
    query = metadata[:query]
    source = metadata[:source]

    if source not in opts[:ignored_sources] and String.starts_with?(query, "SELECT") do
      increment_or_reset(query, opts)
      :ets.insert(__MODULE__, {"last_pid", self()})
      :ets.insert(__MODULE__, {"last_query", query})
      :ets.insert(__MODULE__, {"last_stacktrace", get_stacktrace()})
    end
  end

  defp increment_or_reset(current_query, opts) do
    current_pid = self()

    case {:ets.lookup(__MODULE__, "last_query"), :ets.lookup(__MODULE__, "last_pid")} do
      {[{"last_query", ^current_query}], [{"last_pid", ^current_pid}]} ->
        :counters.add(opts[:counter], 1, 1)

      {[{"last_query", last_query}], _} ->
        maybe_warn(last_query, opts)
        :counters.put(opts[:counter], 1, 0)

      {_, _} ->
        :do_nothing
    end
  end

  defp maybe_warn(query, opts) do
    count = :counters.get(opts[:counter], 1)

    if count > opts[:threshold] do
      stacktrace = :ets.lookup(__MODULE__, "last_stacktrace")

      Logger.log(opts[:log_level], """
      N+1 Query Detected!

      Query executed #{count} times:
      #{query}

      Stacktrace:
      #{inspect(stacktrace, limit: :infinity, pretty: true)}
      """)
    end
  end

  @ignored_stacktraces ~w(Elixir.EctoPlusOne Elixir.Process Elixir.Ecto Elixir.DBConnection Elixir.Enum telemetry)
  defp get_stacktrace() do
    {:current_stacktrace, current_stacktrace} = Process.info(self(), :current_stacktrace)

    Enum.reject(current_stacktrace, fn {module, _, _, _} ->
      module_str = Atom.to_string(module)
      Enum.any?(@ignored_stacktraces, &String.starts_with?(module_str, &1))
    end)
  end
end
