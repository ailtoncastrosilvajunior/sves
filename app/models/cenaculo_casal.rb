class CenaculoCasal < ApplicationRecord
  self.table_name = "cenaculo_casais"

  belongs_to :cenaculo
  belongs_to :casal, class_name: "Casal", inverse_of: :cenaculo_casais

  validates :casal_id, uniqueness: { scope: :cenaculo_id }
  validate :casal_na_mesma_edicao_do_cenaculo
  validate :casal_sem_segundo_grupo_na_mesma_edicao, on: :create

  private

  def casal_sem_segundo_grupo_na_mesma_edicao
    return if casal_id.blank? || cenaculo.blank?

    ocupado_em_outro = CenaculoCasal
      .joins(:cenaculo)
      .exists?(cenaculos: { edicao_id: cenaculo.edicao_id }, casal_id: casal_id)

    return unless ocupado_em_outro

    errors.add(:casal_id, "já integra um cenáculo nesta edição — retire o casal desse grupo antes de o mover para aqui")
  end

  def casal_na_mesma_edicao_do_cenaculo
    return if casal.blank? || cenaculo.blank?
    return if casal.edicao_id == cenaculo.edicao_id

    errors.add(:casal_id, "tem de pertencer à mesma edição deste cenáculo")
  end
end
