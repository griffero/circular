# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Circular <noreply@circular.app>")
  layout "mailer"
end
