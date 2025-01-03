defmodule Growth.LoadReference do
  @moduledoc """
  Manages the loading of WHO growth reference data files for different anthropometric indicators.

  This module provides a centralized way to access various WHO growth standard
  reference data files stored in the application's priv/indicators directory.
  It supports loading data for:

  * Weight-for-age
  * Height-for-age
  * BMI-for-age
  * Head circumference-for-age

  The module uses predefined file mappings and ensures that only valid indicator
  types can be requested. All data files are expected to be in CSV format and
  located in the application's priv/indicators directory.

  ## Supported data types

  * `:weight` - Weight-for-age data
  * `:height` - Height-for-age data
  * `:bmi` - BMI-for-age data
  * `:head_circumference` - Head circumference-for-age data
  """
  alias Growth.CSVLoader

  @data %{
    weight: "weight_for_age.csv",
    height: "height_for_age.csv",
    bmi: "bmi_for_age.csv",
    head_circumference: "head_circumference_for_age.csv"
  }

  @spec load_data(atom()) :: {:ok, list(map)} | {:error, String.t()}
  def load_data(data_type) when is_atom(data_type) do
    case Map.get(@data, data_type) do
      nil ->
        {:error, "Invalid data type: #{data_type}"}

      file_name ->
        :growth
        |> Application.app_dir(["priv", "indicators"])
        |> Path.join(file_name)
        |> CSVLoader.load_csv_data()
    end
  end
end
