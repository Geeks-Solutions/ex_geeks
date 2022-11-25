defmodule ExGeeksWeb.EmailView do
  use ExGeeksWeb, :view

  def safe_render(template, assigns \\ %{})

  def safe_render(template, assigns) when not is_map(assigns) do
    safe_render(template, Enum.into(assigns, %{}))
  end

  def safe_render(template, assigns) do
    case safe_render(template, assigns) do
      {:safe, rendered_html} ->
        rendered_html

      _ ->
        ""
    end
  end

  def render_to_string(template, assigns \\ []) do
    render_to_string(ExGeeksWeb.EmailView, template, assigns)
  end
end
