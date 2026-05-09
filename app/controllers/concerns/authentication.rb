# Autenticação por sessão (cookie). `SessionsController`, `InicioController` fazem skip de `require_login`.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_login
    helper_method :current_user, :user_signed_in?
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id].present?
  end

  def user_signed_in?
    current_user.present?
  end

  def require_login
    return if user_signed_in?

    guard_return_path_for_get!
    redirect_to new_session_path, alert: I18n.t("sessions.require_login_flash")
  end

  # Armazena destino apenas para GET; evita abrir formulários grandes em POST repetido na volta.
  def guard_return_path_for_get!
    return unless request.get?

    return if skip_store_return_after_login?

    session[:return_to_after_login] = request.fullpath
  end

  def skip_store_return_after_login?
    request.path.start_with?(new_session_path)
  end
end
