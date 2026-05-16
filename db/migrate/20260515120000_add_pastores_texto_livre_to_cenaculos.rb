# frozen_string_literal: true

class AddPastoresTextoLivreToCenaculos < ActiveRecord::Migration[8.0]
  def change
    add_column :cenaculos, :pastores_texto_livre, :string, limit: 50
  end
end
