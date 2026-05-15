# SVES Casais · 2026.1

Aplicação **Ruby 3.3** + **Rails 8** + **PostgreSQL** + **Tailwind CSS v4** para organizar edições do Seminário de Vida no Espírito Santo (casais — Face de Cristo): edições, servos/equipes, casais participantes e cenáculos.

## Configuração do PostgreSQL (.env)

Cria um ficheiro `.env` na raiz — vê [.env.example](.env.example). Em **development**, o Rails lê `DATABASE_NAME`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_HOST`, `DATABASE_PORT` (opcionalmente `DATABASE_URL`; se existir, tem prioridade sobre os outros campos). O projeto usa **`dotenv-rails`** só em development/test para carregar o `.env`.

- **Servidor remoto (ex.: droplet)** coloca IP/hostname em `DATABASE_HOST` e garante SSL/porta conforme o teu servidor.
- **Versão do Postgres:** o Rails 8 exige **PostgreSQL ≥ 9.5**; recomenda-se **14–16**. Confirme no servidor com `SELECT version();`. Se o erro mostrar versão **`90324`**, é **`server_version_num`** de **PostgreSQL 9.3.x** — atualiza o Postgres no droplet ou usa outra instância (ex.: Managed Database na DigitalOcean).
- **Órfãos no Compose:** depois de remover o serviço `db`, faz `docker compose down --remove-orphans` para tirar contentores antigos (ex.: `*-db-*`).
- **`DATABASE_TEST_NAME`**: nome da base só para **test**, por defeito `sves_test`. Em CI usa-se só `DATABASE_URL` no workflow.

⚠️ Rota passwords com exposição accidental (chat, screenshots); volta a gravar uma senha no servidor se já partilhaste.

## Ambiente recomendado: Docker Compose (desenvolvimento)

Ruby local não precisa ser 3.x se você desenvolver apenas via containers.

O Compose sobe apenas o **`web`**; não há Postgres no Docker: usa o servidor definido no teu `.env` (droplet ou outro). O ficheiro é montado na app e também passado ao container quando existir (`env_file` opcional).

```bash
docker compose up --build
```

Garante um `.env` na raiz com `DATABASE_HOST` (IP ou hostname do droplet), `DATABASE_NAME`, `DATABASE_USERNAME`, `DATABASE_PASSWORD` e `DATABASE_PORT` (opcional `DATABASE_URL`).

Abra **http://localhost:3000**. O serviço `web` sobe Puma (`./bin/dev` com watcher do Tailwind) e roda `db:prepare` na primeira vez em cima do Postgres remoto.

Antes do `./bin/dev`, o comando do Compose faz **`rm -f tmp/pids/server.pid`** — o volume `rails_tmp` podia salvar um PID velho e o Puma falhava com «A server is already running».

### Telemóvel (Safari ou Chrome em iPhone) não abre a app · «não há ligação» · página em branco

São dois problemas **distintos** (afetam **ambos** os browsers — não é só Safari):

1. **O servidor só escutava no Mac (`127.0.0.1`)**  
   O Puma deve aceitar pedidos vindos da **rede LAN**. Em **development**, `config/puma.rb` faz **`bind tcp://0.0.0.0:PORT`**, assim o telemóvel na mesma Wi‑Fi consegue falar com o Mac usando **`http://IP-DO-MAC:3000`**.  
   - No Mac, IP da Wi‑Fi: `ipconfig getifaddr en0` (ou `en1` segundo a interface activa).

2. **Rails bloqueia o header `Host` («Blocked hosts»)**  
   O Rails só aceita `Host` autorizado. Em `development.rb` já há **192.168.x.x**, **10.x**, **Tailscale (`*.ts.net` e 100.64–100.127.x.x)**, **`.local`**, etc. Para outro nome, no `.env`:  
   `DEV_ALLOWED_HOSTS=meu.hostname,203.0.113.44`

