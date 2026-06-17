# frozen_string_literal: true

require "test_helper"

class BlogModerationFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # Routes are loaded lazily; force them so Devise.mappings is populated before
    # `sign_in` (which needs the mapping to resolve the warden scope).
    Rails.application.reload_routes_unless_loaded

    @author = User.create!(name: "Author Two", username: "author-two",
                           email: "author2@example.com", password: "password123",
                           role: :user, confirmed_at: Time.current)
    @admin  = User.create!(name: "Admin Two", username: "admin-two",
                           email: "admin2@example.com", password: "password123",
                           role: :admin, confirmed_at: Time.current)
    @flagged = @author.blogs.create!(title: "Praising Hitler", content: "Body text")
  end

  test "a regular user cannot approve moderation" do
    sign_in @author
    patch approve_moderation_blog_path(@flagged)
    assert @flagged.reload.moderation_flagged?, "should remain flagged"
  end

  test "an admin can approve a flagged blog" do
    sign_in @admin
    patch approve_moderation_blog_path(@flagged)
    @flagged.reload
    assert @flagged.moderation_approved?
    assert_equal @admin.id, @flagged.moderated_by_id
  end

  test "moderation queue is visible to admins" do
    sign_in @admin
    get moderation_queue_blogs_path
    assert_response :success
    assert_match @flagged.title, response.body
  end
end
