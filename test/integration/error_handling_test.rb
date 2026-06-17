# frozen_string_literal: true

require "test_helper"

class ErrorHandlingTest < ActionDispatch::IntegrationTest
  test "unknown URL redirects an unauthenticated visitor to root" do
    get "/no-such-page-here"
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "unknown URL with deep path still redirects" do
    get "/foo/bar/baz"
    assert_redirected_to root_path
  end

  test "unknown URL returns JSON 404 for JSON requests" do
    get "/no-such-page-here", as: :json
    assert_response :not_found
    assert_equal "Not found", JSON.parse(response.body)["error"]
  end

  test "unknown API path is not swallowed by the catch-all" do
    get "/api/v1/does-not-exist"
    # Excluded from the catch-all, so it does NOT redirect to the error handler.
    assert_not_equal 302, response.status
  end
end
