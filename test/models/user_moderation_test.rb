# frozen_string_literal: true

require "test_helper"

class UserModerationTest < ActiveSupport::TestCase
  def build_user(**attrs)
    User.new({
      name: "Jane Doe", username: "jane-doe",
      email: "jane@example.com", password: "password123",
      role: :user
    }.merge(attrs))
  end

  test "rejects a disposable email" do
    user = build_user(email: "throwaway@yopmail.com")
    refute user.valid?
    assert_includes user.errors[:email], "must be from a non-disposable provider"
  end

  test "accepts a normal email" do
    user = build_user(email: "real.person@gmail.com")
    user.valid?
    assert_empty user.errors[:email]
  end

  test "rejects a banned display name" do
    user = build_user(name: "Heil Hitler")
    refute user.valid?
    assert user.errors[:name].any? { |m| m.include?("isn't allowed") }
  end

  test "rejects a banned username" do
    user = build_user(username: "nigger")
    refute user.valid?
    assert user.errors[:username].any? { |m| m.include?("isn't allowed") }
  end

  test "accepts a clean name and username" do
    user = build_user(name: "Jane Doe", username: "jane-doe")
    user.valid?
    assert_empty user.errors[:name]
    assert_empty user.errors[:username]
  end
end
