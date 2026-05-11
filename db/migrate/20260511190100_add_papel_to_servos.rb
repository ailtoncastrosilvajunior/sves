# frozen_string_literal: true

class AddPapelToServos < ActiveRecord::Migration[8.1]
  def change
    add_column :servos, :papel, :string, default: "coordenacao", null: false
  end
end
