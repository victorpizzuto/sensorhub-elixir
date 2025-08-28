alias SensorhubElixir.Repo
alias SensorhubElixir.Sensor

Repo.insert_all(Sensor, [
  %{
    uuid: "80eabbe6-7e6a-42a4-8ecf-5b3da87460e2",
    name: "Sensor 1",
    inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
  },
  %{
    uuid: "5a54cabf-2caf-4e38-8b4c-9d8b5c70ea54",
    name: "Sensor 2",
    inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
  }
])
