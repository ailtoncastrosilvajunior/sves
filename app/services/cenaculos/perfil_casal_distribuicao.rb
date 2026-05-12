# frozen_string_literal: true

module Cenaculos
  class PerfilCasalDistribuicao
    ATTRS_CLUSTER = %i[
      faixa_idade_mediana
      casamento_anterior
      participacao_filhos_abc
      regiao_simples
      referencia_movimentos
      caracterizacao_resumo
    ].freeze

    attr_reader :casal, :rotulos

    def initialize(casal)
      @casal = casal
      @rotulos = montar_rotulos
    end

    def vetor_para_custo
      ATTRS_CLUSTER.index_with { |k| @rotulos.fetch(k) }
    end

    private

    def montar_rotulos
      {
        faixa_idade_mediana: faixa_idade_valor,
        casamento_anterior: marca_casamento_anterior,
        participacao_filhos_abc: filhos_abc_marca,
        regiao_simples: regiao_por_endereco,
        referencia_movimentos: movimentos_presenca,
        caracterizacao_resumo: digest_texto(caracterizacao_txt),
      }
    end

    def caracterizacao_txt
      casal.caracterizacao_uniao.presence&.strip.to_s
    end

    def marca_casamento_anterior
      orig = casal.teve_casamento_anterior.to_s.strip
      return "(sem resposta registada nos dados brutos)." if orig.blank?

      transl = ActiveSupport::Inflector.transliterate(orig).downcase.strip
      afirmativos = %w[sim s yes y]
      negativos = %w[nao n no]
      sim = transl.in?(afirmativos)
      nao =
        transl.in?(negativos) ||
        orig.casecmp("não").zero? ||
        orig.casecmp("nao").zero?

      return "sim (nos dados)." if sim && !nao

      return "nao (nos dados)." if nao && !sim

      orig.truncate(48)
    end

    def anos_de_idade(em)
      return nil if em.blank?

      n = ((Time.zone.today - em.to_date).to_i / 365.25).floor
      n.negative? ? nil : n
    end

    def faixa_idade_valor
      id_ele = anos_de_idade(casal.data_nascimento_ele)
      id_ela = anos_de_idade(casal.data_nascimento_ela)
      idades = [id_ele, id_ela].compact
      return "idade (sem datas completas nos dados)" if idades.blank?

      med = idades.sum.to_f / idades.size
      if med < 40
        "até ~39 anos (média do casal)"
      elsif med < 52
        "~40–51 anos"
      elsif med < 62
        "~52–61 anos"
      else
        "62 anos ou mais"
      end
    end

    def filhos_abc_marca
      t = casal.filhos_abc_jesus.to_s.strip.downcase
      return "sem texto nos dados" if t.blank?

      if %r{\b(nenhum|sem|nao|não|zero|n[\./]?a)\b}.match?(t) && t.length < 80
        "sem declaração de filhos (texto neutro/abreviativo)"
      else
        "com menção textual a filhos (ABC/Jesus)"
      end
    end

    def regiao_por_endereco
      ln = casal.endereco.to_s.each_line.first&.strip
      ln = ln.blank? ? "" : ln.gsub(/\s+/, " ")
      ln = ln.presence&.truncate(112, omission: "")
      ln.present? ? ln.downcase : "endereco nao registado ou vazio"
    end

    def movimentos_presenca
      if casal.movimentos_ele.to_s.strip.present? || casal.movimentos_ela.to_s.strip.present?
        "referencias de movimento indicadas"
      else
        "sem referencias breves nos campos «movimento» dos dados importados"
      end
    end

    def digest_texto(texto)
      return "campo caracterizacao vazio nos dados exportados do formulario." if texto.blank?

      texto.downcase.gsub(/\s+/, " ").truncate(144, omission: "")
    end
  end
end
