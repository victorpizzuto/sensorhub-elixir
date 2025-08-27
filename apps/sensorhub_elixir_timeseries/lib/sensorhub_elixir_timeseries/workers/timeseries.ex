defmodule SensorhubElixirTimeseries.Workers.Timeseries do
  @moduledoc false
  use Connection
  require Logger
  @reconnect_interval 5_000

  def start_link(_opts \\ []) do
    Connection.start_link(__MODULE__, %{db_path: nil, conn: nil},
      name: SensorhubElixirCluster.via("timeseries")
    )
  end

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      shutdown: 10_000,
      restart: :transient,
      type: :worker
    }
  end

  @impl true
  def init(state) do
    db_path =
      "#{Application.get_env(:sensorhub_elixir_timeseries, :timeseries)[:db_path]}/sensorhub?authSource=admin"

    {:connect, :init, %{state | db_path: db_path}}
  end

  @impl true
  def connect(_info, state) do
    case Mongo.start_link(url: state.db_path) do
      {:ok, conn} ->
        Logger.info("Timeseries connected.")
        Process.monitor(conn)
        {:ok, %{state | conn: conn}}

      {:error, reason} ->
        Logger.error("Can't connect to Timeseries: #{inspect(reason)}")
        {:backoff, @reconnect_interval, state}
    end
  end

  @impl true
  def terminate(_reason, %{conn: conn}) do
    Process.exit(conn, :normal)
    Process.sleep(5_000)
  end

  @impl true
  def disconnect(_info, %{conn: conn} = state) do
    Logger.info("Timeseries disconnect")
    Process.exit(conn, :normal)
    {:connect, :reconnect, %{state | conn: nil}}
  end

  @impl true
  def handle_call({:write, collection, document}, _from, state) do
    case Mongo.insert_one(state.conn, collection, document) do
      {:ok, result} ->
        {:reply, result, state}

      {:error, reason} ->
        Logger.error("Can't insert in Timeseries: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:read, collection, query}, _from, state) do
    stream = Stream.map(Mongo.find(state.conn, collection, query), & &1)
    {:reply, stream, state}
  end

  def write(collection, document) do
    GenServer.call(SensorhubElixirCluster.via("timeseries"), {:write, collection, document})
  end

  def read(collection, query) do
    GenServer.call(SensorhubElixirCluster.via("timeseries"), {:read, collection, query})
  end
end
