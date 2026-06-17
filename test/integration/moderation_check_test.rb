# frozen_string_literal: true

require "test_helper"

class ModerationCheckTest < ActionDispatch::IntegrationTest
  test "flags a disposable email for an unauthenticated visitor" do
    post moderation_check_path, params: { kind: "email", value: "x@yopmail.com" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    refute body["ok"]
    assert_equal "error", body["severity"]
  end

  test "passes a normal email" do
    post moderation_check_path, params: { kind: "email", value: "x@gmail.com" }, as: :json
    assert_response :success
    assert JSON.parse(response.body)["ok"]
  end

  test "blocks a banned username/name (text kind)" do
    post moderation_check_path, params: { kind: "text", value: "Heil Hitler" }, as: :json
    body = JSON.parse(response.body)
    refute body["ok"]
    assert_equal "error", body["severity"]
  end

  test "warns (does not hard-block) for flaggable blog content" do
    post moderation_check_path, params: { kind: "flaggable", value: "An ode to Hitler" }, as: :json
    body = JSON.parse(response.body)
    refute body["ok"]
    assert_equal "warning", body["severity"]
    assert_includes body["matches"], "hitler"
  end
end
