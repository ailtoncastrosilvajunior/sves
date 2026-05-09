# frozen_string_literal: true

require "csv"

module Casais
  # Esqueleto de importação recorrente (upload CSV ou job agendado).
  # A UI pode listar «arquivo CSV» vs «planilha Google» e chamar esta API com IO adequado.
  class ImportadorCsvInscricao
    def self.importar!(edicao:, io:, nome_arquivo: nil)
      fonte = :arquivo_csv
      criados = 0
      atualizados = 0

      csv = CSV.new(
        io,
        headers: true,
        liberal_parsing: true,
        header_converters: nil,
        encoding: "bom|UTF-8",
      )
      csv.each do |row|
        attrs = Casais::MapeamentoInscricaoSves.linha_para_atributos(row)
        attrs[:edicao_id] = edicao.id
        attrs[:fonte_importacao] = fonte

        ele = attrs[:nome_completo_ele].presence
        ela = attrs[:nome_completo_ela].presence
        next if ele.blank? || ela.blank?

        tempo = attrs[:inscrito_em].presence || Time.current
        sig = Casais::MapeamentoInscricaoSves.assinatura_linha(
          edicao_id: edicao.id,
          nome_completo_ele: ele,
          nome_completo_ela: ela,
          inscrito_em: tempo,
        )
        attrs[:assinatura_linha] = sig
        attrs[:inscrito_em] ||= tempo

        registro = Casal.find_or_initialize_by(edicao_id: edicao.id, assinatura_linha: sig)
        novo = registro.new_record?
        registro.assign_attributes(attrs)
        registro.save!
        novo ? (criados += 1) : (atualizados += 1)
      end

      { criados: criados, atualizados: atualizados, nome_arquivo: nome_arquivo }
    end
  end
end
