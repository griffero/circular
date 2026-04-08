# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(255) }
    # has_secure_password validations: false — no password validation
    it { is_expected.not_to validate_presence_of(:password) }
    it { is_expected.to validate_presence_of(:role) }
  end

  describe "associations" do
    it { is_expected.to have_many(:team_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:teams).through(:team_memberships) }
    it { is_expected.to have_many(:project_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:projects).through(:project_memberships) }
  end

  describe "#find_by_email" do
    let!(:user) { create(:user, email: "Test@Example.com") }

    it "finds user by email case-insensitively" do
      expect(described_class.find_by_email("test@example.com")).to eq(user)
      expect(described_class.find_by_email("TEST@EXAMPLE.COM")).to eq(user)
    end
  end

  describe "roles" do
    describe "#owner?" do
      it "returns true when user is an owner" do
        user = create(:user, :owner)
        expect(user.owner?).to be true
      end

      it "returns false when user is not an owner" do
        user = create(:user, :admin)
        expect(user.owner?).to be false
      end
    end

    describe "#admin?" do
      it "returns true when user is an admin" do
        user = create(:user, :admin)
        expect(user.admin?).to be true
      end

      it "returns true when user is an owner" do
        user = create(:user, :owner)
        expect(user.admin?).to be true
      end

      it "returns false when user is a member" do
        user = create(:user)
        expect(user.admin?).to be false
      end
    end

    describe "#can_manage_users?" do
      it "returns true for admins" do
        user = create(:user, :admin)
        expect(user.can_manage_users?).to be true
      end

      it "returns false for members" do
        user = create(:user)
        expect(user.can_manage_users?).to be false
      end
    end
  end

  describe "first user becomes owner" do
    it "first user gets owner role via signup logic" do
      # This is tested in auth_spec, the model itself doesn't enforce this
      user = create(:user)
      expect(user.role).to eq("member")
    end
  end
end
