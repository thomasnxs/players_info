# Diagrama para reproduzir no draw.io

Use este guia como base visual no draw.io: fundo escuro, caixas com borda clara e setas com texto curto.

## 1. Cliente

Crie uma caixa grande no lado esquerdo com o titulo `Cliente`.

Dentro dela, coloque:
- `Flutter Web`
- `Auth Page`
- `Profile Page`
- `Home Page`
- `Team Page`
- `Member Page`
- `ApiClient`

## 2. Insomnia

Abaixo do cliente, crie outra caixa com:
- `Insomnia`
- `collection.json`

## 3. Servidor

Crie uma caixa grande no centro com o titulo `Servidor`.

Dentro dela, coloque:
- `Backend`
- `Dart + Shelf`
- `Pipeline`
- `CORS + Logs`
- `Router`
- `Auth Routes`
- `Team Routes`
- `Member Routes`
- `Auth Service`
- `Repositories`
- `Models`

## 4. Banco de Dados

Crie uma caixa grande no lado direito com o titulo `Banco de Dados`.

Dentro dela, coloque:
- `Neon Postgres`
- `users`
- `teams`
- `members`

Entre `teams` e `members`, desenhe `1:N`.

## 5. Setas principais

Crie as conexoes abaixo:

- `ApiClient -> Pipeline`
  - texto: `POST /auth/login`
  - texto: `POST /auth/register`
  - texto: `GET /teams`
  - texto: `GET /teams/:id/members`
  - texto: `GET /members/:id`

- `Pipeline -> CORS + Logs`
  - texto: `request HTTP`

- `CORS + Logs -> Router`
  - texto: `encaminha request`

- `Router -> Auth Routes / Team Routes / Member Routes`
  - texto: `seleciona rota`

- `Auth Routes -> Auth Service`
  - texto: `login / token / perfil`

- `Auth Routes / Team Routes / Member Routes -> Repositories`
  - texto: `CRUD`

- `Repositories -> Models`
  - texto: `retorna objetos`

- `Repositories -> Banco de Dados`
  - texto: `SELECT / INSERT / UPDATE / DELETE`

- `Banco de Dados -> Repositories`
  - texto: `dados persistidos`

- `Insomnia -> Pipeline`
  - texto: `testes HTTP JSON`

## 6. Fluxo de navegacao

Adicione setas pequenas no bloco do cliente:
- `Auth Page -> Home Page`
- `Home Page -> Profile Page`
- `Home Page -> Team Page`
- `Team Page -> Member Page`

## 7. Cores sugeridas

- Fundo: `#141414`
- Caixas: `#191919`
- Bordas: branco ou cinza claro
- Texto: branco
- Setas: branco/cinza claro
