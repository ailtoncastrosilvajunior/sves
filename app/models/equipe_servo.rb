class EquipeServo < ApplicationRecord
  self.table_name = "equipe_servos"

  enum :forma, { coordenacao: 0, participante: 1 }

  belongs_to :edicao
  belongs_to :equipe
  belongs_to :servo

  validates :forma, presence: true
  validates :servo_id, uniqueness: { scope: %i[equipe_id edicao_id] }
end
