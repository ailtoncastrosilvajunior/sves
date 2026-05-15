# frozen_string_literal: true

class CenaculoServosController < ApplicationController
  before_action :negar_se_nao_coordenacao!
  before_action :set_edicao
  before_action :set_cenaculo

  def create
    ids = Array(params[:servo_ids]).map(&:presence).compact.map(&:to_i).uniq

    if ids.empty?
      redirect_to edicao_cenaculo_path(@edicao, @cenaculo), alert: "Seleccione pelo menos um servo."
      return
    end

    candidatos = Servo.candidatos_pastor_cenaculo_na_edicao(@edicao).where(id: ids).order(:nome).pluck(:id)

    if candidatos.empty?
      redirect_to edicao_cenaculo_path(@edicao, @cenaculo),
                  alert: "Nenhum dos servos seleccionados pode ser adicionado (só participantes; não podem já pastorear nesta edição)."
      return
    end

    falhas = []

    CenaculoServo.transaction do
      candidatos.each do |sid|
        registro = @cenaculo.cenaculo_servos.build(servo_id: sid)
        unless registro.save
          falhas.concat(registro.errors.full_messages)
          raise ActiveRecord::Rollback
        end
      end
    end

    if falhas.any?
      redirect_to edicao_cenaculo_path(@edicao, @cenaculo),
                  alert: falhas.uniq.to_sentence.presence || "Não foi possível adicionar alguns pastores."
      return
    end

    criados = candidatos.size

    notice =
      if criados == 1
        "1 pastor adicionado ao cenáculo."
      else
        "#{criados} pastores adicionados ao cenáculo."
      end

    redirect_to edicao_cenaculo_path(@edicao, @cenaculo), notice: notice
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

end
