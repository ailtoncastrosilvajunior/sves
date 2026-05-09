# Atalhos que dependem da edição marcada como «em curso» (única ativa).
class ContextoController < ApplicationController
  def equipes
    e = edicao_em_curso
    if e
      redirect_to edicao_equipes_path(e)
    else
      redirect_to edicoes_path,
                  alert: "Não há edição em curso. Abra Edições e use «Marcar como edição em curso» na rodada certa."
    end
  end
end
