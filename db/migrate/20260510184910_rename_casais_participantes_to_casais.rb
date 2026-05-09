# frozen_string_literal: true

class RenameCasaisParticipantesToCasais < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :cenaculo_casais, :casais_participantes
    remove_foreign_key :casais_participantes, :edicoes

    rename_table :casais_participantes, :casais
    rename_column :cenaculo_casais, :casal_participante_id, :casal_id

    add_foreign_key :casais, :edicoes
    add_foreign_key :cenaculo_casais, :casais, column: :casal_id
  end

  def down
    remove_foreign_key :cenaculo_casais, column: :casal_id
    remove_foreign_key :casais, column: :edicao_id

    rename_column :cenaculo_casais, :casal_id, :casal_participante_id
    rename_table :casais, :casais_participantes

    add_foreign_key :casais_participantes, :edicoes
    add_foreign_key :cenaculo_casais, :casais_participantes, column: :casal_participante_id
  end
end
