# frozen_string_literal: true

class CasaisController < ApplicationController
  before_action :set_edicao

  def index
    @casais = Casal
      .where(edicao: @edicao)
      .order(Arel.sql("casais.inscrito_em DESC NULLS LAST"))
      .order(:nome_completo_ele)
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:edicao_id])
  end
end
