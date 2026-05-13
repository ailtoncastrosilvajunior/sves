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
      log_erro_upload_imagem(:create, e)
      @cenaculo.errors.add(:base, mensagem_erro_upload_imagem(e))
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

  def mensagem_erro_upload_imagem(error)
    class_name = error.class.name
    message_down = error.message.to_s.downcase

    return I18n.t("cenaculos.imagem_upload.armazem_remoto") if class_name.start_with?("Aws::")
    if message_down.match?(/\b(signature|credentials|access denied|expired token|bucket not found|nosuchbucket|endpoint|connection refused|timed out|nodename|ssl_connect|temporary redirect|spaces)\b/)
      return I18n.t("cenaculos.imagem_upload.armazem_remoto")
    end

    formato_msg = message_down.match?(/\b(heic|heif|avif|vips|magick|libvips|pixels|dimensions|unsupported|image processing|unable to load|unable to open|no loader|not an image|unexpected source)\b/)

    imagem_engine = class_name.include?("Vips") || class_name.include?("MiniMagick")
    imagem_engine ||= defined?(MiniMagick::Error) && error.is_a?(MiniMagick::Error)

    return I18n.t("cenaculos.imagem_upload.formato_ou_pixels") if imagem_engine || formato_msg

    I18n.t("cenaculos.imagem_upload.generico")
  end

  def log_erro_upload_imagem(action, error)
    Rails.logger.warn("[cenaculos##{action}] imagem falhou: #{error.class}: #{error.message}")
    trace = Array(error.backtrace).first(12)&.join("\n")
    Rails.logger.warn(trace.to_s) if trace.present?
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
        log_erro_upload_imagem(:update, e)
        record.errors.add(:base, mensagem_erro_upload_imagem(e))
        render :edit, status: :unprocessable_entity
        return
      end
    elsif remove_pedido
      record.imagem.purge
    end

    redirect_to edicao_cenaculo_path(@edicao, record), notice: "Cenáculo atualizado."
  end
end
