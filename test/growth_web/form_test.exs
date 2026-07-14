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
          "weight" => "10",
          "height" => "10",
          "head_circumference" => "10"
        })

      assert ctx.valid?
      assert 10 == ctx.parsed.weight
      assert 10 == ctx.parsed.height
      assert 10 == ctx.parsed.head_circumference
    end

    test "parses map with atom keys" do
      ctx =
        Form.measure_parse(%{
          weight: 20.0,
          height: 20.0,
          head_circumference: 20.0
        })

      assert ctx.valid?
      assert 20.0 == ctx.parsed.weight
      assert 20.0 == ctx.parsed.height
      assert 20.0 == ctx.parsed.head_circumference
    end

    test "validates correctly params" do
      ctx = Form.measure_parse(%{weight: "la", height: "la", head_circumference: "la"})

      refute ctx.valid?
      assert 3 == Enum.count(ctx.errors)
    end
  end
end
