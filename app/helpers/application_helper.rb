module ApplicationHelper
  def navegacao_user_label
    return unless user_signed_in?

    s = current_user.servo
    primeiro = s&.nome_para_listagem&.strip&.split(/\s+/)&.first
    primeiro.presence || current_user.email.to_s.split("@").first.presence || current_user.email
  end

  # Preposição perante o nome do cônjuge: «do» (M), «da» (F), «de» sem sexo.
  def sves_conjuge_preposicao(parceiro)
    case parceiro.sexo
    when "M" then "do"
    when "F" then "da"
    else "de"
    end
  end

  # Linha secundária (ex.: «da Liliane») para listagens com nome destacado por cima.
  def sves_conjuge_linha_secundaria(parceiro)
    return unless parceiro

    "#{sves_conjuge_preposicao(parceiro)} #{parceiro.nome_para_listagem}".squeeze(" ").strip
  end

  # Frase completa (ex.: aria-label ou leitores de voz): «Eu sou Ailton da Liliane».
  def apresentacao_sves_com_conjuge(servo)
    parceiro = servo.conjuge || servo.parceiro_conjuge
    return unless parceiro

    "Eu sou #{servo.nome_para_listagem} #{sves_conjuge_preposicao(parceiro)} #{parceiro.nome_para_listagem}".squeeze(" ").strip
  end

  # Identifica qual separador está ativo na navegação móvel (barra inferior).
  def mobile_nav_tab
    path = request.path
    e = edicao_em_curso

    return :sessao if controller_name == "sessions"
    return :apoio if controller_name == "materiais_apoio"
    if pode_gerir_painel?
      return :equipes if path.match?(%r{/edicoes/\d+/equipes}) || path == equipes_em_curso_path
    else
      return :cenaculo if e && path.match?(%r{/edicoes/#{e.id}/cenaculos})
    end
    return :edicao if pode_gerir_painel? && e && path.match?(%r{\A/edicoes/#{e.id}}o) && !path.match?(%r{/edicoes/\d+/equipes})
    return :servos if pode_gerir_painel? && controller_name == "servos"
    return :perfil if !pode_gerir_painel? && controller_name == "servos"
    return :edicoes if pode_gerir_painel? && (path == edicoes_path || path == new_edicao_path)
    return :home if controller_name == "inicio" || path == root_path

    :none
  end

  # Primeiro cenáculo do participante na edição em curso, ou lista se há vários.
  def mobile_nav_cenaculo_href
    return unless user_signed_in? && !pode_gerir_painel? && edicao_em_curso

    escopo = current_user.servo&.cenaculos&.where(edicao_id: edicao_em_curso.id)&.order(:nome)
    return if escopo.blank?

    escopo.one? ? edicao_cenaculo_path(edicao_em_curso, escopo.first) : edicao_cenaculos_path(edicao_em_curso)
  end

  def mobile_nav_grid_class
    pode_gerir_painel? ? "grid-cols-6" : "grid-cols-3"
  end

  def mobile_nav_link_classes(active)
    [
      "tap-none touch-manipulation flex min-w-0 flex-1 flex-col items-center justify-center gap-0.5 rounded-xl px-0.5 py-2",
      "text-[0.5625rem] font-semibold uppercase tracking-wide transition-colors",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-stone-400/70 focus-visible:ring-offset-2 focus-visible:ring-offset-stone-50",
      active ? "bg-stone-200/55 text-stone-900 shadow-sm shadow-stone-900/5" : "text-stone-500 active:bg-stone-100/90 active:text-stone-800",
    ].compact.join(" ")
  end

  def mobile_nav_icon_classes(active)
    active ? "text-stone-900" : "text-stone-400"
  end

  def mobile_edicao_tab_url
    return mobile_nav_cenaculo_href || root_path if user_signed_in? && !pode_gerir_painel?

    edicao_em_curso ? edicao_path(edicao_em_curso) : edicoes_path
  end

  def mobile_nav_aria_current(on_page)
    on_page ? { "aria-current" => "page" } : {}
  end
end
