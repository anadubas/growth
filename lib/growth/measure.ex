defmodule Growth.Measure do
  @moduledoc """
  The child measures info struct
  """

  alias Growth.Calculate
  alias Growth.Child

  @type t :: %__MODULE__{
          height: number() | nil,
          weight: number() | nil,
          head_circumference: number() | nil,
          bmi: number() | String.t() | nil,
          results: map()
        }

  defstruct [
    :weight,
    :height,
    :head_circumference,
    :bmi,
    results: %{}
  ]

  @doc """
  Create a measure result for a child
  """
  @spec new(map(), Child.t()) :: {:ok, t()}
  def new(attrs, child) do
    attrs
    |> create_struct()
    |> add_bmi()
    |> add_results(child)
  end

  defp create_struct(attrs) do
    %__MODULE__{
      height: attrs.height,
      weight: attrs.weight,
      head_circumference: attrs.head_circumference
    }
  end

  defp add_bmi(%__MODULE__{weight: weight, height: height} = growth)
       when is_number(weight) and is_number(height) do
    %{growth | bmi: Calculate.bmi(weight, height)}
  end

  defp add_bmi(%__MODULE__{} = growth) do
    %{growth | bmi: "no measure"}
  end

  defp add_results(%__MODULE__{} = growth, %Child{} = child) do
    {:ok, Calculate.results(growth, child)}
  end
end
