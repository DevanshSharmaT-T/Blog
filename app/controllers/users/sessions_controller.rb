# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def after_sign_in_path_for(resource)
      resource.owner_role? || resource.admin_role? ? dashboard_path : blogs_path
    end

    def after_sign_out_path_for(_resource_or_scope)
      root_path
    end

    # Update last_login_at on successful sign-in
    def create
      super do |resource|
        resource.update_column(:last_login_at, Time.current) if resource.persisted?
      end
    end
  end
end
