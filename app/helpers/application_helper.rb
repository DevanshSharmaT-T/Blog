module ApplicationHelper
  PUBLIC_PAGES = {
    "pages" => :any,
    "blogs" => %w[show archive feed]
  }.freeze

  def public_page?
    actions = PUBLIC_PAGES[controller_name]
    return false if actions.nil?
    actions == :any || actions.include?(action_name)
  end

  def current_theme
    cookies[:theme].presence || "light"
  end
end
