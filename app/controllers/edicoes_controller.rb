require "csv"

class EdicoesController < ApplicationController
  before_action :define_edicao, only: %i[
    show edit update destroy marcar_em_curso importar_casais_csv
  ]

  def index
    @edicoes = Edicao.order(ano: :desc, numero_edicao: :desc)
  end

  def show
  end

  def marcar_em_curso
    if @edicao.update(ativa: true)
      redirect_to @edicao, notice: "Esta edição passou a ser a edição em curso. Os atalhos da app ligam-se a ela."
    else
      redirect_to @edicao, alert: @edicao.errors.full_messages.to_sentence
    end
  end

  def new
    @edicao = Edicao.new
  end

  def edit
  end

  def create
    @edicao = Edicao.new(edicao_params)

    if @edicao.save
      redirect_to @edicao, notice: "Edição criada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @edicao.update(edicao_params)
      redirect_to @edicao, notice: "Edição atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @edicao.destroy!
    redirect_to edicoes_url, notice: "Edição removida."
  end

  def importar_casais_csv
    arquivo = params[:casais_csv]
    unless arquivo.respond_to?(:tempfile) && arquivo.tempfile.present?
      redirect_back fallback_location: @edicao, alert: t("edicoes.importar_csv.alertas.arquivo_obrigatorio")
      return
    end

    unless csv_para_importacao?(arquivo)
      redirect_back fallback_location: @edicao, alert: t("edicoes.importar_csv.alertas.arquivo_invalido")
      return
    end

    arquivo.tempfile.rewind
    stats = Casais::ImportadorCsvInscricao.importar!(
      edicao: @edicao,
      io: arquivo.tempfile,
      nome_arquivo: arquivo.original_filename,
    )

    mensagem =
      if stats[:criados].zero? && stats[:atualizados].zero?
        { alert: t("edicoes.importar_csv.alertas.sem_linhas_validas") }
      else
        { notice: t("edicoes.importar_csv.notice.sucesso", criados: stats[:criados], atualizados: stats[:atualizados]) }
      end

    redirect_to @edicao, **mensagem
  rescue CSV::MalformedCSVError => e
    Rails.logger.warn("importar_casais_csv CSV inválido: #{e.message}")
    redirect_back fallback_location: @edicao, alert: t("edicoes.importar_csv.alertas.csv_malformado")
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: @edicao, alert: t("edicoes.importar_csv.alertas.registro_invalido", mensagem: e.record.errors.full_messages.to_sentence)
  end

  private

  def define_edicao
    @edicao = Edicao.find(params[:id])
  end

  def edicao_params
    params.require(:edicao).permit(:ano, :numero_edicao, :link_planilha)
  end

  def csv_para_importacao?(uploaded)
    nome = uploaded.original_filename.to_s.downcase
    return false unless nome.end_with?(".csv")

    tipo = uploaded.content_type.to_s
    return true if tipo.blank?

    %w[text/csv application/csv text/plain application/vnd.ms-excel].include?(tipo)
  end
end
