# frozen_string_literal: true

class EdicaoReunioesCenaculosController < ApplicationController
  before_action :set_edicao
  before_action :negar_se_nao_coordenacao!

  def index
    @reunioes = @edicao.edicao_reuniao_cenaculos.ordenadas
  end

  def new
    @reuniao = @edicao.edicao_reuniao_cenaculos.build(ordem: proxima_ordem)
  end

  def create
    @reuniao = @edicao.edicao_reuniao_cenaculos.build(reuniao_params)
    @reuniao.ordem = proxima_ordem if @reuniao.ordem.blank?

    if @reuniao.save
      redirect_to edicao_reunioes_cenaculo_index_path(@edicao),
                  notice: I18n.t("reunioes_cenaculo.flash.criada")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @reuniao = reuniao_escopo.find(params[:id])
  end

  def update
    @reuniao = reuniao_escopo.find(params[:id])

    if @reuniao.update(reuniao_params)
      redirect_to edicao_reunioes_cenaculo_index_path(@edicao),
                  notice: I18n.t("reunioes_cenaculo.flash.actualizada")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reuniao = reuniao_escopo.find(params[:id])
    nome = @reuniao.titulo
    @reuniao.destroy!
    redirect_to edicao_reunioes_cenaculo_index_path(@edicao),
                notice: I18n.t("reunioes_cenaculo.flash.removida", titulo: nome)
  end

  def novo_lote
    @linhas = 8.times.map { { titulo: "", descricao: "" } }
  end

  def criar_lote
    lista = normalizar_linhas_lote(params[:reunioes])
    if lista.blank?
      redirect_to novo_lote_edicao_reunioes_cenaculo_index_path(@edicao),
                  alert: I18n.t("reunioes_cenaculo.flash.lote_vazio"),
                  status: :see_other
      return
    end

    ordem_base = reuniao_escopo.maximum(:ordem).to_i
    EdicaoReuniaoCenaculo.transaction do
      lista.each_with_index do |attrs, idx|
        @edicao.edicao_reuniao_cenaculos.create!(
          titulo: attrs[:titulo],
          descricao: attrs[:descricao],
          ordem: ordem_base + idx + 1,
          estado: :em_preparacao,
        )
      end
    end

    redirect_to edicao_reunioes_cenaculo_index_path(@edicao),
                notice: I18n.t("reunioes_cenaculo.flash.lote_ok", count: lista.size),
                status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to novo_lote_edicao_reunioes_cenaculo_index_path(@edicao),
                  alert: e.record.errors.full_messages.to_sentence.presence || e.message,
                  status: :see_other
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:edicao_id])
  end

  def reuniao_escopo
    @edicao.edicao_reuniao_cenaculos
  end

  def reuniao_params
    params.require(:edicao_reuniao_cenaculo).permit(:titulo, :descricao, :ordem, :estado)
  end

  def proxima_ordem
    reuniao_escopo.maximum(:ordem).to_i + 1
  end

  def normalizar_linhas_lote(raw)
    return [] if raw.blank?

    hashes =
      case raw
      when ActionController::Parameters
        raw.to_unsafe_h.sort_by { |k, _| k.to_i }.map(&:second)
      when Hash
        raw.sort_by { |k, _| k.to_i }.map(&:second)
      else
        []
      end

    hashes.filter_map do |row|
      next unless row.is_a?(Hash) || row.is_a?(ActionController::Parameters)

      titulo = row[:titulo].to_s.strip
      next if titulo.blank?

      { titulo: titulo, descricao: row[:descricao].to_s.strip.presence }
    end
  end
end
