# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_13_212702) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "casais", force: :cascade do |t|
    t.string "apelido_ela"
    t.string "apelido_ele"
    t.string "assinatura_linha", limit: 128
    t.text "caracterizacao_uniao"
    t.text "como_conheceu_seminario"
    t.datetime "created_at", null: false
    t.jsonb "dados_brutos", default: {}, null: false
    t.date "data_nascimento_ela"
    t.date "data_nascimento_ele"
    t.bigint "edicao_id", null: false
    t.string "email_contato"
    t.text "endereco"
    t.text "filhos_abc_jesus"
    t.string "fonte_importacao", limit: 24, default: "manual", null: false
    t.text "horarios_abc_jesus"
    t.text "igreja_casamento_e_data"
    t.datetime "inscrito_em"
    t.text "movimentos_ela"
    t.text "movimentos_ele"
    t.string "nome_completo_ela"
    t.string "nome_completo_ele"
    t.text "observacoes"
    t.text "telefones_contato"
    t.string "teve_casamento_anterior"
    t.datetime "updated_at", null: false
    t.text "url_comprovante_pagamento"
    t.index ["edicao_id", "assinatura_linha"], name: "index_casais_on_edicao_id_and_assinatura_linha_unique", unique: true, where: "((assinatura_linha IS NOT NULL) AND (TRIM(BOTH FROM assinatura_linha) <> ''::text))"
    t.index ["edicao_id", "email_contato"], name: "index_casais_on_edicao_id_and_email_contato", unique: true, where: "((email_contato IS NOT NULL) AND ((email_contato)::text <> ''::text))"
    t.index ["edicao_id"], name: "index_casais_on_edicao_id"
    t.index ["fonte_importacao"], name: "index_casais_on_fonte_importacao"
    t.index ["inscrito_em"], name: "index_casais_on_inscrito_em"
  end

  create_table "cenaculo_casais", force: :cascade do |t|
    t.bigint "casal_id", null: false
    t.bigint "cenaculo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["casal_id"], name: "index_cenaculo_casais_on_casal_id"
    t.index ["cenaculo_id", "casal_id"], name: "index_cenaculo_casais_unique", unique: true
    t.index ["cenaculo_id"], name: "index_cenaculo_casais_on_cenaculo_id"
  end

  create_table "cenaculo_presenca_reunioes", force: :cascade do |t|
    t.bigint "casal_id", null: false
    t.bigint "cenaculo_id", null: false
    t.datetime "created_at", null: false
    t.bigint "edicao_reuniao_cenaculo_id", null: false
    t.boolean "presente_ela", default: false, null: false
    t.boolean "presente_ele", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["casal_id"], name: "index_cenaculo_presenca_reunioes_on_casal_id"
    t.index ["cenaculo_id", "edicao_reuniao_cenaculo_id"], name: "idx_on_cenaculo_id_edicao_reuniao_cenaculo_id_1b33ae641f"
    t.index ["cenaculo_id"], name: "index_cenaculo_presenca_reunioes_on_cenaculo_id"
    t.index ["edicao_reuniao_cenaculo_id", "casal_id"], name: "idx_presenca_reuniao_casal_unique", unique: true
    t.index ["edicao_reuniao_cenaculo_id"], name: "index_cenaculo_presenca_reunioes_on_edicao_reuniao_cenaculo_id"
  end

  create_table "cenaculo_servos", force: :cascade do |t|
    t.bigint "cenaculo_id", null: false
    t.datetime "created_at", null: false
    t.bigint "servo_id", null: false
    t.datetime "updated_at", null: false
    t.index ["cenaculo_id", "servo_id"], name: "index_cenaculo_servos_on_cenaculo_id_and_servo_id", unique: true
    t.index ["cenaculo_id"], name: "index_cenaculo_servos_on_cenaculo_id"
    t.index ["servo_id"], name: "index_cenaculo_servos_on_servo_id"
  end

  create_table "cenaculos", force: :cascade do |t|
    t.string "cor", limit: 32
    t.datetime "created_at", null: false
    t.bigint "edicao_id", null: false
    t.string "local_homens"
    t.string "local_mulheres"
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index ["edicao_id", "nome"], name: "index_cenaculos_on_edicao_id_and_nome", unique: true
    t.index ["edicao_id"], name: "index_cenaculos_on_edicao_id"
  end

  create_table "edicao_reuniao_cenaculos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "descricao"
    t.bigint "edicao_id", null: false
    t.string "estado", default: "em_preparacao", null: false
    t.integer "ordem", default: 0, null: false
    t.string "titulo", null: false
    t.datetime "updated_at", null: false
    t.index ["edicao_id", "estado"], name: "index_edicao_reuniao_cenaculos_on_edicao_id_and_estado"
    t.index ["edicao_id", "ordem"], name: "index_edicao_reuniao_cenaculos_on_edicao_id_and_ordem"
    t.index ["edicao_id"], name: "index_edicao_reuniao_cenaculos_on_edicao_id"
  end

  create_table "edicoes", force: :cascade do |t|
    t.integer "ano", null: false
    t.boolean "ativa", default: false, null: false
    t.datetime "created_at", null: false
    t.string "link_planilha"
    t.integer "numero_edicao", null: false
    t.datetime "updated_at", null: false
    t.index ["ano", "numero_edicao"], name: "index_edicoes_on_ano_and_numero_edicao", unique: true
    t.index ["ativa"], name: "index_edicoes_one_ativa", unique: true, where: "(ativa = true)"
  end

  create_table "equipe_servos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "edicao_id", null: false
    t.bigint "equipe_id", null: false
    t.integer "forma", default: 1, null: false
    t.bigint "servo_id", null: false
    t.datetime "updated_at", null: false
    t.index ["edicao_id"], name: "index_equipe_servos_on_edicao_id"
    t.index ["equipe_id", "edicao_id", "servo_id"], name: "idx_equipes_servos_equipe_edicao_servo_unique", unique: true
    t.index ["equipe_id"], name: "index_equipe_servos_on_equipe_id"
    t.index ["servo_id"], name: "index_equipe_servos_on_servo_id"
  end

  create_table "equipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index ["nome"], name: "index_equipes_on_nome_unique", unique: true
  end

  create_table "material_apoios", force: :cascade do |t|
    t.boolean "ativo", default: true, null: false
    t.datetime "created_at", null: false
    t.text "descricao"
    t.integer "ordem", default: 0, null: false
    t.string "titulo", null: false
    t.datetime "updated_at", null: false
    t.index ["ativo"], name: "index_material_apoios_on_ativo"
    t.index ["ordem", "titulo"], name: "index_material_apoios_on_ordem_and_titulo"
  end

  create_table "servos", force: :cascade do |t|
    t.bigint "conjuge_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "grupo_de_oracao"
    t.string "nome", null: false
    t.string "origem_cadastro", default: "painel", null: false
    t.string "papel", default: "coordenacao", null: false
    t.string "sexo", limit: 20
    t.string "telefone"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index "lower(TRIM(BOTH FROM email))", name: "index_servos_on_normalized_email_unique", unique: true, where: "((email IS NOT NULL) AND (TRIM(BOTH FROM email) <> ''::text))"
    t.index ["conjuge_id"], name: "index_servos_on_conjuge_id"
    t.index ["user_id"], name: "index_servos_on_user_id", unique: true, where: "(user_id IS NOT NULL)"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "must_change_password", default: false, null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "casais", "edicoes"
  add_foreign_key "cenaculo_casais", "casais"
  add_foreign_key "cenaculo_casais", "cenaculos"
  add_foreign_key "cenaculo_presenca_reunioes", "casais"
  add_foreign_key "cenaculo_presenca_reunioes", "cenaculos"
  add_foreign_key "cenaculo_presenca_reunioes", "edicao_reuniao_cenaculos"
  add_foreign_key "cenaculo_servos", "cenaculos"
  add_foreign_key "cenaculo_servos", "servos"
  add_foreign_key "cenaculos", "edicoes"
  add_foreign_key "edicao_reuniao_cenaculos", "edicoes"
  add_foreign_key "equipe_servos", "edicoes"
  add_foreign_key "equipe_servos", "equipes"
  add_foreign_key "equipe_servos", "servos"
  add_foreign_key "servos", "servos", column: "conjuge_id"
  add_foreign_key "servos", "users"
end