Confirma: **Wi‑Fi a mesma** no Mac/telemóvel, URL **`http://`** (em dev não uses `https`), e no **Firewall** do macOS permite conexões de entrada das redes locais para **Ruby**/terminal se ele bloquear. Com **Docker Compose**, uso **`http://IP-DO-MAC:3000`** (mapeamento de portas já expõe o serviço no host).

**Impressão / PDF no Safari:** em **Imprimir** marca **«Imprimir fundos»** se queres cores/quadrados no PDF (mensagem igual na página da equipe).

### DigitalOcean Managed PostgreSQL (`SSL negotiation` / ligação recusada)

1. Em **Trusted sources**, inclui o **IP público** de onde fazes pedidos de fora da VPC (ex.: o teu IP em casa ou o `curl -s https://ifconfig.me` no mesmo Mac onde corres o Docker).
2. A documentação da DO recomenda **`sslmode=verify-full`** e o ficheiro **CA** descarregado no painel. Coloca-o em `config/certs/do-ca.crt` e na `DATABASE_URL` usa `?sslmode=verify-full&sslrootcert=/rails/config/certs/do-ca.crt` (caminho dentro do contentor com o volume actual).
3. Se ainda falhar com `sslmode=require`, tenta `&gssencmode=disable` na query string.

## Produção (imagem Dockerfile raiz)

A imagem gerada pelo `Dockerfile` do Rails está orientada à produção (Thruster, `assets:precompile`, usuário não root).

Deploy na **DigitalOcean App Platform**: utilize esse `Dockerfile`, defina **`RAILS_MASTER_KEY`**, **`SECRET_KEY_BASE`** (ou apenas master key conforme fluxo Rails), **`DATABASE_URL`** para o Postgres gerenciado. No arranque do contentor web, o **`bin/docker-entrypoint`** corre **`bin/rails db:prepare`** (desde que o comando contenha `rails` + `server`, ou `bin/thrust`), o que **cria/atualiza a primary e carrega o schema da fila Solid Queue** (`solid_queue_jobs`, etc.). Se desativar esse passo, use um job de release com **`bin/rails db:prepare`** — **não** use só `db:migrate`, senão faltam as tabelas da fila e uploads (Active Storage) podem falhar com `relation "solid_queue_jobs" does not exist`.

Variável opcional: **`SKIP_DB_PREPARE=1`** ignora o `db:prepare` no entrypoint (útil se preparares a BD só num job de release). O health check HTTP pode apontar para **`/up`**.

**Nota:** em produção o Rails 8 usa configs extra para Solid Cache, Solid Queue e Solid Cable (`_cache`, `_queue`, `_cable` no `database.yml` quando não usas só `DATABASE_URL`). Com **um único `DATABASE_URL`**, todas partilham o mesmo Postgres; `db:prepare` cria as tabelas necessárias nessa base. Se usares bases separadas no cluster, cria-as ou ajusta nomes/URLs conforme a documentação do Rails.

## Fora do Docker (opcional)

Requer Ruby **3.3.11** (ver `.ruby-version`), PostgreSQL acessível e:

```bash
bundle install
bin/rails db:prepare
bin/dev
```

## Testes

```bash
bin/rails test
```

No CI, `DATABASE_URL` aponta para `sves_test` no serviço Postgres.

<!-- CHECKPOINT id="ckpt_mp4574f8_2epwl6" time="2026-05-13T14:16:03.620Z" note="auto" fixes=0 questions=0 highlights=0 sections="" -->

<!-- CHECKPOINT id="ckpt_mp4beik9_c3ss1y" time="2026-05-13T17:09:46.233Z" note="auto" fixes=0 questions=0 highlights=0 sections="" -->

<!-- CHECKPOINT id="ckpt_mp4e9ejp_506xr2" time="2026-05-13T18:29:46.597Z" note="auto" fixes=0 questions=0 highlights=0 sections="" -->

<!-- CHECKPOINT id="ckpt_mp4fbze4_ustyy7" time="2026-05-13T18:59:46.540Z" note="auto" fixes=0 questions=0 highlights=0 sections="" -->
