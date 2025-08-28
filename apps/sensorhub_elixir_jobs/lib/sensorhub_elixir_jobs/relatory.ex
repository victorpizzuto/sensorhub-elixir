defmodule SensorhubElixirJobs.Relatory do
  use Oban.Worker, queue: :default
  require Logger

  alias Elixlsx.{Workbook, Sheet}
  alias SensorhubElixirTimeseries.Workers.Timeseries
  alias SensorhubElixir.Sensor
  alias ExAws.S3

  @bucket "sensorhub"

  @impl Oban.Worker
  def perform(_job) do
    "telemetry"
    |> get_data()
    |> process_data()
    |> store_data()

    :ok
  end

  defp get_data(collection) do
    ten_minutes_ago = DateTime.utc_now() |> DateTime.add(-600, :second)
    query = %{"time" => %{"$gte" => ten_minutes_ago}}

    Timeseries.read(collection, query)
  end

  defp process_data(stream) do
    sensor_lookup =
      Sensor.list_sensors()
      |> Map.new(fn %{uuid: uuid, name: name} -> {uuid, name} end)

    headers = ["Sensor Name", "UUID", "Time", "Speed", "Temperature"]

    rows =
      Enum.map(stream, fn %{
                            "uuid" => uuid,
                            "time" => time,
                            "speed" => speed,
                            "temperature" => temperature
                          } ->
        [
          Map.get(sensor_lookup, uuid),
          uuid,
          format_time(time),
          speed,
          temperature
        ]
      end)

    %Sheet{name: "Last 10 Minutes", rows: [headers | rows]}
  end

  defp store_data(sheet) do
    with :ok <- maybe_create_bucket(@bucket),
         file_path <- write_excel_file(sheet),
         {:ok, file_binary} <- File.read(file_path) do
      S3.put_object(@bucket, Path.basename(file_path), file_binary)
      |> ExAws.request!()
    else
      {:error, reason} ->
        Logger.error("Erro ao salvar ou fazer upload do arquivo: #{inspect(reason)}")

      _ ->
        Logger.error("Erro inesperado ao armazenar dados.")
    end
  end

  defp write_excel_file(sheet) do
    timestamp =
      DateTime.utc_now()
      |> DateTime.to_iso8601()
      |> String.replace(":", "-")

    path = "/tmp/Relatory-#{timestamp}.xlsx"
    workbook = %Workbook{sheets: [sheet]}
    Elixlsx.write_to(workbook, path)
    path
  end

  defp format_time(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_time(_), do: "invalid"

  defp maybe_create_bucket(bucket) do
    case S3.head_bucket(bucket) |> ExAws.request() do
      {:ok, _} ->
        :ok

      {:error, {:http_error, 404, _}} ->
        S3.put_bucket(bucket, "local") |> ExAws.request!()

      {:error, err} ->
        Logger.error("Erro ao verificar/criar bucket: #{inspect(err)}")
        :error
    end
  end

  def list_reports do
    case S3.list_objects(@bucket) |> ExAws.request() do
      {:ok, %{body: %{contents: contents}}} ->
        contents
        |> Enum.filter(fn %{key: key} -> String.ends_with?(key, ".xlsx") end)
        |> Enum.map(fn %{key: key, last_modified: modified, size: size} ->
          %{
            filename: key,
            size: format_file_size(size),
            modified: format_date(modified),
            download_url: generate_presigned_url(key)
          }
        end)
        |> Enum.sort_by(& &1.modified, :desc)

      {:error, reason} ->
        Logger.error("Erro ao listar arquivos do S3: #{inspect(reason)}")
        []
    end
  end

  def get_report_download_url(filename) do
    generate_presigned_url(filename)
  end

  defp generate_presigned_url(key) do
    case S3.presigned_url(ExAws.Config.new(:s3), :get, @bucket, key, expires_in: 3600) do
      {:ok, url} -> url
      _ -> nil
    end
  end

  defp format_file_size(size) when is_integer(size) do
    cond do
      size >= 1_048_576 -> "#{Float.round(size / 1_048_576, 1)} MB"
      size >= 1_024 -> "#{Float.round(size / 1_024, 1)} KB"
      true -> "#{size} B"
    end
  end

  defp format_file_size(size) when is_binary(size),
    do: format_file_size(String.to_integer(size))

  defp format_date(date), do: inspect(date)
end
