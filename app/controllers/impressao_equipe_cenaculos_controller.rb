# frozen_string_literal: true

# Folha única para impressão / PDF (navegador) com cenáculos, pastores, locais e casais.
class ImpressaoEquipeCenaculosController < ApplicationController
  helper CenaculosHelper

  before_action :set_edicao
  before_action :negar_se_nao_coordenacao!

  def show
    @casais_nomes_modo = params[:casais_nomes].presence_in(%w[completo apelido ambos]) || "completo"

    @cenaculos =
      @edicao.cenaculos
        .includes(cenaculo_casais: :casal, cenaculo_servos: { servo: :conjuge })
        .order(:nome)

    coord_servos = Servo.where(papel: Servo::PAPEL_COORDENACAO).includes(:conjuge).order(:nome)
    @coordenacao_geral_linhas = helpers.linhas_servos_agrupados_casal(coord_servos)

    render layout: "impressao_equipe_cenaculos"
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:id])
  end
end
