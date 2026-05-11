# frozen_string_literal: true

module Publico
  class CadastroServosController < ApplicationController
    skip_before_action :require_login

    def new
      @servo = Servo.new(origem_cadastro: Servo::ORIGEM_PUBLICO)
    end

    def create
      atributos = params.require(:servo).permit(:nome, :email, :telefone, :sexo)
      email_norm = User.normalize_email(atributos[:email])

      if email_norm.blank?
        @servo = Servo.new(atributos.merge(origem_cadastro: Servo::ORIGEM_PUBLICO))
        @servo.errors.add(:email, I18n.t("cadastro_servos.email_obrigatorio"))
        render :new, status: :unprocessable_entity
        return
      end

      @servo = Servo.find_by_normalized_email(email_norm)

      if @servo&.user_id.present?
        @servo = Servo.new(atributos.merge(origem_cadastro: Servo::ORIGEM_PUBLICO))
        @servo.errors.add(:base, I18n.t("cadastro_servos.ja_tem_acesso"))
        render :new, status: :unprocessable_entity
        return
      end

      if @servo
        @servo.assign_attributes(atributos.merge(origem_cadastro: Servo::ORIGEM_PUBLICO))
      else
        @servo = Servo.new(atributos.merge(origem_cadastro: Servo::ORIGEM_PUBLICO))
      end

      if @servo.save
        redirect_to cadastro_servo_path, notice: I18n.t("cadastro_servos.sucesso")
      else
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique
      @servo = Servo.new(atributos.merge(origem_cadastro: Servo::ORIGEM_PUBLICO))
      @servo.errors.add(:email, I18n.t("cadastro_servos.email_duplicado"))
      render :new, status: :unprocessable_entity
    end
  end
end
