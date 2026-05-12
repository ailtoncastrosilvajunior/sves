# frozen_string_literal: true

class CreateCenaculoPresencaReunioes < ActiveRecord::Migration[8.0]
  def change
    create_table :cenaculo_presenca_reunioes do |t|
      t.references :edicao_reuniao_cenaculo, null: false, foreign_key: { to_table: :edicao_reuniao_cenaculos }
      t.references :cenaculo, null: false, foreign_key: true
      t.references :casal, null: false, foreign_key: true
      t.boolean :presente_ele, null: false, default: false
      t.boolean :presente_ela, null: false, default: false

      t.timestamps
    end

    add_index :cenaculo_presenca_reunioes,
              %i[edicao_reuniao_cenaculo_id casal_id],
              unique: true,
              name: "idx_presenca_reuniao_casal_unique"
    add_index :cenaculo_presenca_reunioes, %i[cenaculo_id edicao_reuniao_cenaculo_id]
  end
end
