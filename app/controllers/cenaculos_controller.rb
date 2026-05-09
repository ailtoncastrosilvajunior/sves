# frozen_string_literal: true

class CenaculosController < ApplicationController
  before_action :set_edicao
  before_action :set_cenaculo, only: %i[show edit update destroy]

  def index
    @cenaculos = @edicao.cenaculos
      .includes(:imagem_attachment, :cenaculo_casais, :cenaculo_servos)
      .order(:nome)
  end

  def show
    @cenaculo_casais = @cenaculo.cenaculo_casais
      .joins(:casal)
      .includes(:casal)
      .order("casais.nome_completo_ele ASC")

    @cenaculo_servos_lista = @cenaculo.cenaculo_servos
      .joins(:servo)
      .includes(:servo)
      .order("servos.nome ASC")

    ocupacao_na_edicao = CenaculoCasal.joins(:cenaculo).where(cenaculos: { edicao_id: @edicao.id }).select(:casal_id)

    @casais_para_adicionar = Casal.where(edicao_id: @edicao.id)
      .where.not(id: ocupacao_na_edicao)
      .order(Arel.sql("casais.inscrito_em DESC NULLS LAST"))
      .order(:nome_completo_ele)

    pastores_ids = @cenaculo.servos.pluck(:id)
    @servos_para_adicionar = Servo.where.not(id: pastores_ids).order(:nome)
  end

  def new
    @cenaculo = @edicao.cenaculos.build
  end

  def edit
  end

  def create
    @cenaculo = @edicao.cenaculos.build(cenaculo_params)

    if @cenaculo.save
      redirect_to edicao_cenaculo_path(@edicao, @cenaculo), notice: "Cenáculo criado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    atualizar_com_imagem_opcional(@cenaculo)
  end

  def destroy
    nome = @cenaculo.nome
    @cenaculo.destroy!
    redirect_to edicao_cenaculos_path(@edicao), notice: "Cenáculo «#{nome}» removido."
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:edicao_id])
  end

  def set_cenaculo
    @cenaculo = @edicao.cenaculos.find(params[:id])
  end

  def cenaculo_params
    params.require(:cenaculo).permit(:nome, :cor, :imagem)
  end

  def atualizar_com_imagem_opcional(record)
    permitted = cenaculo_params
    remove_pedido = ActiveModel::Type::Boolean.new.cast(params[:cenaculo][:remove_imagem])
    nomes_sem_ficheiro = permitted.except(:imagem)

    unless record.update(nomes_sem_ficheiro)
      render :edit, status: :unprocessable_entity
      return
    end

    if permitted[:imagem].present?
      record.imagem.attach(permitted[:imagem])
    elsif remove_pedido
      record.imagem.purge
    end

    redirect_to edicao_cenaculo_path(@edicao, record), notice: "Cenáculo atualizado."
  end
end
