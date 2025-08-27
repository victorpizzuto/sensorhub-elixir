defmodule SensorhubElixirCluster.HordeListener do
  @moduledoc false

  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  def init(_) do
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, nil}
  end

  def handle_info({:nodeup, _node, _node_type}, state) do
    set_members(SensorhubElixirCluster.HordeRegistry)
    set_members(SensorhubElixirCluster.HordeSupervisor)
    {:noreply, state}
  end

  def handle_info({:nodedown, _node, _node_type}, state) do
    set_members(SensorhubElixirCluster.HordeRegistry)
    set_members(SensorhubElixirCluster.HordeSupervisor)
    {:noreply, state}
  end

  defp set_members(name) do
    members =
      [Node.self() | Node.list()]
      |> Enum.map(fn node -> {name, node} end)

    :ok = Horde.Cluster.set_members(name, members)
  end
end
