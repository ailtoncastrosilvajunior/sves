class Casal < ApplicationRecord
  # Colunas da ficha de inscrição (Google Forms export / planilha espelhada):
  # ver Casais::MapeamentoInscricaoSves.

  enum :fonte_importacao, {
    arquivo_csv: "arquivo_csv",
    planilha_google: "planilha_google",
    cadastro_manual: "cadastro_manual",
  }, validate: true, default: :cadastro_manual

  belongs_to :edicao, inverse_of: :casais
  has_many :cenaculo_casais, class_name: "CenaculoCasal", dependent: :destroy
  has_many :cenaculo_presenca_reunioes, dependent: :destroy
  has_many :cenaculos, through: :cenaculo_casais

  before_validation :normalizar_nomes_completos_ele_ela
  before_validation :garantir_inscrito_em_em_casais_novos, on: :create
  before_validation :atribuir_assinatura_linha_ao_criar, on: :create

  before_save lambda {
    self.email_contato = email_contato&.strip&.downcase.presence
  }

  validates :nome_completo_ele, :nome_completo_ela, presence: true
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

  # Cenáculo (grupo) onde o casal está nesta edição; no máximo um por regras de negócio.
  def cenaculo_grupo
    cenaculo_casais.first&.cenaculo
  end

  private

  def normalizar_nomes_completos_ele_ela
    %i[nome_completo_ele nome_completo_ela].each do |attr|
      self[attr] = Casais::MapeamentoInscricaoSves.aplicar_padrao_nome_completo_participante(self[attr])
    end
  end

  def garantir_inscrito_em_em_casais_novos
    self.inscrito_em = nil if inscrito_em.blank?
    self.inscrito_em ||= Time.zone.now
  end

  def atribuir_assinatura_linha_ao_criar
    return if nome_completo_ele.blank? || nome_completo_ela.blank?

    recalcular_assinatura_linha!
  end
end
