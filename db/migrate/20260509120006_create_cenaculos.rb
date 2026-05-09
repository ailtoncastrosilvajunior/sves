class CreateCenaculos < ActiveRecord::Migration[8.0]
  def change
    create_table :cenaculos do |t|
      t.references :edicao, null: false, foreign_key: true
      t.string :nome, null: false
      t.string :cor, limit: 32

      t.timestamps
    end

    add_index :cenaculos, %i[edicao_id nome], unique: true
  end
end
