# frozen_string_literal: true

class CreateMateriaisApoio < ActiveRecord::Migration[8.1]
  def change
    create_table :material_apoios do |t|
      t.string :titulo, null: false
      t.text :descricao
      t.boolean :ativo, default: true, null: false
      t.integer :ordem, default: 0, null: false

      t.timestamps
    end

    add_index :material_apoios, :ativo
    add_index :material_apoios, [:ordem, :titulo], name: "index_material_apoios_on_ordem_and_titulo"
  end
end
