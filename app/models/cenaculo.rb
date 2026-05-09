# Cenáculo: grupo de casais participantes da edição, com servos em papel de pastor (cenaculo_servos).
class Cenaculo < ApplicationRecord
  belongs_to :edicao
  has_one_attached :imagem

  has_many :cenaculo_servos, class_name: "CenaculoServo", dependent: :destroy
  has_many :servos, through: :cenaculo_servos # pastores deste cenáculo
  has_many :cenaculo_casais, class_name: "CenaculoCasal", dependent: :destroy
  # +source+: sem isto o Inflector inglês faz +casais+ → «casai», que não existe no join.
  has_many :casais, through: :cenaculo_casais, source: :casal

  HEX_COR = /\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})\z/.freeze

  validates :nome, presence: true
  validates :nome, uniqueness: { scope: :edicao_id }
  validates :cor, format: { with: HEX_COR, message: "deve ser #RGB ou #RRGGBB" }, allow_blank: true
end
