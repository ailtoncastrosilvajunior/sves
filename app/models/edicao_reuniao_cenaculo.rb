# frozen_string_literal: true

# Momento de «reunião de cenáculo» ao longo da edição (partilhas por gênero, etc.).
class EdicaoReuniaoCenaculo < ApplicationRecord
  belongs_to :edicao
  has_many :cenaculo_presenca_reunioes, dependent: :destroy

  enum :estado, {
    em_preparacao: "em_preparacao",
    liberada: "liberada",
    encerrada: "encerrada",
  }, validate: true

  validates :titulo, presence: true
  validates :ordem, numericality: { only_integer: true }

  scope :ordenadas, -> { order(:ordem, :id) }

  def visivel_para_pastor?
    liberada? || encerrada?
  end
end
