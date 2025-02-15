defmodule Growth.CSVLoader do
  @moduledoc """
  Handles loading and parsing of CSV files containing growth reference data.

  This module provides functionality to:

  * Load CSV files containing WHO growth standards data
  * Parse the CSV content into structured Elixir maps
  * Convert string values to appropriate numeric types (integers for age, floats for measurements)

  The module expects CSV files with headers in the first row and uses RFC4180 standard
  CSV parsing through NimbleCSV.

  The function returns either:

  * `{:ok, list_of_maps}` where each map represents a row with atomized keys
  * `{:error, reason}` if the file cannot be found or processed
  """

  alias NimbleCSV.RFC4180, as: CSV

  @spec load_csv_data(String.t()) :: {:ok, list(map)} | {:error, String.t()}
  def load_csv_data(file_path) do
    if File.exists?(file_path) do
      file_path
      |> File.read!()
      |> CSV.parse_string(skip_headers: false)
      |> convert_to_map()
      |> format_map()
    else
      {:error, "File not found: #{file_path}"}
    end
  end

  defp convert_to_map(rows) do
    [header | data_rows] = rows

    data =
      data_rows
      |> Enum.map(fn row ->
        Enum.zip(header, row)
        |> Enum.into(%{})
      end)

    {:ok, data}
  end

  defp format_map({:ok, data}) do
    converted_data =
      Enum.map(data, fn row ->
        Enum.reduce(row, %{}, fn {key, value}, acc ->
          atom_key = String.to_atom(key)
          converted_value = convert_value(atom_key, value)
          Map.put(acc, atom_key, converted_value)
        end)
      end)

    {:ok, converted_data}
  end

  defp convert_value(:age, value) do
    case Integer.parse(value) do
      {int_value, ""} -> int_value
      _ -> value
    end
  end

  defp convert_value(_key, value) do
    case Float.parse(value) do
      {float, ""} -> float
      _ -> value
    end
  end
end
