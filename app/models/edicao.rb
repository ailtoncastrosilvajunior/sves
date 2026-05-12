class Edicao < ApplicationRecord
  has_many :casais, class_name: "Casal", inverse_of: :edicao, dependent: :destroy
  has_many :cenaculos, dependent: :destroy
  has_many :edicao_reuniao_cenaculos, dependent: :destroy
  has_many :equipe_servos, class_name: "EquipeServo", dependent: :destroy

  scope :em_curso, -> { where(ativa: true) }

  validates :ano, presence: true
  validates :numero_edicao, presence: true
  validates :ano, uniqueness: { scope: :numero_edicao }

  before_save :desativar_outras_se_esta_marcada_como_em_curso,
              if: -> { ativa? && (ativa_changed? || new_record?) }

  def rotulo
    "#{ano} · n.º #{numero_edicao}"
  end

  def rotulo_curto
    "#{ano}.#{numero_edicao}"
  end

  def equipes_com_composicao_count
    equipe_servos.distinct.count(:equipe_id)
  end

  def self.em_curso_primaria
    em_curso.first
  end

  private

  def desativar_outras_se_esta_marcada_como_em_curso
    if id.present?
      Edicao.where.not(id: id).update_all(ativa: false)
    else
      Edicao.update_all(ativa: false)
    end
  end
end
