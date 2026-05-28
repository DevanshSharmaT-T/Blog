# frozen_string_literal: true

module Users
  class ConfirmationsController < Devise::ConfirmationsController
    def after_confirmation_path_for(resource_name, resource)
      sign_in(resource)
      resource.owner_role? || resource.admin_role? ? dashboard_path : blogs_path
    end
  end
end
