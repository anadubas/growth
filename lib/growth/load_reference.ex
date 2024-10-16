defmodule Growth.LoadReference do
  alias Growth.CSVLoader

  @data %{
    weight: "weight_for_age.csv",
    height: "height_for_age.csv",
    imc: "bmi_for_age.csv",
    head_circumference: "head_circumference_for_age.csv"
  }

  @spec load_data(atom()) :: {:ok, list(map)} | {:error, String.t()}
  def load_data(data_type) when is_atom(data_type) do
    case Map.get(@data, data_type) do
      nil ->
        {:error, "Invalid data type: #{data_type}"}

      file_name ->
        file_path = "priv/indicators/" <> file_name
        CSVLoader.load_csv_data(file_path)
    end
  end
end
