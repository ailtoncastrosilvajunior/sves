# frozen_string_literal: true

# Materiais editoriais globais (PDF, Word, …) para servos; +ativo+ controla visibilidade na lista pública.
class MateriaisApoioController < ApplicationController
  before_action :negar_se_nao_coordenacao!, only: %i[todos new create edit update destroy]
  before_action :negar_se_nao_administrador!, only: %i[edit update destroy]
  before_action :set_material, only: %i[edit update destroy baixar]

  def index
    @materiais = materiais_visiveis
  end

  def todos
    @materiais = MaterialApoio.listagem.includes(:arquivo_attachment)
  end

  def new
    @material = MaterialApoio.new(ativo: true, ordem: 0)
  end

  def create
    @material = MaterialApoio.new(material_params.except(:remove_arquivo))

    unless @material.save
      render :new, status: :unprocessable_entity
      return
    end

    redirect_to todos_materiais_apoio_path, notice: t("material_apoio.flash.criado")
  end

  def edit
  end

  def update
    @material.assign_attributes(material_params.except(:remove_arquivo))
    arquivo_enviado = params.dig(:material_apoio, :arquivo).present?

    if purge_requested? && !arquivo_enviado && @material.arquivo.attached?
      @material.arquivo.purge
    end

    unless @material.save
      render :edit, status: :unprocessable_entity
      return
    end

    redirect_to todos_materiais_apoio_path, notice: t("material_apoio.flash.atualizado")
  end

  def destroy
    @material.destroy!
    redirect_to todos_materiais_apoio_path, notice: t("material_apoio.flash.removido")
  end

  # GET — lista pública apenas liga materiais activos; gestão permite inactivos.
  def baixar
    unless pode_gerir_painel? || @material.ativo?
      redirect_back fallback_location: materiais_apoio_path,
                    alert: t("material_apoio.flash.baixar_inativo")
      return
    end
    unless @material.arquivo.attached?
      redirect_back fallback_location: materiais_apoio_path,
                    alert: t("material_apoio.flash.sem_ficheiro")
      return
    end

    redirect_to rails_blob_path(@material.arquivo, disposition: :attachment),
                allow_other_host: true,
                status: :see_other
  end

  private

  def set_material
    @material = MaterialApoio.find(params[:id])
  end

  def materiais_visiveis
    MaterialApoio.ativos.merge(MaterialApoio.listagem).includes(:arquivo_attachment).select(&:arquivo_baixavel?)
  end

  def material_params
    params.require(:material_apoio).permit(:titulo, :descricao, :ativo, :ordem, :arquivo, :remove_arquivo)
  end

  def purge_requested?
    ActiveModel::Type::Boolean.new.cast(params.dig(:material_apoio, :remove_arquivo))
  end
end
