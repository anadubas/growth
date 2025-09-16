defmodule Growth.Percentile do
  @moduledoc """
  Provides functionality to convert Z-scores to percentiles.

  The Z-score is a standardized measure of the standard deviation of a
  measurement. It is commonly used in growth assessment to calculate percentiles
  for anthropometric measurements. The percentile is a ranking of a measurement
  within a distribution, with 0 being the minimum value and 100 being the
  maximum value.

  The module provides functions to convert Z-scores to percentiles using the
  standard normal distribution. The Z-score is first converted to a standard
  normal distribution using the inverse error function (erfinv) and then
  converted to a percentile using the cumulative distribution function (erfc).
  """

  @doc """
  Converts a Z-score to a percentile using the standard normal distribution.

  ## Parameters
    - `z`: The Z-score to convert to a percentile.

  ## Returns
    - The percentile as a float between 0 and 100.

  ## Examples
      iex> Growth.Percentile.to_percentile(0.5)
      0.6915
      iex> Growth.Percentile.to_percentile(-1.0)
      0.1587
      iex> Growth.Percentile.to_percentile(3.0)
      0.9987
  """
  @spec calculate(number()) :: float()
  def calculate(z) do
    prob = 0.5 * (1.0 + :math.erf(z / :math.sqrt(2)))
    Float.round(prob, 4)
  end
end
