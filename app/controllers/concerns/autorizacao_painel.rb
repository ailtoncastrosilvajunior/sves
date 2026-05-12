# frozen_string_literal: true

# Regras: utilizador +admin+ tem poderes de coordenação no painel e serve para regras exclusivas de administrador.
# «Coordenação» (servo) gere o painel; «participante» vê só o(s) cenáculo(s) onde figura como pastor
# e materiais públicos activos. +admin+ tem poderes de coordenação. Sem perfil +servo+ não gere o painel
# (exceto +admin+).
module AutorizacaoPainel
  extend ActiveSupport::Concern

  included do
    helper_method :pode_gerir_painel?, :servo_participante?, :administrador?
  end

  private

  def administrador?
    current_user&.admin?
  end

  def pode_gerir_painel?
    return true if current_user&.admin?

    s = current_user&.servo
    return false if s.nil?

    s.coordenacao?
  end

  def servo_participante?
    return false if current_user&.admin?

    current_user&.servo&.participante?
  end

  def negar_se_nao_coordenacao!
    return if pode_gerir_painel?

    redirect_to redirecionamento_apos_negacao!, alert: I18n.t("autorizacao.apenas_coordenacao")
  end

  def negar_se_nao_administrador!
    return if administrador?

    redirect_back fallback_location: root_path, alert: I18n.t("autorizacao.apenas_administrador")
  end

  def redirecionamento_apos_negacao!
    s = current_user&.servo
    return root_path if s.blank? || edicao_em_curso.blank?

    c = s.cenaculos.where(edicao_id: edicao_em_curso.id).order(:nome)
    if c.exists?
      c.one? ? edicao_cenaculo_path(edicao_em_curso, c.first) : edicao_cenaculos_path(edicao_em_curso)
    else
      root_path
    end
  end

  def participante_pode_ver_edicao?(edicao)
    return true if pode_gerir_painel?

    edicao.ativa? && current_user.servo&.cenaculos&.exists?(edicao_id: edicao.id)
  end

  def destino_cenaculos_participante_na_edicao(edicao)
    s = current_user&.servo
    return root_path if edicao.blank? || s.blank?

    c = s.cenaculos.where(edicao_id: edicao.id).order(:nome)
    return root_path unless c.exists?

    c.one? ? edicao_cenaculo_path(edicao, c.first) : edicao_cenaculos_path(edicao)
  end

  def garantir_acesso_show_edicao!
    return if participante_pode_ver_edicao?(@edicao)

    redirect_to root_path,
                alert:
                  if !@edicao.ativa?
                    I18n.t("autorizacao.participante_so_edicao_em_curso")
                  else
                    I18n.t("autorizacao.sem_cenaculo_nesta_edicao")
                  end
  end

  def redirecionar_participante_da_lista_edicoes!
    return if pode_gerir_painel?

    e = edicao_em_curso
    s = current_user&.servo
    if e.blank? || s.blank? || !participante_pode_ver_edicao?(e)
      redirect_to root_path, alert: I18n.t("autorizacao.sem_cenaculo_nesta_edicao_or_sem_edicao")
      return
    end

    c = s.cenaculos.where(edicao_id: e.id).order(:nome)
    redirect_to (c.one? ? edicao_cenaculo_path(e, c.first) : edicao_cenaculos_path(e))
  end

  # Participante nunca vê a ficha completa da edição — só os seus cenáculos.
  def redirecionar_participante_para_os_seus_cenaculos!
    return if pode_gerir_painel?

    unless @edicao.ativa?
      redirect_to root_path, alert: I18n.t("autorizacao.participante_so_edicao_em_curso")
      return
    end

    s = current_user&.servo
    if s.blank?
      redirect_to root_path, alert: I18n.t("autorizacao.sem_perfil_servo")
      return
    end

    c = s.cenaculos.where(edicao_id: @edicao.id).order(:nome)
    unless c.exists?
      redirect_to root_path, alert: I18n.t("autorizacao.sem_cenaculo_nesta_edicao")
      return
    end

    redirect_to (c.one? ? edicao_cenaculo_path(@edicao, c.first) : edicao_cenaculos_path(@edicao)),
                status: :see_other
  end

  def garantir_acesso_cenaculos_na_edicao!
    return if pode_gerir_painel?

    unless @edicao.ativa?
      redirect_to root_path, alert: I18n.t("autorizacao.participante_so_edicao_em_curso")
      return
    end

    s = current_user.servo
    if s.blank? || !s.cenaculos.exists?(edicao_id: @edicao.id)
      redirect_to root_path, alert: I18n.t("autorizacao.sem_cenaculo_nesta_edicao")
    end
  end

  def garantir_cenaculo_do_participante!
    return if pode_gerir_painel?

    s = current_user.servo
    if s.blank? || !@cenaculo.servos.exists?(id: s.id)
      redirect_to destino_cenaculos_participante_na_edicao(@edicao),
                  alert: I18n.t("autorizacao.cenaculo_nao_autorizado")
    end
  end

  def garantir_servo_apenas_proprio_ou_coordenacao!
    return if pode_gerir_painel?

    s = current_user.servo
    permitidos = s ? Servo.ids_do_casal_incluindo(s) : []
    unless permitidos.include?(@servo.id)
      redirect_to root_path, alert: I18n.t("autorizacao.servo_apenas_perfil_proprio")
    end
  end
end
