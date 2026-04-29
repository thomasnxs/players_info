# CS2 Players Hub - Trabalho Full Stack com Dart

Projeto do trabalho pratico da disciplina Topicos Especiais,com:
- backend em Dart + Shelf + Postgres (Neon);
- frontend em Flutter (web);
- documentacao e testes de API via Insomnia (liberado pelo professor).

## 1) Tema e entidades

Tema: informacoes de times e jogadores de CS2.

Entidades:
- `teams` (pai)
- `members` (filho, relacao 1:N com `teams`)

Relacao:
- um time possui varios integrantes (5 jogadores + 1 coach, no seed inicial).

## 2) Como o projeto funciona

Fluxo principal:
1. Usuario abre o app e cai na tela de autenticacao (`/auth`).
2. Faz cadastro ou login.
3. Vai para a home (`/home`) com carrossel de logos dos times.
4. Clica em um time e abre a pagina do time (`/team`), com roster.
5. Clica em um jogador e abre a pagina do jogador (`/member`) com:
   - nome, idade, funcao e time;
   - configuracoes (DPI, sens, resolucao);
   - crosshair e viewmodel.

## 3) Estrutura de pastas

```text
players_info/
├── backend/      # API Dart + Shelf + Neon
├── docs/         # Diagramas de arquitetura
├── frontend/     # App Flutter Web
├── insomnia/     # Export JSON do Insomnia (entrega)
└── README.md     # Este arquivo
```

Diagrama de arquitetura:
- `docs/architecture.md`
- `docs/architecture-drawio-guide.md`
- `docs/architecture-drawio.drawio`

## 4) Backend (API)

### Requisitos
- Dart SDK instalado.
- Banco Neon configurado.
- Arquivo `backend/.env` com:
  - `DATABASE_URL`
  - `JWT_SECRET`
  - `PORT` (opcional; padrao 8080)

### Rodar backend
```bash
cd backend
dart pub get
dart run bin/server.dart
```

API padrao: `http://localhost:8080`

### Endpoints principais

Auth:
- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`

Teams (entidade pai):
- `GET /teams`
- `GET /teams/:id`
- `POST /teams`
- `PUT /teams/:id`
- `DELETE /teams/:id`

Members (entidade filha):
- `GET /members`
- `GET /members/:id`
- `GET /teams/:id/members`
- `POST /members`
- `PUT /members/:id`
- `DELETE /members/:id`

## 5) Frontend (Flutter Web)

### Requisitos
- Flutter SDK instalado.
- Backend rodando em `localhost:8080` (ou ajustar URL da API).

### Rodar frontend web
```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

## 6) Insomnia - o que precisa fazer para entrega

Como o professor liberou Insomnia, a ideia e entregar um export JSON com os requests organizados.

### Estrutura sugerida no Insomnia
- Workspace: `CS2 Players Hub`
- Folder `Auth`
  - Register
  - Login
  - Me
- Folder `Teams`
  - GET list
  - GET by id
  - POST create
  - PUT update
  - DELETE remove
- Folder `Members`
  - GET list
  - GET by id
  - GET by team (`/teams/:id/members`)
  - POST create
  - PUT update
  - DELETE remove

### Variavel de ambiente
Criar variavel/base URL:
- `base_url = http://localhost:8080`

Usar nas requests:
- `{{ base_url }}/teams`
- `{{ base_url }}/members`

### Headers
Para POST/PUT:
- `Content-Type: application/json`

Para rotas autenticadas:
- `Authorization: Bearer <token>`

### Export para entrega
1. No Insomnia, abra o workspace.
2. Clique em `Create` (ou menu do workspace) -> `Export`.
3. Escolha formato JSON.
4. Salve o arquivo em:
   - `insomnia/collection.json`

Se quiser, posso montar para voce o checklist de requests com payload pronto (copiar/colar) para acelerar a configuracao no Insomnia.

Checklist pronto criado em:
- `insomnia/requests-checklist.md`

## 7) Observacoes de entrega

Pendencias comuns para nao perder ponto:
- manter o backend funcionando localmente;
- garantir que o frontend consome sua propria API;
- anexar export do Insomnia em `insomnia/collection.json`;
- preparar apresentacao de arquitetura (slides), conforme exigencia do trabalho.
