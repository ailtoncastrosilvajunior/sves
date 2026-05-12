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

  # Miniatura via Active Storage; se o processador (ex.: libvips) falhar, mostra o original.
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
