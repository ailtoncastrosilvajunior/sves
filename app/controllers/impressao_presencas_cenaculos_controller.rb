# frozen_string_literal: true

# Folha para impressão / PDF (navegador): presenças por reunião, homens e mulheres em tabelas separadas.
class ImpressaoPresencasCenaculosController < ApplicationController
  helper CenaculosHelper

  before_action :set_edicao
  before_action :garantir_acesso_impressao_presencas!

  def show
    @reunioes = @edicao.edicao_reuniao_cenaculos.ordenadas.to_a
    @cenaculo_filtro =
      if params[:cenaculo_id].present?
        @edicao.cenaculos.find_by(id: params[:cenaculo_id].to_s)
      end

    if params[:cenaculo_id].present? && @cenaculo_filtro.blank?
      redirect_to edicao_cenaculos_path(@edicao),
                  alert: I18n.t("impressao_presencas_cenaculos.cenaculo_filtro_invalido")
      return
    end

    scope =
      @edicao.cenaculos
             .includes(cenaculo_casais: :casal, cenaculo_servos: { servo: :conjuge })
    @cenaculos =
      if @cenaculo_filtro
        scope.where(id: @cenaculo_filtro.id).order(:nome)
      elsif pode_gerir_painel?
        scope.order(:nome)
      else
        # Participante não devia chegar aqui sem filtro (before_action); defesa em profundidade.
        scope.none
      end

    reuniao_ids = @reunioes.map(&:id)
    cenaculo_ids = @cenaculos.map(&:id)

    @presencas_por_chave = {}
    if reuniao_ids.any? && cenaculo_ids.any?
      CenaculoPresencaReuniao.where(
        edicao_reuniao_cenaculo_id: reuniao_ids,
        cenaculo_id: cenaculo_ids,
      ).find_each do |p|
        @presencas_por_chave[[p.cenaculo_id, p.casal_id, p.edicao_reuniao_cenaculo_id]] = p
      end
    end

    render layout: "impressao_presencas_cenaculos"
  end

  private

  def garantir_acesso_impressao_presencas!
    return if pode_gerir_painel?

    unless current_user&.servo
      redirect_to root_path, alert: I18n.t("autorizacao.sem_perfil_servo")
      return
    end

    unless @edicao.ativa?
      redirect_to root_path, alert: I18n.t("autorizacao.participante_so_edicao_em_curso")
      return
    end

    cid = params[:cenaculo_id].presence
    if cid.blank?
      redirect_to destino_cenaculos_participante_na_edicao(@edicao),
                  alert: I18n.t("impressao_presencas_cenaculos.participante_precisa_cenaculo")
      return
    end

    cenaculo = @edicao.cenaculos.find_by(id: cid)
    if cenaculo.blank?
      redirect_to destino_cenaculos_participante_na_edicao(@edicao),
                  alert: I18n.t("impressao_presencas_cenaculos.cenaculo_filtro_invalido")
      return
    end

    unless current_user.servo.cenaculos.exists?(id: cenaculo.id)
      redirect_to destino_cenaculos_participante_na_edicao(@edicao),
                  alert: I18n.t("autorizacao.cenaculo_nao_autorizado")
      return
    end
  end

  def set_edicao
    @edicao = Edicao.find(params[:id])
  end
end
