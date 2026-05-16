# frozen_string_literal: true

class AddComoChamarToServos < ActiveRecord::Migration[8.0]
  def change
    add_column :servos, :como_chamar, :string
  end
end
