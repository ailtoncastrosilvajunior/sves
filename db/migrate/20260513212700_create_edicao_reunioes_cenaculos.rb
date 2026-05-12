# frozen_string_literal: true

class CreateEdicaoReunioesCenaculos < ActiveRecord::Migration[8.0]
  def change
    create_table :edicao_reuniao_cenaculos do |t|
      t.references :edicao, null: false, foreign_key: true
      t.string :titulo, null: false
      t.text :descricao
      t.integer :ordem, null: false, default: 0
      t.string :estado, null: false, default: "em_preparacao"

      t.timestamps
    end

    add_index :edicao_reuniao_cenaculos, %i[edicao_id ordem], order: { ordem: :asc }
    add_index :edicao_reuniao_cenaculos, %i[edicao_id estado]
  end
end
