# frozen_string_literal: true

require "digest"

module Cenaculos
  class DistribuidorSugestao
    LegendaDimensao = {
      faixa_idade_mediana: "Faixa etária média inferida pelas datas de nascimento.",
      casamento_anterior: "Campo «teve casamento anterior» apenas como marca simples.",
      participacao_filhos_abc: "Trecho textual «filhos ABC/Jesus» tratado grosso modo.",
      regiao_simples: "Primeira linha textual do campo endereco (aproxima região/local).",
      referencia_movimentos: "Movimento(s) relatados como presentes ou ausentes na ficha importada.",
      caracterizacao_resumo: "Excerto inicial do texto sobre a união, para dispersar repetições literais.",
    }.freeze

    ResultadoGrupo = Data.define(
      :numero,
      :membros,
      :introducao,
      :resumo_dimensao,
      :explicacao_por_casal,
    )

    Resultado = Data.define(
      :edicao_rotulo,
      :casais_por_grupo,
      :total_casais,
      :quantidade_grupos,
      :gerado_em,
      :texto_regra,
      :somente_sem_cenaculo,
      :semilla_observacao,
      :nome_ficheiro,
      :grupos,
    )

    def self.texto_padrao_regra(i18n: I18n)
      i18n.t(
        "cenaculos.distribuicao_sugestao.texto_regra_padrao_html",
        default:
          '<p><strong>Unidade pastoral</strong>: agrupamentos com <strong>casais ínteiros</strong> («uma só carne»).</p>' \
          '<p><strong>Heterogeneidade</strong>: marcas apenas dos campos existentes nas fichas (idades agregadas, casamento anterior, filhos ABC, endereco, movimentos e excerto sobre a união).</p>' \
          '<p><strong>Encontros por gênero</strong>: quando homens e mulheres reunem separadamente, <strong>cada lado continua a pertencer aos mesmos casais participantes e ao mesmo cenáculo</strong>; o casal pastor escolhido manualmente deve ser sempre o mesmo para esses membros.</p>',
      )
    end

    def initialize(casais, casais_por_grupo:, semente:, texto_regra:, rotulo_edicao:, somente_sem_cenaculo: false)
      @lista = Array(casais)
      @n = @lista.size
      @tam_meta = Integer(casais_por_grupo)
      @semente_txt = semente&.to_s
      @texto_regra_html = texto_regra.to_s
      @rotulo = rotulo_edicao.to_s.strip
      @somente_sem = ActiveModel::Type::Boolean.new.cast(somente_sem_cenaculo)
    end

    # @return [Cenaculos::DistribuidorSugestao::Resultado]
    def resultado
      validar_entradas!

      rng, texto_semilla = inicializar_rng
      ordem = @lista.shuffle(random: rng)
      perfil_por = {}
      ordem.each { |c| perfil_por[c] = PerfilCasalDistribuicao.new(c) }

      grupos_tot = (@n.to_f / @tam_meta).ceil
      grupos_tot = 1 if grupos_tot < 1
      caps = quotas(@n, grupos_tot)

      slots = Array.new(grupos_tot) { [] }
      contadores = Array.new(grupos_tot) { Hash.new { |h, atr| h[atr] = Hash.new(0) } }

      ordem.each do |casal|
        vetores = perfil_por.fetch(casal).vetor_para_custo

        escolhas = grupos_tot.times.filter_map do |idx|
          next if slots[idx].size >= caps[idx]

          penal = pena_marginal(vetores, contadores[idx])
          [idx, penal]
        end

        idx_escolha =
          escolhas.min_by { |(idx, penalidade)| [penalidade, idx] }&.first || 0

        slots[idx_escolha] << casal

        vetores.each { |atr, valor| contadores[idx_escolha][atr][valor] += 1 }
      end

      edicao_wide = contagens(perfil_por.values)

      blocos_grupo =
        slots.map.with_index(1).filter_map do |membros, ord|
          next if membros.empty?

          conta_local = contagens(membros.map { |c| perfil_por.fetch(c) })
          gz = membros.size
          parejas =
            membros.map do |c|
              perf = perfil_por.fetch(c)
              {
                nome: nome_expositivo_do_casal(c),
                linhas:
                  texto_motivos_casal(perf, conta_local, gz, edicao_wide, @n),
              }
            end

          ResultadoGrupo.new(
            numero: ord,
            membros: membros,
            introducao: texto_intro_grupo(conta_local, edicao_wide, gz, @n),
            resumo_dimensao: texto_histograma(conta_local),
            explicacao_por_casal: parejas,
          )
        end

      slug =
        ActiveSupport::Inflector
          .parameterize("#{@rotulo}-sugestao-cenaculos", separator: "_")
          .presence || "sugestao_cenaculos"

      Resultado.new(
        edicao_rotulo: @rotulo.presence || "Edição SVES",
        casais_por_grupo: @tam_meta,
        total_casais: @n,
        quantidade_grupos: blocos_grupo.size,
        gerado_em: Time.zone.now,
        texto_regra: @texto_regra_html,
        somente_sem_cenaculo: @somente_sem,
        semilla_observacao: texto_semilla,
        nome_ficheiro: "#{slug}-#{Time.zone.now.strftime('%Y%m%d_%H%M')}.html",
        grupos: blocos_grupo,
      )
    end

    private

    def validar_entradas!
      if @n < 2
        raise ArgumentError,
              "Cadastre pelo menos dois casais nesta edição antes da sugestão automática."
      end

      return if (@tam_meta).between?(2, @n)

      raise ArgumentError, "Limite deve permanecer entre 2 casais por grupo e #{@n}."

    end

    # @return [Random, String]
    def inicializar_rng
      bruto = @semente_txt.to_s.strip
      if bruto.empty?
        r = Random.new
        texto = "embaralhamento pseudo‑aleatorio; o número seguinte permite repetir esta ordem: #{r.seed}."
        return [r, texto]
      elsif bruto.match?(/\A-?\d+\z/)
        s = Integer(bruto)
        return [Random.new(s), "semente inteira fornecida: #{s}."]
      end

      inteiro_derivado =
        Digest::SHA256.digest(ActiveSupport::Inflector.transliterate(bruto))
          .unpack1("q<")

      texto = "semente texto convertida de forma determinística antes da mistura inicial."
      [Random.new(inteiro_derivado), texto]
    end

    # Primeiros «resto» grupos recebem tamanho (quociente + 1), demais apenas quociente.
    def quotas(total_casais, numero_grupos)
      numero_grupos = 1 if numero_grupos < 1

      quotient, leftover = total_casais.divmod(numero_grupos)
      numero_grupos.times.map do |idx|
        idx < leftover ? quotient + 1 : quotient
      end
    end

    def pena_marginal(perfil_linear, conta_grupo_hash)
      perfil_linear.sum do |atri, marca|
        conta_grupo_hash[atri][marca]
      end
    end

    def contagens(lista_perfis)
      resultado = Hash.new { |memo, atr| memo[atr] = Hash.new(0) }

      lista_perfis.each do |perf|
        perf.vetor_para_custo.each do |atri, marca|
          resultado[atri][marca] += 1
        end
      end

      resultado
    end

    def texto_intro_grupo(conta_local_hash, conta_edicao_wide, gz, quantidade_na_base)
      texto = []

      [:faixa_idade_mediana, :regiao_simples].each do |dim|
        conta_local_hash.fetch(dim).each do |valor_etiqueta, qty|
          proporcao_na_edicao =
            quantidade_na_base.positive? ? conta_edicao_wide.fetch(dim)[valor_etiqueta].to_f / quantidade_na_base : 0.0
          esperados_no_grupo = proporcao_na_edicao * gz
          discrepancia = qty - esperados_no_grupo
          next if discrepancia.abs < 1.0

          sentido =
            if discrepancia.positive?
              "acima da proporção esperada só pelos registos da edição usada aqui."
            else
              "abaixo da proporção que resultaria apenas replicar a distribuição global proporcionalmente a este grupo."
            end

          texto <<
            "#{LegendaDimensao.fetch(dim)} — «#{valor_etiqueta}» apareceu #{qty}x neste cenário (#{gz} casais): #{sentido}"
        end
        break if texto.size >= 3
      end

      texto <<
        "A sugestão trata apenas casais ínteiros; encontros por sexo continuam no mesmo cenáculo pastoral — esta ferramenta não indica um casal pastor."

      texto.compact_blank.uniq.first(12)
    end

    def texto_histograma(conta_hash)
      PerfilCasalDistribuicao::ATTRS_CLUSTER.map do |dim|
        valores = conta_hash.fetch(dim)

        formato =
          valores
            .sort_by { |marca_texto, contagem| [-contagem, marca_texto.to_s] }
            .filter_map do |marca_texto, contagem|
              mar = marca_texto.to_s.strip
              next if mar.blank? || contagem.zero?

              "#{mar.truncate(88)} ⇒ #{contagem}x"
            end
            .join("; ")



        "#{LegendaDimensao.fetch(dim)} — #{formato.presence || "(sem combinações observadas)"}"

      end
    end


    def texto_motivos_casal(perfil_obj, conta_grupo_hash, gz, global_hash, quantidade_na_base_total)
      vetores = perfil_obj.vetor_para_custo


      PerfilCasalDistribuicao::ATTRS_CLUSTER.first(5).map do |dim|
        marca_visual = vetores.fetch(dim)
        contagem_interna = conta_grupo_hash.fetch(dim).fetch(marca_visual)
        proporcao_grupo_pct = gz.positive? ? (contagem_interna.to_f / gz * 100).round : 0


        proporcao_total_pct =
          if quantidade_na_base_total.positive?
            (global_hash.fetch(dim).fetch(marca_visual).to_f / quantidade_na_base_total * 100).round
          else


            0
          end




        "#{LegendaDimensao.fetch(dim)} — «#{marca_visual.to_s.truncate(80)}» aparece #{contagem_interna}x entre estes #{gz} casais sugeridos " \
          "(internamente ≈#{proporcao_grupo_pct}%, enquanto o conjunto trabalhado registra ≈#{proporcao_total_pct}%)."






      end
    end




    def nome_expositivo_do_casal(registro_sves)
      primeiro = registro_sves.nome_completo_ele.presence || registro_sves.apelido_ele.presence || "Companheiro"
      segundo =
        registro_sves.nome_completo_ela.presence || registro_sves.apelido_ela.presence || "Companheira"
      "#{primeiro} · #{segundo}"
    end
  end
end
