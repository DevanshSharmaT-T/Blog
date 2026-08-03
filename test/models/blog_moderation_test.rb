# frozen_string_literal: true

require "test_helper"

class BlogModerationTest < ActiveSupport::TestCase
  setup do
    @author = User.create!(name: "Author One", username: "author-one",
                           email: "author@example.com", password: "password123", role: :user)
    @admin  = User.create!(name: "Admin One", username: "admin-one",
                           email: "admin@example.com", password: "password123", role: :admin)
  end

  test "a clean blog stays clean" do
    blog = @author.blogs.create!(title: "Gardening tips", content: "Water your plants.")
    assert blog.moderation_clean?
    assert_nil blog.moderation_flagged_terms
  end

  test "banned content flags the blog and records the terms" do
    blog = @author.blogs.create!(title: "Why Hitler was great", content: "An essay")
    assert blog.moderation_flagged?
    assert_includes blog.moderation_flagged_terms, "hitler"
  end

  test "a flagged blog cannot be published" do
    blog = @author.blogs.create!(title: "Praising Hitler", content: "Body text here")
    blog.status = :published
    refute blog.valid?
    assert blog.errors[:base].any? { |m| m.include?("flagged content") }
  end

  test "admin approval lets the author publish" do
    blog = @author.blogs.create!(title: "Praising Hitler", content: "Body text here")
    blog.approve_moderation!(by: @admin)
    assert blog.moderation_approved?
    assert_equal @admin, blog.moderated_by

    assert_nothing_raised { blog.publish! }
    assert blog.published_status?
  end

  test "editing flagged words back out clears the flag" do
    blog = @author.blogs.create!(title: "Praising Hitler", content: "Body")
    assert blog.moderation_flagged?
    blog.update!(title: "Praising gardening")
    assert blog.moderation_clean?
  end

  test "editing an approved blog's content re-scans and can re-flag" do
    blog = @author.blogs.create!(title: "Clean title", content: "Body")
    blog.approve_moderation!(by: @admin)
    blog.update!(content: "Now mentions Hitler")
    assert blog.moderation_flagged?
    assert_nil blog.moderated_by_id
  end
end
