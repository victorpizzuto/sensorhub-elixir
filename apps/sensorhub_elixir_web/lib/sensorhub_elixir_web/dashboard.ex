defmodule SensorhubElixirWeb.Dashboard do
  alias SensorhubElixirTimeseries.Workers.Timeseries
  alias SensorhubElixir.Sensor

  def get_past_data do
    try do
      thirty_minutes_ago = DateTime.utc_now() |> DateTime.add(-1800, :second)
      query = %{"timestamp" => %{"$gte" => thirty_minutes_ago}}

      case Timeseries.read("telemetry", query) do
        {:ok, [_ | _] = data} ->
          format_past_data(data)

        _ ->
          generate_mock_past_data()
      end
    rescue
      _ ->
        generate_mock_past_data()
    end
  end

  defp format_past_data(data) do
    grouped_data =
      Enum.group_by(data, fn item ->
        Map.get(item, "sensor_id", "sensor_unknown")
      end)

    series =
      Enum.map(grouped_data, fn {sensor_id, readings} ->
        chart_data =
          Enum.map(readings, fn reading ->
            timestamp = Map.get(reading, "timestamp", DateTime.utc_now())
            value = Map.get(reading, "value", 0)
            [timestamp, value]
          end)
          |> Enum.sort_by(fn [timestamp, _] -> timestamp end)

        %{
          name: "Sensor #{sensor_id}",
          type: "line",
          data: chart_data,
          smooth: true
        }
      end)

    %{
      tooltip: %{
        trigger: "axis",
        axisPointer: %{type: "cross"}
      },
      legend: %{
        data: Enum.map(series, & &1.name)
      },
      grid: %{
        left: "3%",
        right: "4%",
        bottom: "3%",
        containLabel: true
      },
      xAxis: %{
        type: "time",
        boundaryGap: false
      },
      yAxis: %{
        type: "value"
      },
      series: series
    }
  end

  defp generate_mock_past_data do
    now = DateTime.utc_now()

    sensors_info =
      try do
        sensors = Sensor.list_sensors()

        if length(sensors) > 0 do
          Enum.with_index(sensors, 1)
        else
          [{%{id: 1, name: "Sensor 1"}, 1}]
        end
      rescue
        _ ->
          [{%{id: 1, name: "Sensor 1"}, 1}, {%{id: 2, name: "Sensor 2"}, 2}]
      end

    series =
      for {sensor, index} <- sensors_info do
        data =
          for i <- 0..59 do
            timestamp = DateTime.add(now, -(59 - i) * 30, :second)
            value = :rand.uniform() * 100 + index * 10
            [DateTime.to_unix(timestamp, :millisecond), Float.round(value, 2)]
          end

        sensor_name = Map.get(sensor, :name, "Sensor #{Map.get(sensor, :id, index)}")

        %{
          name: sensor_name,
          type: "line",
          data: data,
          smooth: true
        }
      end

    %{
      tooltip: %{
        trigger: "axis",
        axisPointer: %{type: "cross"}
      },
      legend: %{
        data: Enum.map(series, & &1.name)
      },
      grid: %{
        left: "3%",
        right: "4%",
        bottom: "3%",
        containLabel: true
      },
      xAxis: %{
        type: "time",
        boundaryGap: false
      },
      yAxis: %{
        type: "value"
      },
      series: series
    }
  end

  def get_velocity_data do
    try do
      thirty_minutes_ago = DateTime.utc_now() |> DateTime.add(-1800, :second)

      query = %{
        "timestamp" => %{"$gte" => thirty_minutes_ago},
        "type" => "velocity"
      }

      case Timeseries.read("telemetry", query) do
        {:ok, [_ | _] = data} ->
          format_sensor_data(data, "Speed (km/h)")

        _ ->
          generate_mock_velocity_data()
      end
    rescue
      _ ->
        generate_mock_velocity_data()
    end
  end

  def get_temperature_data do
    try do
      thirty_minutes_ago = DateTime.utc_now() |> DateTime.add(-1800, :second)

      query = %{
        "timestamp" => %{"$gte" => thirty_minutes_ago},
        "type" => "temperature"
      }

      case Timeseries.read("telemetry", query) do
        {:ok, [_ | _] = data} ->
          format_sensor_data(data, "Temperature (°C)")

        _ ->
          generate_mock_temperature_data()
      end
    rescue
      _ ->
        generate_mock_temperature_data()
    end
  end

  def parse_new_message(new_data, old_chart_data) do
    timestamp =
      case new_data["timestamp"] || new_data["time"] do
        %DateTime{} = dt -> DateTime.to_unix(dt, :millisecond)
        ts when is_integer(ts) -> ts
        _ -> DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      end

    sensor_id = new_data["uuid"] || new_data["sensor_id"] || "sensor_unknown"

    {value, data_type} =
      cond do
        new_data["speed"] -> {new_data["speed"], "velocity"}
        new_data["temperature"] -> {new_data["temperature"], "temperature"}
        new_data["value"] -> {new_data["value"], "unknown"}
        true -> {0, "unknown"}
      end

    chart_type =
      cond do
        Map.get(old_chart_data, :yAxis) |> Map.get(:name, "") |> String.contains?("Speed") ->
          "velocity"

        Map.get(old_chart_data, :yAxis)
        |> Map.get(:name, "")
        |> String.contains?("Temperature") ->
          "temperature"

        true ->
          "unknown"
      end

    if data_type == chart_type do
      updated_series =
        Enum.map(old_chart_data.series || [], fn series ->
          if String.contains?(series.name, "Sensor") do
            new_data_point = [timestamp, value]

            updated_data =
              [new_data_point | series.data]
              |> Enum.sort_by(&List.first/1)
              |> Enum.take(-50)

            %{series | data: updated_data}
          else
            series
          end
        end)

      %{old_chart_data | series: updated_series}
    else
      old_chart_data
    end
  end

  defp format_sensor_data(data, unit_label) do
    grouped_data =
      Enum.group_by(data, fn item ->
        Map.get(item, "sensor_id", "sensor_unknown")
      end)

    series =
      Enum.map(grouped_data, fn {sensor_id, readings} ->
        chart_data =
          Enum.map(readings, fn reading ->
            timestamp = Map.get(reading, "timestamp", DateTime.utc_now())
            value = Map.get(reading, "value", 0)
            [DateTime.to_unix(timestamp, :millisecond), value]
          end)
          |> Enum.sort_by(fn [timestamp, _] -> timestamp end)

        %{
          name: "Sensor #{sensor_id}",
          type: "line",
          data: chart_data,
          smooth: true
        }
      end)

    %{
      tooltip: %{
        trigger: "axis",
        axisPointer: %{type: "cross"}
      },
      legend: %{
        data: Enum.map(series, & &1.name)
      },
      grid: %{
        left: "3%",
        right: "4%",
        bottom: "3%",
        containLabel: true
      },
      xAxis: %{
        type: "time",
        boundaryGap: false
      },
      yAxis: %{
        type: "value",
        name: unit_label
      },
      series: series
    }
  end

  defp generate_mock_velocity_data do
    now = DateTime.utc_now()

    sensors_info = get_sensors_info()

    series =
      for {sensor, index} <- sensors_info do
        data =
          for i <- 0..59 do
            timestamp = DateTime.add(now, -(59 - i) * 30, :second)
            base_velocity = 40 + index * 20
            variation = :rand.uniform() * 40 - 20
            value = max(0, base_velocity + variation)
            [DateTime.to_unix(timestamp, :millisecond), Float.round(value, 1)]
          end

        sensor_name = Map.get(sensor, :name, "Sensor #{Map.get(sensor, :id, index)}")

        %{
          name: sensor_name,
          type: "line",
          data: data,
          smooth: true
        }
      end

    %{
      tooltip: %{
        trigger: "axis",
        axisPointer: %{type: "cross"}
      },
      legend: %{
        data: Enum.map(series, & &1.name)
      },
      grid: %{
        left: "3%",
        right: "4%",
        bottom: "3%",
        containLabel: true
      },
      xAxis: %{
        type: "time",
        boundaryGap: false
      },
      yAxis: %{
        type: "value",
        name: "Speed (km/h)"
      },
      series: series
    }
  end

  defp generate_mock_temperature_data do
    now = DateTime.utc_now()

    sensors_info = get_sensors_info()

    series =
      for {sensor, index} <- sensors_info do
        data =
          for i <- 0..59 do
            timestamp = DateTime.add(now, -(59 - i) * 30, :second)
            base_temp = 20 + index * 5
            variation = :rand.uniform() * 10 - 5
            value = base_temp + variation
            [DateTime.to_unix(timestamp, :millisecond), Float.round(value, 1)]
          end

        sensor_name = Map.get(sensor, :name, "Sensor #{Map.get(sensor, :id, index)}")

        %{
          name: sensor_name,
          type: "line",
          data: data,
          smooth: true
        }
      end

    %{
      tooltip: %{
        trigger: "axis",
        axisPointer: %{type: "cross"}
      },
      legend: %{
        data: Enum.map(series, & &1.name)
      },
      grid: %{
        left: "3%",
        right: "4%",
        bottom: "3%",
        containLabel: true
      },
      xAxis: %{
        type: "time",
        boundaryGap: false
      },
      yAxis: %{
        type: "value",
        name: "Temperature (°C)"
      },
      series: series
    }
  end

  defp get_sensors_info do
    try do
      sensors = Sensor.list_sensors()

      if length(sensors) > 0 do
        Enum.with_index(sensors, 1)
      else
        [{%{id: 1, name: "Sensor 1"}, 1}]
      end
    rescue
      _ ->
        [{%{id: 1, name: "Sensor 1"}, 1}, {%{id: 2, name: "Sensor 2"}, 2}]
    end
  end
end
