defmodule SensorhubElixir.Sensor do
  use Ecto.Schema
  import Ecto.Changeset
  alias SensorhubElixir.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sensors" do
    field :uuid, Ecto.UUID
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(sensor, attrs) do
    sensor
    |> cast(attrs, [:uuid, :name])
    |> validate_required([:uuid, :name])
  end

  def list_sensors do
    Repo.all(__MODULE__)
  end
end
