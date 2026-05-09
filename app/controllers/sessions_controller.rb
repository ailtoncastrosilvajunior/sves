class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create destroy]
  before_action :redirect_logged_in_guests!, only: :new

  def new
  end

  def create
    dados = sessao_params
    utilizador = User.find_by(email: User.normalize_email(dados[:email]))
    authenticated = utilizador&.authenticate(dados[:password])

    unless authenticated
      flash.now[:alert] = I18n.t("sessions.credentials_invalid")
      render :new, status: :unprocessable_entity
      return
    end

    iniciar_sessao_para(utilizador)
    redirect_para = session.delete(:return_to_after_login).presence || root_path
    redirect_to redirect_para, notice: I18n.t("sessions.flash_signed_in")
  end

  def destroy
    reset_session
    redirect_to root_path, notice: I18n.t("sessions.flash_signed_out"), status: :see_other
  end

  private

  def redirect_logged_in_guests!
    redirect_to(session.delete(:return_to_after_login) || root_url) if user_signed_in?
  end

  def sessao_params
    params.require(:session).permit(:email, :password)
  end

  def iniciar_sessao_para(user)
    reset_session
    session[:user_id] = user.id
  end
end
