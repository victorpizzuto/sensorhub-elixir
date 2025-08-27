defmodule SensorhubElixirTimeseries.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    childrens = [
      {SensorhubElixirTimeseries.Workers.Timeseries, [name: "timeseries"]}
    ]

    Supervisor.start_link(childrens,
      strategy: :one_for_one,
      name: SensorhubElixirCluster.via("timeseries_supervisor")
    )
  end
end
