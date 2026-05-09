class CreateEquipesServos < ActiveRecord::Migration[8.0]
  def change
    create_table :equipes_servos do |t|
      t.references :equipe, null: false, foreign_key: true
      t.references :servo, null: false, foreign_key: true
      t.integer :forma, null: false, default: 1

      t.timestamps
    end

    add_index :equipes_servos, %i[equipe_id servo_id], unique: true
  end
end
