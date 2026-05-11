class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Authentication
  include AutorizacaoPainel

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :edicao_em_curso

  def edicao_em_curso
    @edicao_em_curso ||= Edicao.em_curso_primaria
  end
end
