class Servo < ApplicationRecord
  # Formulário: «dar acesso» não persiste; só indica criação de User em ServosController.
  attr_accessor :dar_acesso

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

  def self.ids_do_casal_incluindo(servo)
    [servo.id, servo.conjuge_id, servo.parceiro_conjuge&.id].compact.uniq
  end

  validates :nome, presence: true
  validates :sexo, inclusion: { in: SEXOS, allow_blank: true }
  validates :user_id, uniqueness: { allow_nil: true }
  validate :conjuge_distinto_do_proprio_servo

  before_validation :normalizar_sexo

  before_save lambda {
    self.email = email&.strip&.presence
    self.telefone = telefone&.strip&.presence
    self.telefone = nil if telefone.blank?
  }

  private

  def normalizar_sexo
    self.sexo = nil if sexo.present? && !SEXOS.include?(sexo)
  end

  def conjuge_distinto_do_proprio_servo
    return unless conjuge_id.present? && conjuge_id == id

    errors.add(:conjuge_id, :invalid)
  end
end
