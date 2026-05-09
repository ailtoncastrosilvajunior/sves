class CreateEquipes < ActiveRecord::Migration[8.0]
  def change
    create_table :equipes do |t|
      t.references :edicao, null: false, foreign_key: true
      t.string :nome, null: false

      t.timestamps
    end

    add_index :equipes, %i[edicao_id nome], unique: true
  end
end
