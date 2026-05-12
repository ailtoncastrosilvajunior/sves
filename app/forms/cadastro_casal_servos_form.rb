# frozen_string_literal: true

# Formulário público: cadastro de casal (dois servos, duas contas de acesso).
class CadastroCasalServosForm
  include ActiveModel::Model

  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "CadastroCasal")
    end

    def participante_param_keys
      Participante::ATTRIBUTES
    end
  end

  class Participante
    include ActiveModel::Model

    ATTRIBUTES = %i[nome email telefone password password_confirmation].freeze

    attr_accessor(*ATTRIBUTES)

    validates :nome, presence: true
    validates :email, presence: true,
                      format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
    validates :password, presence: true, confirmation: true,
                         length: { minimum: 8, allow_blank: true }
  end

  attr_reader :dele, :dela

  attr_accessor :grupo_de_oracao

  validates :grupo_de_oracao, presence: true

  validate :validar_participantes
  validate :emails_distintos_normalizados
  validate :emails_sem_conta_existente
  validate :servos_sem_conta_ja_associada

  def initialize(attributes = {})
    attrs = attributes.to_h.deep_symbolize_keys
    @grupo_de_oracao = attrs[:grupo_de_oracao].to_s
    @dele = Participante.new((attrs[:dele] || {}).to_h.symbolize_keys.slice(*Participante::ATTRIBUTES))
    @dela = Participante.new((attrs[:dela] || {}).to_h.symbolize_keys.slice(*Participante::ATTRIBUTES))
  end

  def save
    return false unless valid?

    resultado = false
    Servo.transaction do
      resultado = persist_pair!
      raise ActiveRecord::Rollback unless resultado
    end
    resultado
  end

  private

  def validar_participantes
    unless @dele.valid?
      @dele.errors.each { |err| errors.add(:base, "#{I18n.t('cadastro_servos.lado_dele')}: #{err.full_message}") }
    end
    unless @dela.valid?
      @dela.errors.each { |err| errors.add(:base, "#{I18n.t('cadastro_servos.lado_dela')}: #{err.full_message}") }
    end
  end

  def emails_distintos_normalizados
    a = User.normalize_email(@dele.email)
    b = User.normalize_email(@dela.email)
    return if a.blank? || b.blank?

    errors.add(:base, I18n.t("cadastro_servos.emails_iguais")) if a == b
  end

  def emails_sem_conta_existente
    [@dele, @dela].each do |p|
      email_norm = User.normalize_email(p.email)
      next if email_norm.blank?

      if User.where(email: email_norm).exists?
        errors.add(:base, I18n.t("cadastro_servos.ja_conta_user", email: p.email.strip))
      end
    end
  end

  def servos_sem_conta_ja_associada
    [@dele, @dela].each do |p|
      email_norm = User.normalize_email(p.email)
      next if email_norm.blank?

      servo = Servo.find_by_normalized_email(email_norm)
      next unless servo&.user_id.present?

      errors.add(:base, I18n.t("cadastro_servos.ja_tem_acesso_email", email: p.email.strip))
    end
  end

  def persist_pair!
    user_dele = build_user(@dele)
    return false unless save_user_propagating_errors!(user_dele, lado: :dele)

    user_dela = build_user(@dela)
    return false unless save_user_propagating_errors!(user_dela, lado: :dela)

    servo_dele = build_servo(@dele, user_dele, sexo: "M")
    return false unless save_servo_propagating_errors!(servo_dele, lado: :dele)

    servo_dela = build_servo(@dela, user_dela, sexo: "F")
    return false unless save_servo_propagating_errors!(servo_dela, lado: :dela)

    unless link_conjuges!(servo_dele, servo_dela)
      return false
    end

    true
  end

  def build_user(participante)
    email_norm = User.normalize_email(participante.email)
    User.new(
      email: email_norm,
      password: participante.password,
      password_confirmation: participante.password_confirmation,
      must_change_password: true
    )
  end

  def build_servo(participante, user, sexo:)
    email_norm = User.normalize_email(participante.email)
    servo = Servo.find_by_normalized_email(email_norm) || Servo.new(origem_cadastro: Servo::ORIGEM_PUBLICO, papel: Servo::PAPEL_PARTICIPANTE)

    servo.assign_attributes(
      nome: participante.nome.to_s.strip,
      sexo: sexo,
      telefone: participante.telefone.to_s.strip.presence,
      email: email_norm,
      grupo_de_oracao: grupo_de_oracao.to_s.strip,
      conjuge_id: nil,
      user: user,
      origem_cadastro: Servo::ORIGEM_PUBLICO,
      papel: Servo::PAPEL_PARTICIPANTE
    )
    servo
  end

  def save_user_propagating_errors!(user, lado:)
    return true if user.save

    lado_label = (lado == :dele) ? I18n.t("cadastro_servos.lado_dele") : I18n.t("cadastro_servos.lado_dela")
    user.errors.each do |err|
      errors.add(:base, "#{lado_label} (#{User.model_name.human}): #{err.full_message}")
    end
    false
  end

  def save_servo_propagating_errors!(servo, lado:)
    return true if servo.save

    lado_label = (lado == :dele) ? I18n.t("cadastro_servos.lado_dele") : I18n.t("cadastro_servos.lado_dela")
    servo.errors.each do |err|
      errors.add(:base, "#{lado_label} (#{Servo.model_name.human}): #{err.full_message}")
    end
    false
  end

  def link_conjuges!(a, b)
    unless a.update(conjuge: b)
      append_link_errors(I18n.t("cadastro_servos.erro_vinculo_conjuge"), a)
      return false
    end
    unless b.update(conjuge: a)
      append_link_errors(I18n.t("cadastro_servos.erro_vinculo_conjuge"), b)
      return false
    end
    true
  end

  def append_link_errors(prefixo, servo)
    servo.errors.each do |err|
      errors.add(:base, "#{prefixo}: #{err.full_message}")
    end
  end
end
