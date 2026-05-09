class CreateCasaisParticipantes < ActiveRecord::Migration[8.0]
  def change
    create_table :casais_participantes do |t|
      t.references :edicao, null: false, foreign_key: true
      t.string :nome_parceiro_a
      t.string :nome_parceiro_b
      t.string :email_contato
      t.string :telefone_contato
      t.text :observacoes

      t.timestamps
    end

    add_index :casais_participantes, %i[edicao_id email_contato], unique: true, where: "email_contato IS NOT NULL AND email_contato <> ''"
  end
end
