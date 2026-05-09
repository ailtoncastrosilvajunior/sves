# frozen_string_literal: true

class RenameEquipesServosToEquipeServos < ActiveRecord::Migration[8.1]
  def change
    rename_table :equipes_servos, :equipe_servos
  end
end
