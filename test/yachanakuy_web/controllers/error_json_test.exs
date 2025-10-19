defmodule YachanakuyWeb.ErrorJSONTest do
  use YachanakuyWeb.ConnCase, async: true

  test "renders 404" do
    assert YachanakuyWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert YachanakuyWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
