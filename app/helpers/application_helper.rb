module ApplicationHelper
  PUBLIC_PAGES = {
    "pages" => :any,
    "blogs" => %w[show archive feed],
    "public_profiles" => :any
  }.freeze

  def public_page?
    actions = PUBLIC_PAGES[controller_name]
    return false if actions.nil?
    actions == :any || actions.include?(action_name)
  end

  def current_theme
    cookies[:theme].presence || "light"
  end

  # True when the authenticated dashboard sidebar is rendered for this request.
  def sidebar_visible?
    user_signed_in? && !devise_controller? && !public_page?
  end
end
