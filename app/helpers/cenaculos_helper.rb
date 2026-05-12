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
end
