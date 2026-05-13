# frozen_string_literal: true

module CenaculosHelper
  # Texto normalizado para filtragem client-side (accent folding quando possível).
  def texto_busca_distribuicao_casal(casal)
    partes = [
      casal.nome_completo_ele,
      casal.nome_completo_ela,
      casal.apelido_ele,
      casal.apelido_ela,
      casal.telefones_contato,
      casal.email_contato,
      casal.endereco,
      casal.caracterizacao_uniao,
      casal.igreja_casamento_e_data,
      casal.teve_casamento_anterior,
      casal.movimentos_ele,
      casal.movimentos_ela,
      casal.filhos_abc_jesus,
      casal.horarios_abc_jesus,
      casal.como_conheceu_seminario,
      casal.fonte_importacao,
      (l(casal.inscrito_em, format: :short) if casal.inscrito_em),
    ].compact_blank
    bruto = partes.join(" ").downcase.gsub(/\s+/, " ").strip
    I18n.transliterate(bruto)
  rescue ArgumentError, I18n::ArgumentError
    bruto
  end

  def resumo_um_linha(texto, length: 120)
    truncate((texto || "").squish, length: length, omission: "…")
  end

  def idade_para_contexto(date)
    return nil unless date.respond_to?(:to_date)

    d = date.to_date
    return nil if d > Date.today

    dias = (Date.today - d).to_i
    anos = dias / 365
    anos.positive? ? "#{anos} anos" : nil
  rescue Date::Error
    nil
  end

  def rotulo_fonte_casal(casal)
    t("casais_views.fontes.#{casal.fonte_importacao}", default: casal.fonte_importacao.to_s.titleize)
  end

  # Miniatura do cartão na lista de cenáculos: foto, ou quadrante colorido, ou inicial.
  # Se há anexo mas o ficheiro não existe no bucket (URL 404), o onerror revela o mesmo placeholder.
  def cenaculo_index_card_miniatura(cenaculo, cor_acento: nil)
    unless cenaculo.imagem.attached?
      return cenaculo_index_card_miniatura_sem_imagem(cenaculo, cor_acento: cor_acento)
    end

    src =
      begin
        url_for(cenaculo.imagem.variant(resize_to_limit: [144, 144]))
      rescue StandardError => e
        Rails.logger.warn("Cenaculo##{cenaculo.id} miniatura (URL): #{e.class}: #{e.message}")
        nil
      end
    return cenaculo_index_card_miniatura_sem_imagem(cenaculo, cor_acento: cor_acento) if src.blank?

    img_sz =
      "[grid-area:stack] z-10 h-[3.35rem] w-[3.35rem] rounded-[calc(1rem-2px)] object-cover transition duration-300 group-hover/card:scale-[1.04] sm:h-[3.65rem] sm:w-[3.65rem]"
    fb_outer =
      "[grid-area:stack] z-0 hidden h-[3.35rem] w-[3.35rem] rounded-[calc(1rem-2px)] p-[3px] transition duration-300 group-hover/card:scale-[1.04] sm:h-[3.65rem] sm:w-[3.65rem] " +
      (cor_acento.present? ? "bg-stone-100 shadow-inner ring-1 ring-black/[0.08]" : "bg-teal-100 shadow-md shadow-teal-900/15 ring-1 ring-teal-300/40")

    grid_shell =
      "grid [grid-template-areas:'stack'] place-items-start rounded-2xl bg-stone-100 p-[3px] shadow-md shadow-stone-900/12 ring-[3px] ring-white transition duration-300 group-hover/card:shadow-lg group-hover/card:shadow-teal-900/10"

    js = '(function(el){var r=el.closest("[data-thumb=\'cenaculo\']");var fb=r&&r.querySelector("[data-thumb-fb]");if(fb){fb.classList.remove("hidden");fb.classList.remove("z-0");fb.classList.add("z-10")}el.remove()})(this)'

    content_tag(:div, class: grid_shell, data: { thumb: "cenaculo" }) do
      safe_join([
        tag.img(
          src: src,
          alt: cenaculo.nome.to_s.truncate(80),
          class: img_sz,
          loading: "lazy",
          decoding: "async",
          onerror: js,
        ),
        content_tag(:div, data: { thumb_fb: true }, class: fb_outer) do
          cenaculo_index_thumb_fallback_inner(cenaculo, cor_acento: cor_acento)
        end,
      ])
    end
  end

  def cenaculo_index_thumb_fallback_inner(cenaculo, cor_acento:)
    inner = "h-full w-full rounded-[calc(1rem-2px)]"
    if cor_acento.present?
      tag.div(class: inner, style: "background-color: #{cor_acento}", aria: { hidden: true })
    else
      tag.div(class: "#{inner} flex items-center justify-center bg-white/95 text-lg font-display font-semibold tracking-tight text-teal-800/55 shadow-inner", aria: { hidden: true }) do
        (cenaculo.nome.to_s.strip[0] || "·").upcase
      end
    end
  end

  def cenaculo_index_card_miniatura_sem_imagem(cenaculo, cor_acento:)
    inner_sz =
      "h-[3.35rem] w-[3.35rem] rounded-[calc(1rem-2px)] transition duration-300 group-hover/card:scale-[1.04] sm:h-[3.65rem] sm:w-[3.65rem]"
    if cor_acento.present?
      content_tag(:div, class: "rounded-2xl bg-stone-100 p-[3px] shadow-md shadow-stone-900/12 ring-[3px] ring-white transition duration-300 group-hover/card:shadow-lg") do
        tag.span(class: "#{inner_sz} block shadow-inner ring-1 ring-black/[0.08]", style: "background-color: #{cor_acento}", aria: { hidden: true })
      end
    else
      content_tag(:div, class: "rounded-2xl bg-teal-100 p-[3px] shadow-md shadow-teal-900/15 ring-[3px] ring-white transition duration-300 group-hover/card:shadow-lg") do
        tag.span(class: "#{inner_sz} flex items-center justify-center bg-white/95 text-lg font-display font-semibold tracking-tight text-teal-800/55 shadow-inner", aria: { hidden: true }) do
          (cenaculo.nome.to_s.strip[0] || "·").upcase
        end
      end
    end
  end

  # Miniatura via Active Storage (show, formulário, etc.); se o processador falhar, mostra o original.
  def cenaculo_imagem_tag(cenaculo, resize_to_limit:, **html_options)
    return "".html_safe unless cenaculo.imagem.attached?

    image_tag cenaculo.imagem.variant(resize_to_limit: resize_to_limit), html_options
  rescue StandardError => e
    Rails.logger.warn("Cenaculo##{cenaculo.id} imagem variant: #{e.class}: #{e.message}")
    image_tag cenaculo.imagem, html_options
  end

  # Pastores ligados ao cenáculo, agrupados por casal quando cônjuge também está no mesmo grupo.
  # @return [Array<String>] linhas como «Nome A · Nome B» ou nome único.
  def linhas_coordenacao_pastoral_cenaculo(cenaculo)
    linhas_servos_agrupados_casal(cenaculo.servos)
  end

  # Agrupa servos por duplas de cônjuges quando ambos estão na mesma lista (ex.: coordenação geral).
  def linhas_servos_agrupados_casal(servos)
    servos = Array(servos).sort_by { |s| s.nome.to_s.downcase }
    ids_no_conjunto = servos.map(&:id).to_set
    consumidos = Set.new
    linhas = []

    servos.each do |s|
      next if consumidos.include?(s.id)

      parceiro_id = s.conjuge_id
      if parceiro_id && ids_no_conjunto.include?(parceiro_id)
        parceiro = servos.find { |x| x.id == parceiro_id }
        consumidos.add(s.id)
        consumidos.add(parceiro_id)
        ord = [s, parceiro].compact.sort_by { |x| x.nome.to_s.downcase }
        linhas << "#{ord.first.nome} · #{ord.second.nome}"
      else
        consumidos.add(s.id)
        linhas << s.nome
      end
    end

    linhas
  end

  # Para colunas homens/mulheres na impressão (sexo M / F registado no servo).
  # @return [Hash] :homens, :mulheres, :sem_sexo — strings já com « · » ou nil
  def pastores_por_sexo_texto_impressao(cenaculo)
    servos = cenaculo.servos.sort_by { |s| s.nome.to_s.downcase }
    com_m = servos.select { |s| s.sexo.to_s == "M" }
    com_f = servos.select { |s| s.sexo.to_s == "F" }
    sem = servos.reject { |s| %w[M F].include?(s.sexo.to_s) }

    {
      homens: com_m.map(&:nome).join(" · ").presence,
      mulheres: com_f.map(&:nome).join(" · ").presence,
      sem_sexo: sem.map(&:nome).join(" · ").presence,
    }
  end

  # Cor na impressão: HEX normalizado (#RRGGBB minúsculo) ou nil.
  def cenaculo_cor_hex_para_impressao(cenaculo)
    Cenaculo.normalizar_hex_cor(cenaculo.cor)
  end

  # Nome da paleta rápida quando o HEX coincide; senão nil (usa só o código na vista).
  def cenaculo_cor_rotulo_impressao(cenaculo)
    hex = cenaculo_cor_hex_para_impressao(cenaculo)
    Cenaculo.rotulo_cor_na_paleta(hex)
  end

  def linhas_casais_participantes_impressao(cenaculo)
    cenaculo.casais.order(:nome_completo_ele).map do |c|
      "#{c.nome_completo_ele.presence || '—'} · #{c.nome_completo_ela.presence || '—'}"
    end
  end
end
