# frozen_string_literal: true

require "test_helper"

class ContentModerationTest < ActiveSupport::TestCase
  test "detects a banned word case-insensitively" do
    assert_equal [ "hitler" ], ContentModeration.scan("A glowing post about Hitler")
    refute ContentModeration.clean?("praising Hitler")
  end

  test "matches on word boundaries to avoid false positives" do
    assert_empty ContentModeration.scan("My class covered an assignment about passages")
    assert ContentModeration.clean?("class assignment passage")
  end

  test "matches multi-word phrases" do
    assert_includes ContentModeration.scan("they shouted Heil Hitler"), "heil hitler"
  end

  test "clean text returns no matches" do
    assert_empty ContentModeration.scan("A friendly post about gardening and tea")
    assert ContentModeration.clean?("gardening and tea")
  end

  test "blank input is treated as clean" do
    assert_empty ContentModeration.scan(nil)
    assert_empty ContentModeration.scan("")
  end

  test "flags disposable email domains" do
    assert ContentModeration.disposable_email?("someone@yopmail.com")
    assert ContentModeration.disposable_email?("USER@Mailinator.com")
  end

  test "allows ordinary email domains" do
    refute ContentModeration.disposable_email?("someone@gmail.com")
    refute ContentModeration.disposable_email?("hi@my-company.io")
    refute ContentModeration.disposable_email?("")
  end
end
