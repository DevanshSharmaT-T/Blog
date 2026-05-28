# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :update, :destroy, :toggle_active, :change_role ]
  before_action :enforce_role_scope!, only: [ :change_role ]
  authorize_resource

  ROLE_OPTIONS = %w[owner admin user visitor].freeze

  def index
    authorize! :index, User
    scope = User.not_deleted
    @q    = scope.ransack(params[:q])
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

  private

  def set_user
    @user = User.find(params[:id])
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
