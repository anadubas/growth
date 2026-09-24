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

  @doc """
  Loads a reference data row from the ETS table for a given measurement type and measure data.

  ## Parameters

  * `data_type`: The type of measurement, e.g., `:weight`, `:bmi`, etc.
  * `measure`: The measure struct, which must have at least child gender and age in months.

  ## Returns

  * `{:ok, reference_data}` if the data is found in the ETS table.
  * `{:error, reason}` if the data is invalid or not found.
  * `{:error, [Zoi.Error.t()]} if the child data was not valid.
  """
  @spec load_data(atom(), Growth.Measure.t()) ::
          {:ok, map()} | {:error, String.t()} | {:error, [Zoi.Error.t()]}
  def load_data(data_type, %Growth.Measure{
        child: %Growth.Child{gender: gender},
        measure_date: measure_date,
        age_in_months: age_in_months
      }) do
    :telemetry.span(
      [:growth, :reference_data, :load],
      %{
        age_in_months: age_in_months,
        gender: gender,
        data_type: data_type,
        measure_date: measure_date
      },
      fn ->
        case get_reference(data_type, gender, age_in_months) do
          {:ok, value} ->
            {{:ok, value},
             %{
               age_in_months: age_in_months,
               gender: gender,
               data_type: data_type,
               measure_date: measure_date,
               success: true
             }}

          {:error, reason} ->
            {{:error, reason},
             %{
               age_in_months: age_in_months,
               child_gender: gender,
               data_type: data_type,
               measure_date: measure_date,
               success: false,
               reason: reason
             }}
        end
      end
    )
  end

  defp get_reference(data_type, gender, age_in_months) do
    a_gender = String.to_existing_atom(gender)

    case :ets.lookup(data_type, {a_gender, :month, age_in_months}) do
      [{{^a_gender, :month, ^age_in_months}, data}] -> {:ok, data}
      [] -> {:error, "reference not found for #{data_type}, #{gender}, age #{age_in_months}"}
    end
  end
end
