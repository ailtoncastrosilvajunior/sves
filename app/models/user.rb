class User < ApplicationRecord
  # Só formulário: confirmação da senha actual em «alterar senha» voluntário.
  attr_accessor :current_password

  has_secure_password

  normalizes :email, with: ->(e) { e.to_s.strip.downcase }

  has_one :servo, inverse_of: :user, dependent: :nullify

  # Conta com privilégios de plataforma (regras futuras: apenas admin).
  scope :admins, -> { where(admin: true) }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  def self.normalize_email(value)
    value.to_s.strip.downcase
  end

  validates :password, length: { minimum: 8 }, if: -> { password.present? }
end
