defmodule SensorhubElixirCluster.HordeRegistry do
  @moduledoc false

  use Horde.Registry

  def start_link(_) do
    Horde.Registry.start_link(__MODULE__, [members: :auto, keys: :unique], name: __MODULE__)
  end

  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.Registry.init()
  end

  defp members() do
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {__MODULE__, node} end)
  end
end
