defmodule IgamingRef.Web.ErrorView do
  @moduledoc """
  Renders HTTP error responses for the iGaming application.

  Provides standardized error pages for different HTTP status codes (500, 4xx, etc.).
  """
  use Phoenix.View,
    root: "lib/igaming_ref/web/templates",
    namespace: IgamingRef.Web

  def render("500.html", _assigns) do
    "Internal Server Error"
  end

  def render(_template, _assigns) do
    "Error"
  end
end
