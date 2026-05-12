# frozen_string_literal: true

# Troca voluntária de senha (utilizador autenticado, com senha actual).
class AlterarSenhasController < ApplicationController
  def edit
  end

  def update
    current_user.reload
    p = alterar_senha_params

    unless current_user.authenticate(p[:current_password])
      current_user.errors.add(:current_password, :invalid)
      render :edit, status: :unprocessable_entity
      return
    end

    if current_user.update(
         password: p[:password],
         password_confirmation: p[:password_confirmation],
         must_change_password: false,
       )
      redirect_to root_path, notice: I18n.t("alterar_senha.flash_ok")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def alterar_senha_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
