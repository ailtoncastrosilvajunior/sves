# frozen_string_literal: true

class CasaisController < ApplicationController
  before_action :set_edicao
  before_action :negar_se_nao_coordenacao!

  def index
    @casais = Casal
      .where(edicao: @edicao)
      .includes(cenaculo_casais: :cenaculo)
      .order(Arel.sql("casais.inscrito_em DESC NULLS LAST"))
      .order(:nome_completo_ele)
    @visualizacao_casais = params[:v].presence_in(%w[resumida nomes_chamados completa]) || "resumida"
  end

  def new
    @casal = @edicao.casais.build(
      fonte_importacao: :cadastro_manual,
      inscrito_em: Time.zone.now.change(sec: 0),
    )
  end

  def create
    @casal = @edicao.casais.build(casal_params)
    @casal.fonte_importacao = :cadastro_manual

    begin
      if @casal.save
        redirect_to edicao_casais_path(@edicao), notice: t("casais_views.cadastro_secretaria.sucesso")
      else
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique
      flash.now[:alert] = t("casais_views.cadastro_secretaria.duplicado")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:edicao_id])
  end

  def casal_params
    params.require(:casal).permit(
      :nome_completo_ele,
      :nome_completo_ela,
      :apelido_ele,
      :apelido_ela,
      :data_nascimento_ele,
      :data_nascimento_ela,
      :email_contato,
      :telefones_contato,
      :endereco,
      :observacoes,
      :inscrito_em,
    )
  end
end
