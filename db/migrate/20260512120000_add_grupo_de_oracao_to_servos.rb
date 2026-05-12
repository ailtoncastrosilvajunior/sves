# frozen_string_literal: true

class AddGrupoDeOracaoToServos < ActiveRecord::Migration[8.0]
  def change
    add_column :servos, :grupo_de_oracao, :string
  end
end
