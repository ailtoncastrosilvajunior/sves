# Cenáculo: grupo de casais participantes da edição, com servos em papel de pastor (cenaculo_servos).
class Cenaculo < ApplicationRecord
  belongs_to :edicao
  has_one_attached :imagem

  has_many :cenaculo_servos, class_name: "CenaculoServo", dependent: :destroy
  has_many :servos, through: :cenaculo_servos # pastores deste cenáculo
  has_many :cenaculo_casais, class_name: "CenaculoCasal", dependent: :destroy
  has_many :cenaculo_presenca_reunioes, dependent: :destroy
  # +source+: sem isto o Inflector inglês faz +casais+ → «casai», que não existe no join.
  has_many :casais, through: :cenaculo_casais, source: :casal

  HEX_COR = /\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})\z/.freeze

  # Rótulos curtos (tom predominante) — formulário e impressão da equipe.
  PALETA_CORES = [
    ["Verde", "#1b4332"],
    ["Verde", "#2d6a4f"],
    ["Verde", "#40916c"],
    ["Turquesa", "#2a9d8f"],
    ["Azul", "#264653"],
    ["Roxo", "#6d597a"],
    ["Amarelo", "#e9c46a"],
    ["Laranja", "#f4a261"],
    ["Laranja", "#e76f51"],
    ["Azul", "#355070"],
    ["Rosa", "#b56576"],
    ["Cinzento", "#6c757d"],
    ["Cinzento", "#343a40"],
    ["Preto", "#212529"],
  ].freeze

  def self.normalizar_hex_cor(valor)
    raw = valor.to_s.strip
    return nil unless raw.present? && raw.match?(HEX_COR)

    h = raw.delete_prefix("#").downcase
    h = h.chars.map { |c| c * 2 }.join if h.length == 3

    "##{h}"
  end

  PALETA_ROTULO_POR_HEX = PALETA_CORES.each_with_object({}) do |(rotulo, hex), memo|
    nh = normalizar_hex_cor(hex)
    memo[nh] = rotulo if nh
  end.freeze

  def self.rotulo_cor_na_paleta(hex_normalizado)
    return nil if hex_normalizado.blank?

    PALETA_ROTULO_POR_HEX[hex_normalizado]
  end

  validates :nome, presence: true
  validates :nome, uniqueness: { scope: :edicao_id }
  validates :cor, format: { with: HEX_COR, message: "deve ser #RGB ou #RRGGBB" }, allow_blank: true
  validates :pastores_texto_livre, length: { maximum: 50 }, allow_blank: true

  normalizes :pastores_texto_livre, with: ->(raw) { raw.to_s.strip.presence }
end
