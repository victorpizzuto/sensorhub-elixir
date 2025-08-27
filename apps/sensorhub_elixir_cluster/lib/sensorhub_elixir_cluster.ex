defmodule SensorhubElixirCluster do
  @moduledoc """
  Documentation for `SensorhubElixirCluster`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> SensorhubElixirCluster.hello()
      :world

  """
  def hello do
    :world
  end

  def via(name) do
    {:via, Horde.Registry, {SensorhubElixirCluster.HordeRegistry, name}}
  end
end
