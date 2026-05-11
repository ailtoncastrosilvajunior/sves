class InicioController < ApplicationController
  skip_before_action :require_login

  def index
    @edicao_painel = Edicao.em_curso_primaria
    @casais_inscritos_count = @edicao_painel&.casais&.count
  end
end
