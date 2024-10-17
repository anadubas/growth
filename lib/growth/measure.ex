defmodule Growth.Measure do
  @moduledoc """
  The child measures info struct
  """

  alias Growth.Child
  alias Growth.Calculate

  @type t :: %__MODULE__{
          height: number(),
          weight: number(),
          head_circumference: number(),
          bmi: number(),
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
  @spec new(map(), Child.t()) :: {:ok, t()} | {:error, term()}
  def new(attrs, child) do
    attrs
    |> create_struct()
    |> add_bmi()
    |> add_results(child)
  end

  defp create_struct(attrs) do
    %__MODULE__{
      height: parse_float(attrs["height"]),
      weight: parse_float(attrs["weight"]),
      head_circumference: parse_float(attrs["head_circumference"])
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
    {:ok, %{growth | results: Calculate.results(growth, child)}}
  end

  defp parse_float(value) when is_binary(value) do
    {float, _} = Float.parse(value)

    float
  end
end
