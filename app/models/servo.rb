class Servo < ApplicationRecord
  # Formulário: «dar acesso» não persiste; só indica criação de User em ServosController.
  attr_accessor :dar_acesso

  ORIGEM_PAINEL = "painel"
  ORIGEM_PUBLICO = "publico"
  ORIGEM_IMPORTACAO = "importacao"
  ORIGENS = [ORIGEM_PAINEL, ORIGEM_PUBLICO, ORIGEM_IMPORTACAO].freeze

  PAPEL_COORDENACAO = "coordenacao"
  PAPEL_PARTICIPANTE = "participante"
  PAPEIS = [PAPEL_COORDENACAO, PAPEL_PARTICIPANTE].freeze

  belongs_to :user, optional: true
  belongs_to :conjuge, class_name: "Servo", optional: true

  has_many :equipe_servos, class_name: "EquipeServo", dependent: :destroy
  has_many :equipes, -> { distinct }, through: :equipe_servos
  has_many :cenaculo_servos, class_name: "CenaculoServo", dependent: :destroy
  has_many :cenaculos, through: :cenaculo_servos

  has_one :parceiro_conjuge, class_name: "Servo", foreign_key: :conjuge_id, dependent: :nullify,
          inverse_of: :conjuge

  SEXOS = %w[M F].freeze

  # Servos com papel de pastor de cenáculo nesta edição (cenaculo_servos).
  # Conceito pastoral: cenáculo = casais participantes + pastores daquele grupo.
  scope :pastores_de_cenaculo_na_edicao, lambda { |edicao|
    joins(cenaculo_servos: :cenaculo).where(cenaculos: { edicao_id: edicao.id }).distinct
  }

  scope :aguardando_acesso_ao_painel, -> { where(user_id: nil).where.not(email: [nil, ""]) }

  def coordenacao?
    papel == PAPEL_COORDENACAO
  end

  def participante?
    papel == PAPEL_PARTICIPANTE
  end

  def self.find_by_normalized_email(raw)
    e = User.normalize_email(raw)
    return nil if e.blank?

    where("email IS NOT NULL AND LOWER(TRIM(BOTH FROM email)) = ?", e).first
  end

  def self.ids_do_casal_incluindo(servo)
    [servo.id, servo.conjuge_id, servo.parceiro_conjuge&.id].compact.uniq
  end

  validates :nome, presence: true
  validates :sexo, inclusion: { in: SEXOS, allow_blank: true }
  validates :user_id, uniqueness: { allow_nil: true }
  validates :origem_cadastro, inclusion: { in: ORIGENS }
  validates :papel, inclusion: { in: PAPEIS }
  validate :conjuge_distinto_do_proprio_servo

  before_validation :normalizar_sexo
  before_validation :definir_papel_padrao

  before_save lambda {
    self.email = email&.strip&.presence
    self.telefone = telefone&.strip&.presence
    self.telefone = nil if telefone.blank?
  }

  # Cria ou atualiza User com senha inicial e obriga troca no primeiro login.
  # @return [Boolean]
  def liberar_acesso_senha_padrao!(raw_password)
    errors.clear
    if user_id.present?
      errors.add(:base, I18n.t("servos.liberar_ja_tem_acesso"))
      return false
    end

    email_norm = User.normalize_email(email)
    if email_norm.blank?
      errors.add(:email, I18n.t("errors.messages.blank"))
      return false
    end

    sucesso = false
    Servo.transaction do
      utilizador = User.find_by(email: email_norm)

      if utilizador
        if utilizador.servo.present? && utilizador.servo.id != id
          errors.add(:base, I18n.t("servos.liberar_email_ligado_outro_servo"))
          raise ActiveRecord::Rollback
        end

        utilizador.password = raw_password
        utilizador.password_confirmation = raw_password
        utilizador.must_change_password = true
        unless utilizador.save
          copiar_erros_utilizador(utilizador)
          raise ActiveRecord::Rollback
        end

        update!(user: utilizador)
      else
        utilizador = User.new(
          email: email_norm,
          password: raw_password,
          password_confirmation: raw_password,
          must_change_password: true
        )
        unless utilizador.save
          copiar_erros_utilizador(utilizador)
          raise ActiveRecord::Rollback
        end

        update!(user: utilizador)
      end

      sucesso = true
    end

    sucesso
  end

  # Coordenação redefine senha de participante que já tem conta (ex.: esqueceu a senha).
  # @return [Boolean]
  def coordenacao_redefinir_senha_padrao_participante!(raw_password)
    errors.clear

    if user_id.blank?
      errors.add(:base, I18n.t("servos.redefinir_sem_conta"))
      return false
    end

    unless participante?
      errors.add(:base, I18n.t("servos.redefinir_so_participante"))
      return false
    end

    if user.admin?
      errors.add(:base, I18n.t("servos.redefinir_nao_admin_alvo"))
      return false
    end

    u = user
    u.password = raw_password
    u.password_confirmation = raw_password
    u.must_change_password = true

    if u.save
      true
    else
      copiar_erros_utilizador(u)
      false
    end
  end

  private

  def copiar_erros_utilizador(utilizador)
    utilizador.errors.each do |err|
      errors.add(:base, err.full_message)
    end
  end

  def normalizar_sexo
    self.sexo = nil if sexo.present? && !SEXOS.include?(sexo)
  end

  def definir_papel_padrao
    if origem_cadastro == ORIGEM_PUBLICO
      self.papel = PAPEL_PARTICIPANTE
    elsif papel.blank?
      self.papel = PAPEL_COORDENACAO
    end
  end

  def conjuge_distinto_do_proprio_servo
    return unless conjuge_id.present? && conjuge_id == id

    errors.add(:conjuge_id, :invalid)
  end
end
