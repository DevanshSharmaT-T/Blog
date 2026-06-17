# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new(role: :visitor)

    case user.role
    when "owner"
      owner_abilities(user)
    when "admin"
      admin_abilities(user)
    when "user"
      user_abilities(user)
    else
      visitor_abilities
    end
  end

  private

  def owner_abilities(user)
    # Owner gets everything
    can :manage, :all
  end

  def admin_abilities(user)
    # Admin manages blogs and users — no billing/integrations/webhooks
    can :manage, Blog
    can :moderate, Blog
    can :manage, Topic
    can :manage, Template
    can :read,   BlogAnalytic
    can :read,   SocialPlatform

    # Users: read, update, toggle active, change role, manage email verification,
    # resend confirmation / password reset (owner-promotion blocked in controller).
    # Delete + restore stay owner-only (default-deny covers :restore).
    can [ :index, :show, :update, :toggle_active, :change_role,
          :verify, :unverify, :resend_confirmation, :send_password_reset ], User
    cannot :destroy, User

    # Own profile
    can [ :read, :update ], User, id: user.id
    can :manage, UserSocial, user_id: user.id
  end

  def user_abilities(user)
    # Can manage own blogs only
    can :create, Blog
    can [ :read, :update, :destroy ], Blog, author_id: user.id
    can :publish,  Blog, author_id: user.id
    can :schedule, Blog, author_id: user.id
    can :archive,  Blog, author_id: user.id

    can :read, Topic
    can :read, Template
    can :read, SocialPlatform

    # Own images
    can :create, Image
    can [ :read, :destroy ], Image, uploaded_by_id: user.id

    # Own analytics (read only)
    can :read, BlogAnalytic, blog: { author_id: user.id }

    # Own profile and socials
    can [ :read, :update ], User, id: user.id
    can :manage, UserSocial, user_id: user.id
  end

  def visitor_abilities
    can :read, Blog, status: "published", deleted_at: nil
    can :read, Topic
    can :read, Template
    can :read, SocialPlatform
  end
end
