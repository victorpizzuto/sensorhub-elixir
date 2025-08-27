defmodule SensorhubElixirCluster.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor,
       [
         Application.get_env(:libcluster, :topologies),
         [name: SensorhubElixirCluster.ClusterSupervisor]
       ]},
      SensorhubElixirCluster.HordeSupervisor,
      SensorhubElixirCluster.HordeRegistry,
      SensorhubElixirCluster.HordeListener
    ]

    opts = [strategy: :one_for_one, name: SensorhubElixirCluster.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
