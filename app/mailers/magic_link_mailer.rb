# frozen_string_literal: true

class MagicLinkMailer < ApplicationMailer
  def magic_link_email(user, token)
    @user = user
    @token = token
    @magic_link_url = "#{frontend_url}/auth/verify?token=#{token}"

    mail(
      to: user.email,
      subject: "Sign in to Circular"
    )
  end

  private

  def frontend_url
    ENV.fetch("FRONTEND_URL", "http://localhost:5173")
  end
end
