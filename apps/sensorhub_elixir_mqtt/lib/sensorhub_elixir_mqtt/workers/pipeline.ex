defmodule SensorhubElixirMqtt.Workers.Pipeline do
  use Broadway

  alias Broadway.Message
  alias SensorhubElixirTimeseries.Workers.Timeseries
  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    Broadway.start_link(__MODULE__,
      name: SensorhubElixirCluster.via(name),
      producer: [
        module: {
          BroadwayRabbitMQ.Producer,
          queue: "sensor_data",
          connection: Application.get_env(:sensorhub_elixir_mqtt, :mqtt),
          declare: [durable: true],
          metadata: [:routing_key]
        },
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 4]
      ]
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
  def handle_message(_processor, %Message{data: payload, metadata: meta} = message, _context) do
    with {:ok, decoded} <- Jason.decode(payload),
         {:ok, sensor_id} <- extract_sensor_id(meta),
         :ok <- store(sensor_id, decoded) do
      message
    else
      error ->
        Logger.error("Failed to process message: #{inspect(error)}")
        Message.failed(message, error)
    end
  end

  defp extract_sensor_id(%{routing_key: topic}) do
    case String.split(topic, ".") do
      [_environment, sensor_id, _action] -> {:ok, sensor_id}
      _ -> {:error, :invalid_topic}
    end
  end

  defp store(sensor_id, data) do
    {:ok, time, _} = DateTime.from_iso8601(data["time"])

    data =
      data
      |> Map.put("uuid", sensor_id)
      |> Map.put("time", time)
      |> Map.put_new("inserted_at", DateTime.utc_now())

    with {:ok, _} <- Timeseries.write("telemetry", data) do
      :ok
    else
      error -> error
    end
  end

  @impl true
  def process_name({:via, Horde.Registry, {_reg, base}}, role),
    do: {:via, Horde.Registry, {SensorhubElixirCluster.HordeRegistry, :"#{base}_#{role}"}}
end
