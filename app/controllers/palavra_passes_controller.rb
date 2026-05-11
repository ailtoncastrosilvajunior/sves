# frozen_string_literal: true

class PalavraPassesController < ApplicationController
  def edit
  end

  def update
    if current_user.update(palavra_passe_params.merge(must_change_password: false))
      redirect_to root_path, notice: I18n.t("palavra_passes.flash_atualizada")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def palavra_passe_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
