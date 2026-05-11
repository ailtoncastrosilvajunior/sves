# frozen_string_literal: true

class CenaculoServosController < ApplicationController
  before_action :negar_se_nao_coordenacao!
  before_action :set_edicao
  before_action :set_cenaculo

  def create
    vinculo = @cenaculo.cenaculo_servos.build(cenaculo_servo_params)
    servo_id_alvo = vinculo.servo_id

    unless servo_id_alvo.present? && Servo.exists?(servo_id_alvo)
      redirect_to edicao_cenaculo_path(@edicao, @cenaculo), alert: "Escolha um servo válido."
      return
    end

    if vinculo.save
      redirect_to edicao_cenaculo_path(@edicao, @cenaculo), notice: "Pastor adicionado ao cenáculo."
    else
      redirect_to edicao_cenaculo_path(@edicao, @cenaculo),
                  alert: vinculo.errors.full_messages.to_sentence.presence || "Não foi possível adicionar o pastor."
    end
  end

  def destroy
    vinculo = @cenaculo.cenaculo_servos.find(params[:id])
    vinculo.destroy!
    redirect_to edicao_cenaculo_path(@edicao, @cenaculo), notice: "Pastor retirado do cenáculo."
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:edicao_id])
  end

  def set_cenaculo
    @cenaculo = @edicao.cenaculos.find(params[:cenaculo_id])
  end

  def cenaculo_servo_params
    params.require(:cenaculo_servo).permit(:servo_id)
  end
end
