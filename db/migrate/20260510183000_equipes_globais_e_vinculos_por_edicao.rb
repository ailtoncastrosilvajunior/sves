# frozen_string_literal: true

# Equipes deixam de pertencer a uma edição: saem templates globais.
# O vínculo servo ↔ equipe passa a ser sempre por edição (lista de disponíveis = todos os servos;
# ocupação dentro da equipe nesta edição = equipes_servos.edicao_id).
class EquipesGlobaisEVinculosPorEdicao < ActiveRecord::Migration[8.1]
  def up
    add_reference :equipes_servos, :edicao, null: true, foreign_key: true

    say_with_time "Preencher edicao_id nos vínculos a partir das equipes atuais" do
      execute <<-SQL.squish
        UPDATE equipes_servos
        SET edicao_id = equipes.edicao_id
        FROM equipes
        WHERE equipes_servos.equipe_id = equipes.id
      SQL
    end

    say_with_time "Unificar registos duplicados de equipes com o mesmo nome (base comum)" do
      buckets = Equipe.all.group_by { |e| e.nome.strip.downcase }
      buckets.each_value do |grp|
        next if grp.size < 2
        keeper = grp.min_by(&:id)
        (grp - [keeper]).each do |dup|
          EquipeServo.where(equipe_id: dup.id).update_all(equipe_id: keeper.id)
          dup.reload.destroy!
        end
      end
    end

    if EquipeServo.where(edicao_id: nil).exists?
      raise ActiveRecord::IrreversibleMigration, "existem vínculos sem edicao_id após o backfill — ver dados manualmente"
    end

    remove_index :equipes_servos, name: "index_equipes_servos_on_equipe_id_and_servo_id"

    execute <<-SQL.squish
      DELETE FROM equipes_servos es
      USING equipes_servos es2
      WHERE es.equipe_id = es2.equipe_id
        AND es.edicao_id = es2.edicao_id
        AND es.servo_id = es2.servo_id
        AND es.id > es2.id
    SQL

    change_column_null :equipes_servos, :edicao_id, false

    add_index :equipes_servos,
              %i[equipe_id edicao_id servo_id],
              unique: true,
              name: "idx_equipes_servos_equipe_edicao_servo_unique"

    remove_foreign_key :equipes, :edicoes
    remove_index :equipes, name: "index_equipes_on_edicao_id_and_nome"
    remove_index :equipes, :edicao_id
    remove_column :equipes, :edicao_id, :bigint

    add_index :equipes, :nome, unique: true, name: "index_equipes_on_nome_unique"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Reverta a partir do backup/restauro ou recrie edição_em_equipe manualmente"
  end
end
