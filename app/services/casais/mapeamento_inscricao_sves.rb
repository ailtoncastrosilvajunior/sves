# frozen_string_literal: true

require "digest"

module Casais
  # Mapeamento dos cabecalhos do CSV export do Google Forms «Inscrição SVES Casais» ↔ modelo +Casal+.
  # Serve de base igual para importação CSV local ou cópia a partir da planilha Google (mesmas colunas).
  class MapeamentoInscricaoSves
    BOM_UTF8 = "\uFEFF"

    CABECALHO_PARA_CAMPO = {
      "Carimbo de data/hora" => :inscrito_em,
      "Nome completo (ele):" => :nome_completo_ele,
      "Data de nascimento (ele):" => :data_nascimento_ele,
      "Como gostaria de ser chamado (ele)?" => :apelido_ele,
      "Nome completo (ela):" => :nome_completo_ela,
      "Data de nascimento (ela):" => :data_nascimento_ela,
      "Como gostaria de ser chamada (ela)?" => :apelido_ela,
      "Endereço:" => :endereco,
      "Telefones para contato (especificar os nomes)" => :telefones_contato,
      "Como se caracteriza a sua união:" => :caracterizacao_uniao,
      "Igreja onde casaram e data " => :igreja_casamento_e_data,
      "Teve casamento anterior?" => :teve_casamento_anterior,
      "Participa de algum dos movimentos abaixo? (ele)" => :movimentos_ele,
      "Participa de algum dos movimentos abaixo? (ela)" => :movimentos_ela,
      "Se você tem filhos entre 2-10 anos e está preocupado sem saber como vai ficar o final de semana, pode ficar tranquilo, que pensamos em cada detalhe pra família inteira. Teremos ao longo do final de semana um espaço de evangelização para as crianças, o Abc de Jesus. E para melhor organizarmos, escreva abaixo a idade e o nome de cada um deles." => :filhos_abc_jesus,
      "Ainda sobre o Abc de Jesus, marque abaixo os horários em que eles estarão presentes.\n" => :horarios_abc_jesus,
      "Como ficaram sabendo do Seminário de Vida no Espírito Santo?" => :como_conheceu_seminario,
      "Anexar o comprovante de pagamento" => :url_comprovante_pagamento,
    }.freeze

    CABECALHOS_VARIANTES =
      CABECALHO_PARA_CAMPO.each_with_object({}) do |(rotulo, campo), memo|
        [rotulo, rotulo.strip, "#{rotulo.strip}\n"].each { |variant| memo[variant] = campo }
      end.freeze

    # @param linha [CSV::Row, Hash]
    # @return [Hash] chaves são atributos de +Casal+ (exceto edicao_id, fonte_importacao — preencher no importador).
    def self.linha_para_atributos(linha)
      bruto = {}
      attrs = {}

      enumerar_linha(linha) do |cabecalho_original, valor|
        cab = texto_utf8(cabecalho_original)
        sem_bom = cab.delete_prefix(BOM_UTF8)
        campo =
          CABECALHOS_VARIANTES[sem_bom] ||
          CABECALHOS_VARIANTES[sem_bom.strip] ||
          CABECALHOS_VARIANTES["#{sem_bom.strip}\n"]

        rotulo_limpo = sem_bom.strip
        bruto[rotulo_limpo] = texto_utf8(valor)
        next unless campo

        attrs[campo] = converter(campo, texto_utf8(valor))
      end

      attrs[:dados_brutos] = bruto.compact_blank if bruto.any?
      attrs
    end

    def self.enumerar_linha(linha)
      if linha.is_a?(Hash)
        linha.each { |chave, v| yield texto_utf8(chave), texto_utf8(v) }
      elsif linha.respond_to?(:each)
        linha.each do |cab, val|
          # CSV::Row#each faz yield de [cabecalho, valor]; em Ruby o bloco |(cab,val)| faz splat implícito.
          yield texto_utf8(cab), texto_utf8(val)
        end
      end
    end
    private_class_method :enumerar_linha

    def self.texto_utf8(valor)
      return +"" if valor.nil?

      s = valor.is_a?(String) ? valor.dup : +valor.to_s

      if s.encoding == Encoding::UTF_8
        return s if s.valid_encoding?

        return s.encode(Encoding::UTF_8, Encoding::WINDOWS_1252, invalid: :replace, undef: :replace)
      end

      if s.encoding == Encoding::ASCII_8BIT || s.encoding == Encoding::BINARY
        u = s.dup.force_encoding(Encoding::UTF_8)
        return u if u.valid_encoding?

        return s.encode(Encoding::UTF_8, Encoding::WINDOWS_1252, invalid: :replace, undef: :replace)
      end

      s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)

    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
      s.force_encoding(Encoding::UTF_8).scrub
    end

    def self.converter(campo, valor)
      str = valor.to_s.strip
      return nil if str.blank?

      case campo
      when :inscrito_em
        parse_datetime(str)
      when :data_nascimento_ele, :data_nascimento_ela
        parse_date_iso(str)
      when :nome_completo_ele, :nome_completo_ela
        normalizar_nome_completo_importacao(str)
      else
        str
      end
    end

    def self.normalizar_nome_completo_importacao(str)
      str.gsub(/\s+/, " ").upcase
    end

    # Mesmo padrão aplicado na importação CSV (maiúsculas, espaços colapsados).
    def self.aplicar_padrao_nome_completo_participante(valor)
      str = texto_utf8(valor).strip
      return nil if str.blank?

      normalizar_nome_completo_importacao(str)
    end

    def self.parse_datetime(str)
      t = Time.zone.parse(str)
      t&.in_time_zone
    rescue ArgumentError, TypeError
      nil
    end

    def self.parse_date_iso(str)
      Date.iso8601(str)
    rescue ArgumentError
      Date.parse(str)
    rescue ArgumentError, TypeError
      nil
    end

    private_class_method :converter, :normalizar_nome_completo_importacao, :parse_datetime, :parse_date_iso, :texto_utf8

    # Hash estável por edição para não duplicar linhas quando o CSV ou a planilha é reimportada.
    def self.assinatura_linha(edicao_id:, nome_completo_ele:, nome_completo_ela:, inscrito_em:)
      e = texto_utf8(nome_completo_ele).downcase.gsub(/\s+/, " ").strip
      a = texto_utf8(nome_completo_ela).downcase.gsub(/\s+/, " ").strip
      base = [
        edicao_id.to_i,
        e,
        a,
        inscrito_em.respond_to?(:utc) ? inscrito_em.utc.iso8601(6) : inscrito_em.to_s,
      ].join("::")
      Digest::SHA256.hexdigest(base)
    end
  end
end
