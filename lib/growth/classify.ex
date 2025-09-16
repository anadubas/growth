defmodule Growth.Classify do
  @moduledoc """
  Provides functionality to classify anthropometric measurements.

  The module provides functions to classify anthropometric measurements based on
  their Z-scores and percentiles. The classification is based on the Z-score and
  percentile ranges for different anthropometric measurements.
  """

  @doc """
  Classifies anthropometric measurements based on their Z-scores and percentiles.

  ## Parameters
    - `data_type`: The type of anthropometric measurement (e.g., `:weight`, `:height`).
    - `z`: The Z-score of the anthropometric measurement.

  ## Returns
    - The classification as a string.

  ## Examples
      iex> Growth.Classify.calculate(:weight, 0.5)
      "Eutrofia"
      iex> Growth.Classify.calculate(:height, 3.0)
      "Estatura adequada"
  """
  @spec calculate(atom(), number()) :: String.t()
  def calulate(:weight, z) do
    cond do
      z < -3 -> "Baixo peso grave"
      z < -2 -> "Baixo peso"
      z <= 2 -> "Eutrófico"
      z <= 3 -> "Sobrepeso"
      true -> "Obesidade"
    end
  end

  def calculate(:height, z) do
    cond do
      z < -3 -> "Muito baixa estatura"
      z < -2 -> "Baixa estatura"
      true -> "Estatura adequada"
    end
  end

  def calculate(:bmi, z) do
    cond do
      z < -3 -> "Magreza acentuada"
      z < -2 -> "Magreza"
      z <= 1 -> "Eutrofia"
      z <= 2 -> "Sobrepeso"
      z <= 3 -> "Obesidade"
      true -> "Obesidade grave"
    end
  end

  def calculate(:head_circumference, z) do
    cond do
      z < -2 -> "Microcefalia"
      z > 2 -> "Macrocefalia"
      true -> "Normal"
    end
  end

  def calculate(_data_type, _z) do
    "Sem classificação"
  end
end
