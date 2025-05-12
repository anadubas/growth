defmodule Growth.CSVLoader do
  @moduledoc """
  Loads WHO child growth standard CSV files and stores the parsed data into ETS tables.

  This GenServer is started with the application and automatically loads all relevant CSV files
  from the `priv/indicators` directory. The data is parsed using the `NimbleCSV.RFC4180` parser and
  stored in named ETS tables for fast, in-memory access.

  ## Features

    * Automatically loads and parses all relevant WHO growth CSVs at application startup
    * Stores the parsed data into named ETS tables (`:weight`, `:height`, `:bmi`, `:head_circumference`)
    * Supports on-demand reloading via `CSVLoader.reload/0`
    * Each row is stored with a key of `{gender, :month, age}`

  ## Usage

      # Manually trigger a reload of all CSV data
      Growth.CSVLoader.reload()
  """

  use GenServer
  alias NimbleCSV.RFC4180, as: CSV

  @data_dir Application.app_dir(:growth, ["priv", "indicators"])

  @mapping %{
    "weight_for_age.csv" => :weight,
    "height_for_age.csv" => :height,
    "bmi_for_age.csv" => :bmi,
    "head_circumference_for_age.csv" => :head_circumference
  }

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_args), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc """
  Forces a reload of all CSV data into ETS tables.
  """
  @spec reload :: :ok
  def reload, do: GenServer.call(__MODULE__, :reload)

  @impl true
  def init(:ok) do
    load_all()
    {:ok, %{}}
  end

  @impl true
  def handle_call(:reload, _from, state) do
    load_all()
    {:reply, :ok, state}
  end

  defp load_all do
    Path.wildcard(Path.join(@data_dir, "*.csv"))
    |> Enum.each(&load_csv_to_ets/1)
  end

  defp load_csv_to_ets(file_path) do
    case Map.get(@mapping, Path.basename(file_path)) do
      nil ->
        :skip

      table_name ->
        create_ets_table(table_name)

        file_path
        |> File.read!()
        |> CSV.parse_string(skip_headers: false)
        |> convert_to_map()
        |> store_in_ets(table_name)
    end
  end

  defp create_ets_table(name) do
    :ets.new(name, [:set, :public, :named_table])
  rescue
    _ -> :ok
  end

  defp convert_to_map([header | rows]) do
    Enum.map(rows, fn row ->
      Enum.zip(header, row) |> Enum.into(%{})
    end)
  end

  defp store_in_ets(data, table) do
    Enum.each(data, fn row ->
      gender = String.to_atom(row["gender"])
      age = String.to_integer(row["age"])
      key = {gender, :month, age}

      value = %{
        age: age,
        age_unit: "month",
        gender: gender,
        l: parse_float(row["l"]),
        m: parse_float(row["m"]),
        s: parse_float(row["s"]),
        sd0: parse_float(row["sd0"]),
        sd1: parse_float(row["sd1"]),
        sd2: parse_float(row["sd2"]),
        sd3: parse_float(row["sd3"]),
        sd1neg: parse_float(row["sd1neg"]),
        sd2neg: parse_float(row["sd2neg"]),
        sd3neg: parse_float(row["sd3neg"])
      }

      :ets.insert(table, {key, value})
    end)
  end

  defp parse_float(nil), do: nil
  defp parse_float(""), do: nil

  defp parse_float(value) do
    case Float.parse(value) do
      {f, _} -> f
      _ -> nil
    end
  end
end
