import { Controller } from "@hotwired/stimulus"

// Filtra cartões de casais candidatos ao cenáculo (palavras no campo de pesquisa, acentuação ignorada).
export default class extends Controller {
  static targets = ["campoBusca", "cartao", "semResultados", "resultadoFiltragem"]

  connect () {
    this.atualizarFiltragem()
  }

  atualizarFiltragem () {
    const tokens = tokensNormalizados(this.campoBuscaTarget?.value ?? "")
    let matched = 0

    this.cartaoTargets.forEach((el) => {
      const haystack = normalizar(el.dataset.busca || "")
      const ok = tokens.length === 0 || tokens.every((t) => haystack.includes(t))

      el.toggleAttribute("hidden", !ok)
      if (ok) matched++
    })

    const ativo = tokens.length > 0

    if (this.hasSemResultadosTarget) {
      this.semResultadosTarget.hidden = !ativo || matched > 0
    }

    if (this.hasResultadoFiltragemTarget) {
      if (ativo) {
        const total = this.cartaoTargets.length
        this.resultadoFiltragemTarget.textContent =
          matched === total
            ? `Filtros: todos os ${total} candidatos ficam visíveis.`
            : `Filtros: ${matched} de ${total} candidatos visíveis.`
        this.resultadoFiltragemTarget.classList.remove("hidden")
      } else {
        this.resultadoFiltragemTarget.textContent = ""
        this.resultadoFiltragemTarget.classList.add("hidden")
      }
    }
  }

  limparCampoBusca () {
    if (this.hasCampoBuscaTarget) {
      this.campoBuscaTarget.value = ""
      this.atualizarFiltragem()
    }
  }
}

/** @returns {string[]} */
function tokensNormalizados (raw) {
  return normalizar(raw)
    .split(/\s+/)
    .map((x) => x.trim())
    .filter(Boolean)
}

function normalizar (s) {
  return String(s ?? "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ")
    .trim()
}
