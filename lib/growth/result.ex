defmodule Growth.Result do
  @moduledoc """
  Represents a result for a given measurement of a child, such as weight, height, etc.

  This holds the `zscore` and `percentile` wich allow one to compare how this measurement fits agagainst common patterns. As well as, have a `classification` that summarizes this comparison.

  To help knowing if the result is available or not, the `available?` field is set, so any consumer is aware if this result is not available, due to missing measurement value or missing classification data.
  """
  @type null_number() :: number() | nil
  @type null_non_neg_number() :: number() | nil
  @type t() :: %__MODULE__{
          sd3neg: null_non_neg_number(),
          sd2neg: null_non_neg_number(),
          sd1neg: null_non_neg_number(),
          sd0: null_non_neg_number(),
          sd1: null_non_neg_number(),
          sd2: null_non_neg_number(),
          sd3: null_non_neg_number(),
          zscore: null_number(),
          percentile: null_non_neg_number(),
          classification: String.t() | nil,
          available?: boolean()
        }
  defstruct [
    :sd3neg,
    :sd2neg,
    :sd1neg,
    :sd0,
    :sd1,
    :sd2,
    :sd3,
    :zscore,
    :percentile,
    :classification,
    :available?
  ]

  @doc """
  Create a new result based on the availability of data and the data itself.
  """
  @spec new(boolean(), map()) :: t()
  def new(false, _) do
    %__MODULE__{available?: false}
  end

  def new(true, params) do
    __MODULE__
    |> struct(params)
    |> Map.put(:available?, true)
  end
end
