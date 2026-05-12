# frozen_string_literal: true

class CenaculoReuniaoPresencasController < ApplicationController
  before_action :set_edicao
  before_action :set_cenaculo
  before_action :garantir_acesso_presencas!

  def index
    @reunioes =
      if pode_gerir_painel?
        @edicao.edicao_reuniao_cenaculos.ordenadas
      else
        @edicao.edicao_reuniao_cenaculos.where(estado: %w[liberada encerrada]).ordenadas
      end
  end

  def edit
    @reuniao = @edicao.edicao_reuniao_cenaculos.find(params[:reuniao_id])

    unless pode_gerir_painel?
      unless @reuniao.visivel_para_pastor?
        redirect_to reunioes_cenaculo_edicao_cenaculo_path(@edicao, @cenaculo),
                    alert: I18n.t("reunioes_cenaculo.presencas.reuniao_indisponivel"),
                    status: :see_other
        return
      end
    end

    @somente_leitura = !pode_editar_presencas_reuniao?(@reuniao, @cenaculo)
    garantir_linhas_presenca!
    @casais_com_presenca =
      @cenaculo.casais.order(:nome_completo_ele).map do |casal|
        pres = CenaculoPresencaReuniao.find_by!(
          edicao_reuniao_cenaculo: @reuniao,
          cenaculo: @cenaculo,
          casal: casal,
        )
        [casal, pres]
      end
  end

  def update
    @reuniao = @edicao.edicao_reuniao_cenaculos.find(params[:reuniao_id])

    unless pode_editar_presencas_reuniao?(@reuniao, @cenaculo)
      redirect_to reunioes_cenaculo_edicao_cenaculo_path(@edicao, @cenaculo),
                  alert: I18n.t("reunioes_cenaculo.presencas.sem_permissao_editar"),
                  status: :see_other
      return
    end

    garantir_linhas_presenca!

    if params[:acao_lote].present?
      aplicar_acao_lote!(params[:acao_lote].to_s)
      redirect_to edit_reuniao_presencas_edicao_cenaculo_path(@edicao, @cenaculo, reuniao_id: params[:reuniao_id]),
                  notice: I18n.t("reunioes_cenaculo.presencas.flash_lote_ok"),
                  status: :see_other
      return
    end

    aplicar_presencas_individuals!(params[:presencas])
    redirect_to edit_reuniao_presencas_edicao_cenaculo_path(@edicao, @cenaculo, reuniao_id: params[:reuniao_id]),
                notice: I18n.t("reunioes_cenaculo.presencas.flash_guardado"),
                status: :see_other
  rescue ActiveRecord::RecordNotFound
    redirect_to reunioes_cenaculo_edicao_cenaculo_path(@edicao, @cenaculo),
                alert: I18n.t("reunioes_cenaculo.presencas.reuniao_indisponivel"),
                status: :see_other
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:edicao_id])
  end

  def set_cenaculo
    @cenaculo = @edicao.cenaculos.find(params[:id])
  end

  def garantir_acesso_presencas!
    return if pode_gerir_painel?

    garantir_cenaculo_do_participante!
  end

  def garantir_linhas_presenca!
    @cenaculo.casais.find_each do |casal|
      CenaculoPresencaReuniao.find_or_create_by!(
        edicao_reuniao_cenaculo: @reuniao,
        cenaculo: @cenaculo,
        casal: casal,
      )
    end
  end

  def aplicar_presencas_individuals!(raw)
    ids = @cenaculo.casais.pluck(:id).map(&:to_s).to_set
    hash =
      case raw
      when ActionController::Parameters
        raw.to_unsafe_h.stringify_keys
      when Hash
        raw.stringify_keys
      else
        {}
      end

    cast_bool = ActiveModel::Type::Boolean.new

    CenaculoPresencaReuniao.transaction do
      ids.each do |casal_id|
        flags = hash[casal_id]
        flags_h =
          case flags
          when ActionController::Parameters
            flags.permit(:presente_ele, :presente_ela).to_h.stringify_keys
          when Hash
            flags.stringify_keys.slice("presente_ele", "presente_ela")
          else
            {}
          end

        pres = CenaculoPresencaReuniao.find_by!(
          edicao_reuniao_cenaculo: @reuniao,
          cenaculo: @cenaculo,
          casal_id: casal_id,
        )

        ele_raw = flags_h["presente_ele"]
        ela_raw = flags_h["presente_ela"]

        pres.update!(
          presente_ele: ele_raw.nil? ? false : cast_bool.cast(ele_raw),
          presente_ela: ela_raw.nil? ? false : cast_bool.cast(ela_raw),
        )
      end
    end
  end

  def aplicar_acao_lote!(acao)
    escopo = CenaculoPresencaReuniao.where(edicao_reuniao_cenaculo: @reuniao, cenaculo: @cenaculo)

    case acao
    when "todos_ele"
      escopo.update_all(presente_ele: true)
    when "todos_ela"
      escopo.update_all(presente_ela: true)
    when "todos_ambos"
      escopo.update_all(presente_ele: true, presente_ela: true)
    when "limpar"
      escopo.update_all(presente_ele: false, presente_ela: false)
    end
  end
end
