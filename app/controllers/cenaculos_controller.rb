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

      @servos_para_adicionar = Servo.candidatos_pastor_cenaculo_na_edicao(@edicao).order(:nome)
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
    com_imagem = permitted[:imagem].present?

    begin
      @cenaculo.imagem.attach(permitted[:imagem]) if com_imagem
      unless @cenaculo.save
        render :new, status: :unprocessable_entity
        return
      end
    rescue StandardError => e
      raise unless erro_upload_imagem_ou_remote_storage?(e)

      log_erro_upload_imagem(:create, e)
      limpar_bd_imagem_cenaculo_apos_falha_no_servico(@cenaculo) if @cenaculo.persisted?
      @cenaculo.imagem.detach if com_imagem && !@cenaculo.persisted?
      @cenaculo.reload if @cenaculo.persisted?
      @cenaculo.errors.add(:base, mensagem_erro_upload_imagem(e))
      render :new, status: :unprocessable_entity
      return
    end

    redirect_to edicao_cenaculo_path(@edicao, @cenaculo), notice: "Cenáculo criado."
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
    params.require(:cenaculo).permit(:nome, :cor, :local_homens, :local_mulheres, :pastores_texto_livre, :imagem)
  end

  def erro_upload_imagem_ou_remote_storage?(error)
    return true if erro_remoto_spaces?(error)

    message_down = error.message.to_s.downcase
    formato_msg = message_down.match?(/\b(heic|heif|avif|vips|magick|libvips|pixels|dimensions|unsupported|image processing|unable to load|unable to open|no loader|not an image|unexpected source)\b/)

    cn = error.class.name
    cn.include?("Vips") || cn.include?("MiniMagick") ||
      (defined?(MiniMagick::Error) && error.is_a?(MiniMagick::Error)) || formato_msg
  end

  def mensagem_erro_upload_imagem(error)
    return I18n.t("cenaculos.imagem_upload.bucket_inexistente") if erro_spaces_bucket_inexistente?(error)
    return I18n.t("cenaculos.imagem_upload.armazem_remoto") if erro_remoto_spaces?(error)

    message_down = error.message.to_s.downcase

    formato_msg = message_down.match?(/\b(heic|heif|avif|vips|magick|libvips|pixels|dimensions|unsupported|image processing|unable to load|unable to open|no loader|not an image|unexpected source)\b/)

    cn = error.class.name
    imagem_engine = cn.include?("Vips") || cn.include?("MiniMagick")
    imagem_engine ||= defined?(MiniMagick::Error) && error.is_a?(MiniMagick::Error)

    return I18n.t("cenaculos.imagem_upload.formato_ou_pixels") if imagem_engine || formato_msg

    I18n.t("cenaculos.imagem_upload.generico")
  end

  def erro_spaces_bucket_inexistente?(error)
    cn = error.class.name
    return true if cn == "Aws::S3::Errors::NoSuchBucket"
    code = error.respond_to?(:code) ? error.code.to_s : ""
    return true if code == "NoSuchBucket"

    md = error.message.to_s.downcase
    md.include?("specified bucket does not exist") ||
      /\bnosuchbucket\b/.match?(md) ||
      (cn.start_with?("Aws::") && md.include?("bucket does not exist"))
  end

  def erro_remoto_spaces?(error)
    cn = error.class.name
    return true if cn.start_with?("Aws::", "Seahorse::")
    return true if defined?(OpenSSL::SSL::SSLError) && error.is_a?(OpenSSL::SSL::SSLError)
    return true if error.is_a?(SocketError)

    message_down = error.message.to_s.downcase
    message_down.match?(
      /\b(signature|credentials|access denied|expired token|bucket not found|nosuchbucket|endpoint|digitalocean(?:\s+spaces)?|connection refused|timed out|time out|timeout|nodename|ssl(?:_|\s+)connect|econnreset|etimedout|temporary redirect|\bspaces\b)\b/n,
    )
  end

  def log_erro_upload_imagem(action, error)
    Rails.logger.warn("[cenaculos##{action}] imagem falhou: #{error.class}: #{error.message}")
    trace = Array(error.backtrace).first(12)&.join("\n")
    Rails.logger.warn(trace.to_s) if trace.present?
    log_contexto_spaces_nosuchbucket if erro_spaces_bucket_inexistente?(error)
  end

  def log_contexto_spaces_nosuchbucket
    return unless Rails.application.config.active_storage.service == :digitalocean_spaces

    srv = ActiveStorage::Blob.services.fetch(:digitalocean_spaces)
    cli = srv.client.respond_to?(:client) ? srv.client.client : nil
    Rails.logger.warn(
      "[cenaculos] Spaces (NoSuchBucket) bucket=#{srv.bucket&.name.inspect} endpoint=#{cli&.config&.endpoint} ",
    )
  rescue StandardError => e
    Rails.logger.warn("[cenaculos] Spaces contexto não registado: #{e.class}: #{e.message}")
  end

  def atualizar_com_imagem_opcional(record)
    permitted = cenaculo_params
    remove_pedido = ActiveModel::Type::Boolean.new.cast(params[:cenaculo][:remove_imagem])
    attrs_sem_ficheiro = permitted.except(:imagem)
    nova_imagem = permitted[:imagem].present?

    record.assign_attributes(attrs_sem_ficheiro)

    salvou = false
    begin
      if nova_imagem
        record.imagem.attach(permitted[:imagem])
      elsif remove_pedido && record.imagem.attached?
        record.imagem.purge
      end

      salvou = record.save
    rescue StandardError => e
      raise unless erro_upload_imagem_ou_remote_storage?(e)

      log_erro_upload_imagem(:update, e)
      limpar_bd_imagem_cenaculo_apos_falha_no_servico(record)
      record.reload
      record.errors.add(:base, mensagem_erro_upload_imagem(e))
      render :edit, status: :unprocessable_entity
      return
    end

    unless salvou
      render :edit, status: :unprocessable_entity
      return
    end

    redirect_to edicao_cenaculo_path(@edicao, record), notice: "Cenáculo atualizado."
  end

  # Rails 8 faz upload do blob em after_commit; se falha o Spaces, podem ficar linhas órfãs em BD.
  # Limpamos só registos Active Storage (sem apagar o cenáculo) para pré-visualização não apontar a ficheiros inexistentes.
  def limpar_bd_imagem_cenaculo_apos_falha_no_servico(cenaculo)
    rid = cenaculo&.id
    return if rid.blank?

    type = Cenaculo.base_class.name
    bids =
      ActiveStorage::Attachment.where(record_type: type, record_id: rid, name: "imagem").pluck(:blob_id).compact.uniq
    return if bids.empty?

    ActiveStorage::VariantRecord.where(blob_id: bids).delete_all
    ActiveStorage::Attachment.where(record_type: type, record_id: rid, name: "imagem").delete_all
    ActiveStorage::Blob.where(id: bids).delete_all
  rescue StandardError => e
    Rails.logger.warn("[cenaculos] limpar imagem na BD após erro do serviço: #{e.class}: #{e.message}")
  end
end
