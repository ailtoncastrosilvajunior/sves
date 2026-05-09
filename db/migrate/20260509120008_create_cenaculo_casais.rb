class CreateCenaculoCasais < ActiveRecord::Migration[8.0]
  def change
    create_table :cenaculo_casais do |t|
      t.references :cenaculo, null: false, foreign_key: true
      t.references :casal_participante, null: false, foreign_key: { to_table: :casais_participantes }

      t.timestamps
    end

    add_index :cenaculo_casais, %i[cenaculo_id casal_participante_id], unique: true, name: "index_cenaculo_casais_unique"
  end
end
