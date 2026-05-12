# frozen_string_literal: true

class AddLocalHomensAndLocalMulheresToCenaculos < ActiveRecord::Migration[8.1]
  def change
    add_column :cenaculos, :local_homens, :string
    add_column :cenaculos, :local_mulheres, :string
  end
end
