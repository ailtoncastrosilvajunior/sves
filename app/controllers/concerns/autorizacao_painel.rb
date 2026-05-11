# frozen_string_literal: true

# Regras: utilizador +admin+ tem poderes de coordenação no painel e serve para regras exclusivas de administrador.
# «Coordenação» (servo) gere o painel; «participante» vê só a edição em curso, o(s) cenáculo(s)
# onde figura como pastor e materiais públicos activos. Utilizador sem +servo+ tratado como coordenação.
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
    s.nil? || s.coordenacao?
  end

  def servo_participante?
    return false if current_user&.admin?

    current_user&.servo&.participante?
  end

  def negar_se_nao_coordenacao!
    return if pode_gerir_painel?

    redirect_to redirecionamento_apos_negacao!, alert: I18n.t("autorizacao.apenas_coordenacao")
  end

  def redirecionamento_apos_negacao!
    return root_path unless edicao_em_curso && current_user.servo

    if current_user.servo.cenaculos.exists?(edicao_id: edicao_em_curso.id)
      edicao_path(edicao_em_curso)
    else
      root_path
    end
  end

  def participante_pode_ver_edicao?(edicao)
    return true if pode_gerir_painel?

    edicao.ativa? && current_user.servo&.cenaculos&.exists?(edicao_id: edicao.id)
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

    if edicao_em_curso && participante_pode_ver_edicao?(edicao_em_curso)
      redirect_to edicao_path(edicao_em_curso)
    else
      redirect_to root_path, alert: I18n.t("autorizacao.sem_cenaculo_nesta_edicao")
    end
  end

  def garantir_acesso_cenaculos_na_edicao!
    return if pode_gerir_painel?

    unless @edicao.ativa?
      redirect_to root_path, alert: I18n.t("autorizacao.participante_so_edicao_em_curso")
      return
    end

    unless current_user.servo&.cenaculos&.exists?(edicao_id: @edicao.id)
      redirect_to root_path, alert: I18n.t("autorizacao.sem_cenaculo_nesta_edicao")
    end
  end

  def garantir_cenaculo_do_participante!
    return if pode_gerir_painel?

    unless @cenaculo.servos.exists?(id: current_user.servo.id)
      redirect_to edicao_cenaculos_path(@edicao), alert: I18n.t("autorizacao.cenaculo_nao_autorizado")
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
