# frozen_string_literal: true

class ServosOrigemMustChangePasswordEmailUnique < ActiveRecord::Migration[8.1]
  def up
    add_column :servos, :origem_cadastro, :string, null: false, default: "painel"
    add_column :users, :must_change_password, :boolean, null: false, default: false

    remove_index :servos, :email, if_exists: true

    execute <<~SQL.squish
      CREATE UNIQUE INDEX index_servos_on_normalized_email_unique
      ON servos (LOWER(TRIM(BOTH FROM email)))
      WHERE email IS NOT NULL AND TRIM(BOTH FROM email) <> '';
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_servos_on_normalized_email_unique;"

    add_index :servos, :email, if_not_exists: true

    remove_column :users, :must_change_password
    remove_column :servos, :origem_cadastro
  end
end
