defmodule Growth.LoadReferenceChart do
  @moduledoc """
  Provides access to WHO child growth reference data for a range of ages.

  This module retrieves a series of growth standard data points for a given measurement type
  (e.g., `:weight`, `:height`) and gender, centered around a specific age. This is useful for
  generating data for growth charts. The data is assumed to be preloaded into named ETS
  tables by the `Growth.CSVLoader` module.

  ## Supported Data Types

  - `:weight` — Weight-for-age reference
  - `:height` — Height-for-age reference
  - `:bmi` — BMI-for-age reference
  - `:head_circumference` — Head circumference-for-age reference
  """

  @doc """
  Loads a range of reference data from the ETS table for a given measurement type and child.
  Can optionally interpolate data between months to create a smoother chart.

  ## Parameters
    - `data_type`: The type of measurement, e.g., `:weight`, `:bmi`, etc.
    - `gender`: The gender of the child, e.g., `:boy` or `:girl`.
    - `reference_age_in_months`: The age in months to center the data range around.
    - `range_size_in_months`: The number of months to extend the range on either side of the reference age. Defaults to 4. Can also be `:inf` to retrieve all data.
    - `subdivisions`: The number of interpolated points to generate between each month. Defaults to 0 (no interpolation).

  ## Returns
    - `{:ok, list_of_reference_data}` if data is found. The list is sorted by age.
    - `{:error, reason}` if no data is found for the given parameters.
  """
  @spec load_data(atom(), atom(), pos_integer(), atom() | pos_integer(), non_neg_integer()) ::
          {:ok, list(map())} | {:error, String.t()}
  def load_data(
        data_type,
        gender,
        reference_age_in_months,
        range_size_in_months \\ 4,
        subdivisions \\ 0
      ) do
    data_type
    |> match_spec(gender, reference_age_in_months, range_size_in_months)
    |> then(&:ets.select(data_type, &1))
    |> case do
      [] ->
        {:error, "no data found for #{data_type}, #{gender}, age #{reference_age_in_months}"}

      result ->
        interpolated_result =
          result
          |> Enum.sort(&(&1.age < &2.age))
          |> interpolate_data(subdivisions)

        {:ok, interpolated_result}
    end
  end

  defp match_spec(_, gender, _, :inf) do
    [{{{gender, :month, :_}, :"$2"}, [], [:"$2"]}]
  end

  defp match_spec(data_type, gender, reference_age_in_months, range_size_in_months) do
    {data_type_age_lower_limit, data_type_age_upper_limit} = age_range_for(data_type, gender)

    age_lower_limit =
      :erlang.max(data_type_age_lower_limit, reference_age_in_months - range_size_in_months)

    age_upper_limit =
      :erlang.min(data_type_age_upper_limit, reference_age_in_months + range_size_in_months)

    [
      {{{gender, :month, :"$1"}, :"$2"},
       [{:andalso, {:>=, :"$1", age_lower_limit}, {:"=<", :"$1", age_upper_limit}}], [:"$2"]}
    ]
  end

  defp age_range_for(data_type, gender) do
    ages = :ets.select(data_type, [{{{gender, :month, :"$1"}, :_}, [], [:"$1"]}])
    {Enum.min(ages), Enum.max(ages)}
  end

  defp interpolate_data([_ | _] = results, 0) do
    results
  end

  defp interpolate_data([_ | _] = results, subdivisions) do
    last_point = List.last(results)

    results
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.flat_map(fn [lower_ref, upper_ref] ->
      interpolated_points =
        Enum.map(1..subdivisions, fn i ->
          fraction = i / (subdivisions + 1)
          interpolate(lower_ref, upper_ref, fraction)
        end)

      [lower_ref | interpolated_points]
    end)
    |> Kernel.++([last_point])
  end

  defp interpolate_data(_, _) do
    []
  end

  defp interpolate(lower_ref, upper_ref, fraction) do
    keys = [:l, :m, :s, :sd0, :sd1, :sd2, :sd3, :sd1neg, :sd2neg, :sd3neg]

    interpolated_values =
      Enum.reduce(keys, %{}, fn key, acc ->
        v_lower = Map.get(lower_ref, key)
        v_upper = Map.get(upper_ref, key)

        # linear interpolation
        value =
          if is_number(v_lower) and is_number(v_upper) do
            v_lower + (v_upper - v_lower) * fraction
          else
            v_lower
          end

        Map.put(acc, key, value)
      end)

    lower_ref
    |> Map.put(:age, lower_ref.age + fraction)
    |> Map.merge(interpolated_values)
  end
end
