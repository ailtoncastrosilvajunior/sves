# frozen_string_literal: true

# Bases que já correram `create_materiais_apoio` com o nome antigo da tabela.
class RenameMateriaisApoioToMaterialApoios < ActiveRecord::Migration[8.1]
  def up
    return if table_exists?(:material_apoios)
    return unless table_exists?(:materiais_apoio)

    rename_table :materiais_apoio, :material_apoios

    return unless index_exists?(:material_apoios, :ativo, name: "index_materiais_apoio_on_ativo")
    rename_index :material_apoios, "index_materiais_apoio_on_ativo", "index_material_apoios_on_ativo"

    return unless index_exists?(:material_apoios, [:ordem, :titulo], name: "index_materiais_apoio_on_ordem_and_titulo")
    rename_index :material_apoios,
                 "index_materiais_apoio_on_ordem_and_titulo",
                 "index_material_apoios_on_ordem_and_titulo"
  end

  def down
    return if table_exists?(:materiais_apoio)
    return unless table_exists?(:material_apoios)

    if index_exists?(:material_apoios, :ativo, name: "index_material_apoios_on_ativo")
      rename_index :material_apoios, "index_material_apoios_on_ativo", "index_materiais_apoio_on_ativo"
    end

    if index_exists?(:material_apoios, [:ordem, :titulo], name: "index_material_apoios_on_ordem_and_titulo")
      rename_index :material_apoios,
                     "index_material_apoios_on_ordem_and_titulo",
                     "index_materiais_apoio_on_ordem_and_titulo"
    end

    rename_table :material_apoios, :materiais_apoio
  end
end
