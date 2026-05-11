# frozen_string_literal: true

# Material editorial global (todas as edições), opcionalmente fora do ar via +ativo+.
class MaterialApoio < ApplicationRecord
  self.table_name = "material_apoios"

  MAX_BYTES = 30.megabytes
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.oasis.opendocument.text
  ].freeze
  ALLOWED_EXTENSIONS = %w[.pdf .doc .docx .odt].freeze

  has_one_attached :arquivo

  scope :ativos, -> { where(ativo: true) }
  scope :listagem, -> { order(ordem: :asc, titulo: :asc) }

  validates :titulo, presence: true, length: { maximum: 255 }
  validates :ordem, numericality: { only_integer: true }
  validate :precisa_arquivo_anexado
  validate :arquivo_tipagem

  before_validation -> { titulo&.strip! }

  def arquivo_baixavel?
    arquivo.attached?
  end

  private

  def precisa_arquivo_anexado
    errors.add(:arquivo, :blank) unless arquivo.attached?
  end

  def arquivo_tipagem
    return unless arquivo.attached?

    blob = arquivo.blob

    tipo_ok = ALLOWED_EXTENSIONS.include?(File.extname(blob.filename.to_s).downcase) ||
              ALLOWED_CONTENT_TYPES.include?(blob.content_type.to_s)

    unless tipo_ok
      errors.add(:arquivo, I18n.t("material_apoio.errors.arquivo_tipos"))
    end

    return unless blob.byte_size
    return unless blob.byte_size > MAX_BYTES

    errors.add(:arquivo,
               I18n.t("material_apoio.errors.arquivo_tamanho", max_mb: (MAX_BYTES / 1.megabyte).to_i))
  end
end
