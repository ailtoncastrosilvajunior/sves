class Equipe < ApplicationRecord
  has_many :equipe_servos, class_name: "EquipeServo", dependent: :destroy
  has_many :servos, -> { distinct }, through: :equipe_servos

  validates :nome, presence: true
  validates :nome, uniqueness: true

  def servidor_ids_na_edicao(edicao)
    equipe_servos.where(edicao: edicao).distinct.pluck(:servo_id)
  end
end
