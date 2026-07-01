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

  test "asset-like request returns a real 404 instead of redirecting" do
    get "/apple-touch-icon.png"
    assert_response :not_found
    assert_nil response.headers["Location"]
  end

  test "unknown path with non-GET verb returns 404 rather than a redirect" do
    post "/no-such-page-here"
    assert_response :not_found
  end

  test "favicon.ico is served statically and never hits the catch-all" do
    get "/favicon.ico"
    assert_response :success
    assert_includes [ "image/x-icon", "image/vnd.microsoft.icon" ], response.media_type
  end
end
