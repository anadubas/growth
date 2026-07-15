defmodule GrowthWeb.LiveCase do
  @moduledoc """
  This module defines the test case to be used by test that require setting up liveview.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint GrowthWeb.Endpoint
      use GrowthWeb, :verified_routes
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import GrowthWeb.LiveCase
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
