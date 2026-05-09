class UsersAndServosUserId < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    # Índice parcial único (vários user_id NULL; um login por servo com conta).
    # Não repetir `add_reference` + `add_index` sem `index:` — PostgreSQL já batiza o índice
    # `index_servos_on_user_id` e falha ao tentar criar outro igual.
    add_reference :servos, :user, foreign_key: true, index: { unique: true, where: "user_id IS NOT NULL" }
  end
end
