# frozen_string_literal: true

class UsersController < ApplicationController
  MEMBER_ACTIONS = %i[show update destroy toggle_active change_role
                      verify unverify restore resend_confirmation send_password_reset].freeze

  # Member actions that change account state — guarded against self-targeting and
  # against a non-owner touching an owner.
  GUARDED_ACTIONS = %i[toggle_active change_role verify unverify restore destroy
                       resend_confirmation send_password_reset].freeze

  before_action :authenticate_user!
  before_action :set_user, only: MEMBER_ACTIONS
  before_action :guard_target!, only: GUARDED_ACTIONS
  before_action :enforce_role_scope!, only: [ :change_role ]
  authorize_resource

  ROLE_OPTIONS = %w[owner admin user visitor].freeze

  def index
    authorize! :index, User
    scope = case params[:status]
            when "deleted"    then User.deleted
            when "unverified" then User.not_deleted.unverified
            else                   User.not_deleted
            end
    @status = params[:status]
    @q      = scope.ransack(params[:q])
    @pagy, @users = pagy(@q.result.order(created_at: :desc), items: 25)
  end

  def show
    @blogs = @user.blogs.not_deleted.recent.limit(10)
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), notice: "User updated."
    else
      @blogs = @user.blogs.not_deleted.recent.limit(10)
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @user.soft_delete!
    redirect_to users_path, notice: "User deactivated."
  end

  def toggle_active
    @user.update!(is_active: !@user.is_active)
    redirect_back fallback_location: users_path,
                  notice: "User #{@user.is_active ? 'activated' : 'deactivated'}."
  end

  def change_role
    @user.update!(role: params[:role])
    redirect_back fallback_location: users_path,
                  notice: "Role updated to #{params[:role]}."
  end

  def verify
    @user.verify!
    redirect_back fallback_location: users_path, notice: "#{@user.name} marked as verified."
  end

  def unverify
    @user.unverify!
    redirect_back fallback_location: users_path, notice: "#{@user.name} marked as unverified."
  end

  def restore
    @user.restore!
    redirect_back fallback_location: users_path, notice: "#{@user.name} restored."
  end

  def resend_confirmation
    @user.send_confirmation_instructions
    redirect_back fallback_location: users_path, notice: "Confirmation email sent to #{@user.email}."
  end

  def send_password_reset
    @user.send_reset_password_instructions
    redirect_back fallback_location: users_path, notice: "Password reset email sent to #{@user.email}."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # Self-targeting and owner-protection guard shared by the state-changing member
  # actions. Destructive actions may never target yourself; only an owner may act
  # on another owner.
  def guard_target!
    destructive = %w[toggle_active unverify destroy].include?(action_name)
    if destructive && @user == current_user
      redirect_back fallback_location: users_path,
                    alert: "You can't perform that action on your own account." and return
    end
    if @user.owner_role? && !current_user.owner_role?
      redirect_back fallback_location: users_path,
                    alert: "Only an owner can manage an owner account." and return
    end
  end

  def user_params
    params.require(:user).permit(:name, :bio, :website_url, :avatar_url)
  end

  # Admins may not promote anyone to :owner; only an owner may.
  def enforce_role_scope!
    requested = params[:role].to_s
    unless ROLE_OPTIONS.include?(requested)
      redirect_back fallback_location: users_path, alert: "Invalid role." and return
    end
    if requested == "owner" && !current_user.owner_role?
      redirect_back fallback_location: users_path, alert: "Only an owner can grant the owner role." and return
    end
    if @user.owner_role? && !current_user.owner_role?
      redirect_back fallback_location: users_path, alert: "Only an owner can change an owner's role." and return
    end
  end
end
