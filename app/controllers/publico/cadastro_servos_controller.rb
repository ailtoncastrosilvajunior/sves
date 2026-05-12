# frozen_string_literal: true

module Publico
  class CadastroServosController < ApplicationController
    skip_before_action :require_login

    def new
      @form = CadastroCasalServosForm.new
    end

    def create
      atributos = cadastro_casal_params.to_unsafe_h
      @form = CadastroCasalServosForm.new(atributos)

      begin
        if @form.save
          redirect_to cadastro_servo_path, notice: I18n.t("cadastro_servos.sucesso")
          return
        end
      rescue ActiveRecord::RecordNotUnique
        @form = CadastroCasalServosForm.new(atributos)
        @form.errors.add(:base, I18n.t("cadastro_servos.email_duplicado"))
      end

      render :new, status: :unprocessable_entity
    end

    private

    def cadastro_casal_params
      lado = CadastroCasalServosForm.participante_param_keys
      params.require(:cadastro_casal).permit(:grupo_de_oracao, dela: lado, dele: lado)
    end
  end
end
