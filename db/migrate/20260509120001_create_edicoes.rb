class CreateEdicoes < ActiveRecord::Migration[8.0]
  def change
    create_table :edicoes do |t|
      t.integer :ano, null: false
      t.integer :numero_edicao, null: false
      t.string :link_planilha

      t.timestamps
    end

    add_index :edicoes, %i[ano numero_edicao], unique: true
  end
end
