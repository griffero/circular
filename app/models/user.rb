# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password validations: false

  # Direct associations (single-tenant)
  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_many :led_projects, class_name: "Project", foreign_key: :lead_id, dependent: :nullify, inverse_of: :lead
  has_many :created_issues, class_name: "Issue", foreign_key: :creator_id, dependent: :nullify, inverse_of: :creator
  has_many :assigned_issues, class_name: "Issue", foreign_key: :assignee_id, dependent: :nullify, inverse_of: :assignee
  has_many :issue_subscriptions, dependent: :destroy
  has_many :subscribed_issues, through: :issue_subscriptions, source: :issue
  has_many :comments, dependent: :destroy
  has_many :issue_activities, dependent: :destroy

  # Roles: owner, admin, member
  enum :role, { member: "member", admin: "admin", owner: "owner" }, default: :member

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :role, presence: true

  before_save :downcase_email

  scope :by_email, ->(email) { where("LOWER(email) = ?", email.downcase) }
  scope :admins, -> { where(role: %w[owner admin]) }
  scope :owners, -> { where(role: "owner") }

  # Magic Link token expiration time
  MAGIC_LINK_EXPIRATION = 15.minutes

  def self.find_by_email(email)
    by_email(email).first
  end

  # Generate magic link token
  def generate_magic_link_token!
    loop do
      self.magic_link_token = SecureRandom.urlsafe_base64(32)
      break unless User.exists?(magic_link_token: magic_link_token)
    end
    self.magic_link_sent_at = Time.current
    save!
    magic_link_token
  end

  # Verify magic link token
  def self.find_by_magic_link_token(token)
    return nil if token.blank?

    user = find_by(magic_link_token: token)
    return nil unless user
    return nil if user.magic_link_expired?

    user
  end

  def magic_link_expired?
    magic_link_sent_at.nil? || magic_link_sent_at < MAGIC_LINK_EXPIRATION.ago
  end

  def clear_magic_link_token!
    update!(magic_link_token: nil, magic_link_sent_at: nil)
  end

  # Single-tenant role checks
  def owner?
    role == "owner"
  end

  def admin?
    role.in?(%w[owner admin])
  end

  def can_manage_users?
    admin?
  end

  def can_manage_teams?
    admin?
  end

  def can_manage_settings?
    admin?
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
