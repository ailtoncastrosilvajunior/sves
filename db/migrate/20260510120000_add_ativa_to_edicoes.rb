# frozen_string_literal: true

class AddAtivaToEdicoes < ActiveRecord::Migration[8.1]
  def up
    add_column :edicoes, :ativa, :boolean, null: false, default: false

    say_with_time "Definir edição em curso (a mais recente por ano/número)" do
      top = Edicao.order(ano: :desc, numero_edicao: :desc).first
      top&.update_column(:ativa, true)
    end

    add_index :edicoes, :ativa, unique: true, where: "ativa = true", name: "index_edicoes_one_ativa"
  end

  def down
    remove_index :edicoes, name: "index_edicoes_one_ativa"
    remove_column :edicoes, :ativa
  end
end
