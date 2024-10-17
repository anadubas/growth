defmodule Growth.Measure do
  @moduledoc """
  The child measures info struct
  """

  alias Growth.Child
  alias Growth.Calculate

  @type t :: %__MODULE__{
    height: number(),
    weight: number(),
    head_circumference:  number(),
    imc: number(),
    results: map()
  }

  defstruct [
    :weight,
    :height,
    :head_circumference,
    :imc,
    results: %{}
  ]

  @doc"""
  Create a measure result for a child
  """
  @spec new(map(), Child.t()) :: {:ok, t()} | {:error, term()}
  def new(attrs, child) do
    attrs
    |> create_struct()
    |> add_imc()
    |> add_results(child)
  end

  defp create_struct(attrs) do
    %__MODULE__{
      height: attrs.height,
      weight: attrs.weight,
      head_circumference: attrs.head_circumference
    }
  end

  defp add_imc(%__MODULE__{weight: weight, height: height} = growth)
    when is_number(weight) and is_number(height) do
    %{growth | imc: Calculate.imc(weight, height)}
  end

  defp add_imc(%__MODULE__{} = growth), do: %{growth | imc: "no measure"}

  defp add_results(%__MODULE__{} = growth, %Child{} = child) do
    {:ok, %{growth | results: Calculate.results(growth, child)}}
  end
end
