class Casal < ApplicationRecord
  # Colunas da ficha de inscrição (Google Forms export / planilha espelhada):
  # ver Casais::MapeamentoInscricaoSves.

  enum :fonte_importacao, {
    manual: "manual",
    arquivo_csv: "arquivo_csv",
    planilha_google: "planilha_google",
  }, validate: true, default: :manual

  belongs_to :edicao, inverse_of: :casais
  has_many :cenaculo_casais, class_name: "CenaculoCasal", dependent: :destroy
  has_many :cenaculo_presenca_reunioes, dependent: :destroy
  has_many :cenaculos, through: :cenaculo_casais

  before_save lambda {
    self.email_contato = email_contato&.strip&.downcase.presence
  }

  validates :email_contato,
            uniqueness: { scope: :edicao_id, allow_blank: true }

  def recalcular_assinatura_linha!
    self.assinatura_linha = Casais::MapeamentoInscricaoSves.assinatura_linha(
      edicao_id: edicao_id,
      nome_completo_ele: nome_completo_ele,
      nome_completo_ela: nome_completo_ela,
      inscrito_em: inscrito_em.presence || Time.current,
    )
  end
end
