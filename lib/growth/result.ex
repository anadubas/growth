defmodule Growth.Result do
  @moduledoc false
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
          classification: String.t() | nil
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
