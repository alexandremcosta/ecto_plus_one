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
    opts =
      [ignored_sources: [], threshold: 3, log_level: :warning]
      |> Keyword.merge(opts)
      |> Keyword.update!(:ignored_sources, &MapSet.new(&1))

    :ets.new(__MODULE__, [:named_table, :public])
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
      [{_, query, count, pid, stacktrace}] = get_last_query(self())

      :ets.insert(__MODULE__, {"last_query", query, count, pid, stacktrace})
    end
  end

  defp increment_or_reset(current_query, opts) do
    current_pid = self()

    case get_last_query(current_pid) do
      [{_, ^current_query, _, _, _}] ->
        increment_count(current_pid)

      [] ->
        set_last_query(current_query, current_pid)

        case :ets.lookup(__MODULE__, "last_query") do
          [{"last_query", last_query, _, last_pid, _}] ->
            maybe_warn(last_query, last_pid, opts)
            reset_count(last_pid)

          _ ->
            :do_nothing
        end

      [{_, last_query, _, _, _}] ->
        maybe_warn(last_query, current_pid, opts)
        set_last_query(current_query, current_pid)
        reset_count(current_pid)

      _ ->
        :do_nothing
    end
  end

  defp maybe_warn(query, pid, opts) do
    count = get_count(pid)

    if count > opts[:threshold] do
      [{_, _, _, _, stacktrace}] = :ets.lookup(__MODULE__, get_key(pid))

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

  defp get_key(pid) do
    "last_query" <> inspect(pid)
  end

  defp get_last_query(pid),
    do: :ets.match_object(__MODULE__, {get_key(pid), :"$2", :"$3", pid, :"$4"})

  defp set_last_query(query, pid),
    do: :ets.insert(__MODULE__, {get_key(pid), query, 1, pid, get_stacktrace()})

  defp increment_count(pid), do: :ets.update_counter(__MODULE__, get_key(pid), {3, 1})
  defp reset_count(pid), do: :ets.update_counter(__MODULE__, get_key(pid), {3, 1, 1, 0})
  defp get_count(pid), do: :ets.update_counter(__MODULE__, get_key(pid), {3, 0})
end
