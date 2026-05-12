# frozen_string_literal: true

# Presença de cada membro do casal numa reunião de cenáculo da edição.
class CenaculoPresencaReuniao < ApplicationRecord
  belongs_to :edicao_reuniao_cenaculo
  belongs_to :cenaculo
  belongs_to :casal

  validates :casal_id, uniqueness: { scope: :edicao_reuniao_cenaculo_id }
  validate :casal_membro_do_cenaculo
  validate :mesma_edicao_reuniao_e_cenaculo

  private

  def casal_membro_do_cenaculo
    return if cenaculo.blank? || casal.blank?

    unless cenaculo.casais.exists?(casal.id)
      errors.add(:casal_id, "não pertence a este cenáculo")
    end
  end

  def mesma_edicao_reuniao_e_cenaculo
    return if edicao_reuniao_cenaculo.blank? || cenaculo.blank?

    unless edicao_reuniao_cenaculo.edicao_id == cenaculo.edicao_id
      errors.add(:base, "reunião e cenáculo têm de ser da mesma edição")
    end
  end
end
