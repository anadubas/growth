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

  @spec calculate(number(), number(), number(), number()) :: number()
  def calculate(measure, l, m, s) do
    measure
    |> raw_zscore(l, m, s)
    |> adjust_result(measure, l, m, s)
  end

  defp raw_zscore(measure, l, m, s) do
    (:math.pow(measure / m, l) - 1) / (s * l)
  end

  defp adjust_result(zscore, measure, l, m, s) when zscore > 3 do
    [sd2, sd3, _, _] = cutoffs(l, m, s)
    sd_delta = sd3 - sd2
    3 + (measure - sd3) / sd_delta
  end

  defp adjust_result(zscore, measure, l, m, s) when zscore < -3 do
    [_, _, sd2, sd3] = cutoffs(l, m, s)
    sd_delta = sd2 - sd3
    -3 + (measure - sd3) / sd_delta
  end

  defp adjust_result(zscore, _, _, _, _) do
    zscore
  end

  defp cutoffs(l, m, s) do
    Enum.map([2, 3, -2, -3], &measure_deviation(&1, l, m, s))
  end

  defp measure_deviation(sd, l, m, s) do
    m * :math.pow(1 + l * s * sd, 1 / l)
  end
end
