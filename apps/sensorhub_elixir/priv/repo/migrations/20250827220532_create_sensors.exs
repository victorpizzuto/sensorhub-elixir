defmodule SensorhubElixir.Repo.Migrations.CreateSensors do
  use Ecto.Migration

  def change do
    create table(:sensors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uuid, :uuid
      add :name, :string

      timestamps()
    end
  end
end
