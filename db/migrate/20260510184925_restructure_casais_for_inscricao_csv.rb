# frozen_string_literal: true

# Colunas alinhadas ao export CSV do Google Forms «Inscrição SVES Casais» (ex.: 2026.1).
# Campo +assinatura_linha+ permite reimportações idempotentes por edição (CSV ou planilha).
class RestructureCasaisForInscricaoCsv < ActiveRecord::Migration[8.1]
  def up
    rename_column :casais, :nome_parceiro_a, :nome_completo_ele
    rename_column :casais, :nome_parceiro_b, :nome_completo_ela
    rename_column :casais, :telefone_contato, :telefones_contato
    change_column :casais, :telefones_contato, :text

    add_column :casais, :inscrito_em, :datetime
    add_column :casais, :data_nascimento_ele, :date
    add_column :casais, :apelido_ele, :string
    add_column :casais, :data_nascimento_ela, :date
    add_column :casais, :apelido_ela, :string

    add_column :casais, :endereco, :text

    add_column :casais, :caracterizacao_uniao, :text
    add_column :casais, :igreja_casamento_e_data, :text
    add_column :casais, :teve_casamento_anterior, :string

    add_column :casais, :movimentos_ele, :text
    add_column :casais, :movimentos_ela, :text

    add_column :casais, :filhos_abc_jesus, :text
    add_column :casais, :horarios_abc_jesus, :text

    add_column :casais, :como_conheceu_seminario, :text

    add_column :casais, :url_comprovante_pagamento, :text

    add_column :casais, :fonte_importacao, :string, limit: 24, default: "manual", null: false
    add_column :casais, :assinatura_linha, :string, limit: 128
    add_column :casais, :dados_brutos, :jsonb, default: {}, null: false

    add_index :casais,
              %i[edicao_id assinatura_linha],
              unique: true,
              where: "(assinatura_linha IS NOT NULL AND TRIM(BOTH FROM assinatura_linha) <> '')",
              name: "index_casais_on_edicao_id_and_assinatura_linha_unique"
    add_index :casais, :inscrito_em
    add_index :casais, :fonte_importacao
  end

  def down
    remove_index :casais, name: "index_casais_on_edicao_id_and_assinatura_linha_unique"
    remove_index :casais, :inscrito_em
    remove_index :casais, :fonte_importacao

    remove_column :casais, :dados_brutos
    remove_column :casais, :assinatura_linha
    remove_column :casais, :fonte_importacao

    remove_column :casais, :url_comprovante_pagamento
    remove_column :casais, :como_conheceu_seminario
    remove_column :casais, :horarios_abc_jesus
    remove_column :casais, :filhos_abc_jesus
    remove_column :casais, :movimentos_ela
    remove_column :casais, :movimentos_ele
    remove_column :casais, :teve_casamento_anterior
    remove_column :casais, :igreja_casamento_e_data
    remove_column :casais, :caracterizacao_uniao
    remove_column :casais, :endereco
    remove_column :casais, :apelido_ela
    remove_column :casais, :data_nascimento_ela
    remove_column :casais, :apelido_ele
    remove_column :casais, :data_nascimento_ele
    remove_column :casais, :inscrito_em

    change_column :casais, :telefones_contato, :string
    rename_column :casais, :telefones_contato, :telefone_contato
    rename_column :casais, :nome_completo_ela, :nome_parceiro_b
    rename_column :casais, :nome_completo_ele, :nome_parceiro_a
  end
end
