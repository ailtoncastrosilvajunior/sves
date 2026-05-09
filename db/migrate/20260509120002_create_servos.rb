class CreateServos < ActiveRecord::Migration[8.0]
  def change
    create_table :servos do |t|
      t.string :nome, null: false
      t.string :email
      t.string :telefone
      t.string :sexo, limit: 20

      t.references :conjuge, foreign_key: { to_table: :servos }

      t.timestamps
    end

    add_index :servos, :email
  end
end
