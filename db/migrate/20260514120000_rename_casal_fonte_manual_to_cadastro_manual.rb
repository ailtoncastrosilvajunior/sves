# frozen_string_literal: true

class RenameCasalFonteManualToCadastroManual < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE casais
      SET fonte_importacao = 'cadastro_manual'
      WHERE fonte_importacao = 'manual'
    SQL

    change_column_default :casais, :fonte_importacao, "cadastro_manual"
  end

  def down
    execute <<~SQL
      UPDATE casais
      SET fonte_importacao = 'manual'
      WHERE fonte_importacao = 'cadastro_manual'
    SQL

    change_column_default :casais, :fonte_importacao, "manual"
  end
end
