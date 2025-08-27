defmodule SensorhubElixirMqtt.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    childrens = [
      {SensorhubElixirMqtt.Workers.Pipeline, [name: "pipeline"]}
    ]

    Supervisor.start_link(childrens,
      strategy: :one_for_one,
      name: SensorhubElixirCluster.via("mqtt_supervisor")
    )
  end
end
