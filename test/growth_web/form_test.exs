defmodule GrowthWeb.FormTest do
  use ExUnit.Case, async: true

  alias GrowthWeb.Form

  describe "child_parse/1" do
    test "parses map with string keys" do
      ctx =
        Form.child_parse(%{
          "name" => "Jane",
          "gender" => "female",
          "birthday" => Date.utc_today() |> Date.add(-30) |> Date.to_iso8601()
        })

      assert ctx.valid?
      assert "Jane" == ctx.parsed.name
      assert "female" == ctx.parsed.gender
      assert Date.add(Date.utc_today(), -30) == ctx.parsed.birthday
    end

    test "parses map with atom keys" do
      ctx =
        Form.child_parse(%{
          name: "Jane",
          gender: "female",
          birthday: Date.utc_today() |> Date.add(-30) |> Date.to_iso8601()
        })

      assert ctx.valid?
      assert "Jane" == ctx.parsed.name
      assert "female" == ctx.parsed.gender
      assert Date.add(Date.utc_today(), -30) == ctx.parsed.birthday
    end

    test "validates correctly params" do
      ctx = Form.child_parse(%{name: "J", gender: "-", birthday: "00-01-01"})

      refute ctx.valid?
      assert 3 == Enum.count(ctx.errors)
    end
  end

  describe "measure_parse/1" do
    test "parses map with string keys" do
      ctx =
        Form.measure_parse(%{
          "measure_date" => "2024-01-01",
          "weight" => "10",
          "height" => "10",
          "head_circumference" => "10"
        })

      assert ctx.valid?
      assert ~D[2024-01-01] == ctx.parsed.measure_date
      assert 10 == ctx.parsed.weight
      assert 10 == ctx.parsed.height
      assert 10 == ctx.parsed.head_circumference
    end

    test "parses map with atom keys" do
      ctx =
        Form.measure_parse(%{
          measure_date: ~D[2024-01-01],
          weight: 20.0,
          height: 20.0,
          head_circumference: 20.0
        })

      assert ctx.valid?
      assert ~D[2024-01-01] == ctx.parsed.measure_date
      assert 20.0 == ctx.parsed.weight
      assert 20.0 == ctx.parsed.height
      assert 20.0 == ctx.parsed.head_circumference
    end

    test "treats empty strings as nil (Zoi.Form.prepare/1)" do
      ctx =
        Form.measure_parse(%{
          "measure_date" => "",
          "weight" => "",
          "height" => "",
          "head_circumference" => ""
        })

      assert ctx.valid?
      refute Map.has_key?(ctx.parsed, :measure_date)
      refute Map.has_key?(ctx.parsed, :weight)
      refute Map.has_key?(ctx.parsed, :height)
      refute Map.has_key?(ctx.parsed, :head_circumference)
    end

    test "validates correctly params" do
      ctx = Form.measure_parse(%{weight: "la", height: "la", head_circumference: "la"})

      refute ctx.valid?
      assert 3 == Enum.count(ctx.errors)
    end
  end

  describe "measure_new/1" do
    test "builds an indexed form seeded with today's date" do
      form = Form.measure_new(2)

      assert "measure[2]" == form.name
      assert "measure[2][height]" == form[:height].name
      assert "measure[2][measure_date]" == form[:measure_date].name
      assert Date.utc_today() == form[:measure_date].value
    end
  end

  describe "measures_forms/2" do
    test "builds one indexed form per row" do
      forms =
        Form.measures_forms([
          %{"height" => "80.3"},
          %{"height" => "90.9"}
        ])

      assert 2 == length(forms)
      assert ["measure[0]", "measure[1]"] == Enum.map(forms, & &1.name)
      assert "measure[1][height]" == forms |> List.last() |> then(& &1[:height].name)
    end

    test "keeps per-row contexts and errors, honouring opts" do
      [first, second] =
        Form.measures_forms(
          [
            %{"height" => "80.3"},
            %{"height" => "-1"}
          ],
          action: :validate
        )

      assert [] == first[:height].errors
      assert [{"too small: must be at least %{count}", _opts}] = second[:height].errors
    end
  end
end
