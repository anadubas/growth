defmodule Growth.Zscore do
  @moduledoc """
  Provides functionality to calculate Z-scores using the LMS method.

  The LMS method is commonly used in growth assessment to calculate Z-scores
  (standard deviation scores) for anthropometric measurements. It accounts for
  the skewness (L), median (M), and coefficient of variation (S) of the
  reference distribution.

  The module implements extended Z-score calculations that handle extreme values
  (beyond ±3 SD) using a special adjustment to prevent excessive values while
  maintaining the relative ordering of measurements.
  """

  @doc """
  Calculates the Z-score for a given measurement using the LMS method.
  This function handles extreme values (beyond ±3 SD) using an adjustment
  to prevent excessive Z-scores while maintaining the relative ordering of
  measurements.
  ## Parameters
    - `measure`: The anthropometric measurement (e.g., weight, height).
    - `l`: The Box-Cox transformation parameter (skewness).
    - `m`: The median of the reference population.
    - `s`: The coefficient of variation of the reference population.
  ## Returns
    - The calculated Z-score as a float.
  ## Examples
      iex> Growth.Zscore.calculate(10.0, 0.1, 9.5, 0.2)
      0.5278640450004206
      iex> Growth.Zscore.calculate(15.0, 0.1, 9.5, 0.2)
      3.25
      iex> Growth.Zscore.calculate(5.0, 0.1, 9.5, 0.2)
      -3.25
  """
  @spec calculate(number(), number(), number(), number()) :: number()
  def calculate(measure, l, m, s) do
    measure
    |> raw_zscore(l, m, s)
    |> adjust_result(measure, l, m, s)
  end

  @doc false
  defp raw_zscore(measure, 0, m, s), do: :math.log(measure / m) / s
  defp raw_zscore(measure, l, m, s), do: (:math.pow(measure / m, l) - 1) / (s * l)

  @doc false
  defp adjust_result(zscore, measure, l, m, s) when zscore > 3 do
    %{+2 => sd2, +3 => sd3} = cutoffs(l, m, s)
    3 + (measure - sd3) / (sd3 - sd2)
  end

  defp adjust_result(zscore, measure, l, m, s) when zscore < -3 do
    %{-2 => sd2, -3 => sd3} = cutoffs(l, m, s)
    -3 + (measure - sd3) / (sd2 - sd3)
  end

  defp adjust_result(zscore, _, _, _, _), do: zscore

  @doc false
  defp cutoffs(l, m, s) do
    for sd <- [-3, -2, +2, +3], into: %{} do
      {sd, m * :math.pow(1 + l * s * sd, 1 / l)}
    end
  end
end
