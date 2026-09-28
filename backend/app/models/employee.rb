class Employee < ApplicationRecord
  EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  enum :employment_status, { active: 'active', inactive: 'inactive', terminated: 'terminated' }, default: 'active'

  before_validation :normalize_email

  validates :full_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: EMAIL_FORMAT }
  validates :job_title, presence: true
  validates :country, presence: true
  validates :salary, presence: true, numericality: { greater_than: 0 }
  validates :employment_status, presence: true, inclusion: { in: %w[active inactive terminated] }

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
