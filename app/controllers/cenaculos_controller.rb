# frozen_string_literal: true

class CenaculosController < ApplicationController
  before_action :set_edicao
  before_action :garantir_acesso_cenaculos_na_edicao!, only: %i[index show new create edit update destroy]
  before_action :set_cenaculo, only: %i[show edit update destroy]
  before_action :garantir_cenaculo_do_participante!, only: :show
  before_action :negar_se_nao_coordenacao!, only: %i[new create edit update destroy]

  def index
    @cenaculos = @edicao.cenaculos
      .includes(:imagem_attachment, :cenaculo_casais, cenaculo_servos: { servo: :conjuge })
      .order(:nome)
    if !pode_gerir_painel? && current_user.servo
      @cenaculos = @cenaculos.where(id: current_user.servo.cenaculo_ids)
    end
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

    if pode_gerir_painel?
      ocupacao_na_edicao = CenaculoCasal.joins(:cenaculo).where(cenaculos: { edicao_id: @edicao.id }).select(:casal_id)

      @casais_para_adicionar = Casal.where(edicao_id: @edicao.id)
        .where.not(id: ocupacao_na_edicao)
        .order(Arel.sql("casais.inscrito_em DESC NULLS LAST"))
        .order(:nome_completo_ele)

      pastores_ids = @cenaculo.servos.pluck(:id)
      @servos_para_adicionar = Servo.where.not(id: pastores_ids).order(:nome)
    else
      @casais_para_adicionar = Casal.none
      @servos_para_adicionar = Servo.none
    end
  end

  def new
    @cenaculo = @edicao.cenaculos.build
  end

  def edit
  end

  def create
    permitted = cenaculo_params
    @cenaculo = @edicao.cenaculos.build(permitted.except(:imagem))
    begin
      @cenaculo.imagem.attach(permitted[:imagem]) if permitted[:imagem].present?
    rescue StandardError => e
      Rails.logger.warn("[cenaculos#create] imagem: #{e.class}: #{e.message}")
      @cenaculo.errors.add(:imagem, "não foi possível processar o ficheiro. Experimente JPG, PNG ou WebP (tamanho moderado).")
      render :new, status: :unprocessable_entity
      return
    end

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
    params.require(:cenaculo).permit(:nome, :cor, :local_homens, :local_mulheres, :imagem)
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
      begin
        record.imagem.attach(permitted[:imagem])
      rescue StandardError => e
        Rails.logger.warn("[cenaculos#update] imagem: #{e.class}: #{e.message}")
        record.errors.add(:imagem, "não foi possível processar o ficheiro. Experimente JPG, PNG ou WebP (tamanho moderado).")
        render :edit, status: :unprocessable_entity
        return
      end
    elsif remove_pedido
      record.imagem.purge
    end

    redirect_to edicao_cenaculo_path(@edicao, record), notice: "Cenáculo atualizado."
  end
end
