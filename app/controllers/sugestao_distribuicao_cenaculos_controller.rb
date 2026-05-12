# frozen_string_literal: true

class SugestaoDistribuicaoCenaculosController < ApplicationController
  before_action :set_edicao
  before_action :negar_se_nao_administrador!

  def new
    @somente_sem_cenaculo = apenas_sem_checkbox(params[:somente_sem_cenaculo])
    filtrados = escopo_de_casais(@somente_sem_cenaculo)
    @contagem_escopo = filtrados.size
    @casais_por_grupo_prefill =
      ajustar_tamanho_grupo(params[:casais_por_grupo], @contagem_escopo)
    @semilla_manual = params[:semilla].to_s
    @texto_regra =
      params[:texto_regra].presence || Cenaculos::DistribuidorSugestao.texto_padrao_regra
  end

  def create
    apenas_sem = apenas_sem_checkbox(params[:somente_sem_cenaculo])
    lista_escopo = escopo_de_casais(apenas_sem)

    if lista_escopo.size < 2
      redireciona_com_alerta(
        "Só há #{lista_escopo.size} casal(is); importe outros ou inclua também os que já estejam agrupados.",
      )
      return
    end

    limite = ajustar_tamanho_grupo(params[:casais_por_grupo], lista_escopo.size)

    resultado_markup =
      Cenaculos::DistribuidorSugestao.new(
        lista_escopo,
        casais_por_grupo: limite,
        semente: params[:semilla].to_s,
        texto_regra: params[:texto_regra].to_s,
        rotulo_edicao: @edicao.rotulo,
        somente_sem_cenaculo: apenas_sem,
      ).resultado

    corpo_markup =
      ApplicationController.render(
        layout: false,
        formats: [:html],
        template: "sugestao_distribuicao_cenaculos/documento",
        locals: { resultado: resultado_markup },
      )

    send_data(
      corpo_markup,
      filename: resultado_markup.nome_ficheiro,
      type: "text/html; charset=utf-8",
      disposition: "attachment",
    )
  rescue ArgumentError => problema
    redireciona_com_alerta(problema.message)
  end

  private

  def set_edicao
    @edicao = Edicao.find(params.require(:edicao_id))
  end

  def redireciona_com_alerta(mensagem_visual)
    redirect_to edicao_distribuicao_cenaculos_sugestao_path(@edicao), alert: mensagem_visual.to_s.strip
  end

  def apenas_sem_checkbox(valor_na_url_param)
    return true if valor_na_url_param.nil?

    ActiveModel::Type::Boolean.new.cast(valor_na_url_param)
  end

  def escopo_de_casais(apenas_sem_cenaculos)
    base = Casal.where(edicao_id: @edicao.id).order(:nome_completo_ele)
    return base unless apenas_sem_cenaculos

    ocupados =
      CenaculoCasal.joins(:cenaculo).where(cenaculos: { edicao_id: @edicao.id }).select(:casal_id)
    ocupados.blank? ? base : base.where.not(id: ocupados)
  end

  def tamanho_sugerido_para(total_casamentos)
    total_casamentos = total_casamentos.to_i
    return total_casamentos if total_casamentos < 2

    sugerido = [(total_casamentos.to_f / 4).ceil, 2].max
    sugerido = [sugerido, 12].min
    [sugerido, total_casamentos].min
  end

  def ajustar_tamanho_grupo(valor_param, total_escopo)
    total = total_escopo.to_i
    recomendado = tamanho_sugerido_para(total)
    candidato = valor_param.present? ? valor_param.to_i : recomendado
    candidato = recomendado if candidato < 2 || !candidato.positive?
    candidato = [candidato, total].min
    [candidato, 2].max
  end
end
