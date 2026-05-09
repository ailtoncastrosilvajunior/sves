# frozen_string_literal: true

class CenaculoCasaisController < ApplicationController
  before_action :set_edicao
  before_action :set_cenaculo

  def create
    vinculo = @cenaculo.cenaculo_casais.build(cenaculo_casal_params)
    casal_id_alvo = vinculo.casal_id

    unless casal_id_alvo.present? && @edicao.casais.exists?(casal_id_alvo)
      redirect_to edicao_cenaculo_path(@edicao, @cenaculo), alert: "Escolha um casal desta edição."
      return
    end

    if vinculo.save
      redirect_to edicao_cenaculo_path(@edicao, @cenaculo), notice: "Casal adicionado ao cenáculo."
    else
      redirect_to edicao_cenaculo_path(@edicao, @cenaculo),
                  alert: vinculo.errors.full_messages.to_sentence.presence || "Não foi possível adicionar o casal."
    end
  end

  def destroy
    vinculo = @cenaculo.cenaculo_casais.find(params[:id])
    vinculo.destroy!
    redirect_to edicao_cenaculo_path(@edicao, @cenaculo), notice: "Casal retirado do cenáculo."
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:edicao_id])
  end

  def set_cenaculo
    @cenaculo = @edicao.cenaculos.find(params[:cenaculo_id])
  end

  def cenaculo_casal_params
    params.require(:cenaculo_casal).permit(:casal_id)
  end
end
