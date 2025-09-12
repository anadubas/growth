defmodule Growth.LoadReference do
  @moduledoc """
  Provides access to WHO child growth reference data stored in ETS tables.

  This module retrieves growth standard data for a given measurement type (e.g., weight, height, BMI)
  based on a child's age (in months) and gender. The data is assumed to be preloaded into named ETS
  tables by the `Growth.CSVLoader` module.

  ## Supported Data Types

  - `:weight` — Weight-for-age reference
  - `:height` — Height-for-age reference
  - `:bmi` — BMI-for-age reference
  - `:head_circumference` — Head circumference-for-age reference
  """
  require :telemetry

  @doc """
  Loads a reference data row from the ETS table for a given measurement type and child.

  ## Parameters
    - `data_type`: The type of measurement, e.g., `:weight`, `:bmi`, etc.
    - `child`: The child struct, which must have at least `:gender` and `:age_in_months`.

  ## Returns
    - `{:ok, reference_data}` if the data is found in the ETS table.
    - `{:error, reason}` if the data is invalid or not found.
  """
  @spec load_data(atom(), Growth.Child.t()) :: {:ok, map()} | {:error, String.t()}
  def load_data(data_type, %Growth.Child{gender: _gender, age_in_months: nil} = child) do
    with {:ok, updated_child} <- Growth.Child.add_age_in_months(child) do
      load_data(data_type, updated_child)
    end
  end

  def load_data(data_type, %Growth.Child{gender: gender, age_in_months: age_in_months} = child) do
    :telemetry.span(
      [:growth, :reference_data, :load],
      %{
        age_in_months: age_in_months,
        gender: gender,
        data_type: data_type,
        measure_date: child.measure_date
      },
      fn ->
        key = {String.to_atom(gender), :month, age_in_months}

        case :ets.lookup(data_type, key) do
          [{^key, value}] ->
            {{:ok, value},
             %{
               age_in_months: age_in_months,
               gender: gender,
               data_type: data_type,
               measure_date: child.measure_date,
               success: true
             }}

          [] ->
            reason = "Data not found for #{inspect(key)} in #{inspect(data_type)}"

            {{:error, reason},
             %{
               age_in_months: age_in_months,
               child_gender: gender,
               data_type: data_type,
               measure_date: child.measure_date,
               success: false,
               reason: reason
             }}
        end
      end
    )
  end
end
