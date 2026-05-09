class CreateCenaculoServos < ActiveRecord::Migration[8.0]
  def change
    create_table :cenaculo_servos do |t|
      t.references :cenaculo, null: false, foreign_key: true
      t.references :servo, null: false, foreign_key: true

      t.timestamps
    end

    add_index :cenaculo_servos, %i[cenaculo_id servo_id], unique: true
  end
end
