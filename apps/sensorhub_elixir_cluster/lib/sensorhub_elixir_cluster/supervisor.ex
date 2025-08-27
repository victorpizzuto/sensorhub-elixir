defmodule SensorhubElixirCluster.Supervisor do
  @moduledoc false
  use Horde.DynamicSupervisor

  def start_link(_) do
    Horde.DynamicSupervisor.start_link(
      __MODULE__,
      [
        members: :auto,
        strategy: :one_for_one,
        distribution_strategy: Horde.UniformDistribution
      ],
      name: __MODULE__
    )
  end

  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end

  defp members() do
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {__MODULE__, node} end)
  end

  def start_child(child_spec) do
    Horde.DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_child(pid) do
    Horde.DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
