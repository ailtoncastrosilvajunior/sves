# frozen_string_literal: true

class CasaisController < ApplicationController
  before_action :set_edicao
  before_action :negar_se_nao_coordenacao!

  def index
    @casais = Casal
      .where(edicao: @edicao)
      .order(Arel.sql("casais.inscrito_em DESC NULLS LAST"))
      .order(:nome_completo_ele)
    @visualizacao_casais = params[:v].presence_in(%w[resumida completa]) || "resumida"
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:edicao_id])
  end
end
