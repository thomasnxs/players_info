# Backend (Dart + Shelf + Neon)

API de autenticação e cadastro de times/integrantes para o trabalho.

## Endpoints

### Auth
- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me` (Bearer token)

### Teams (entidade pai)
- `GET /teams`
- `GET /teams/:id`
- `POST /teams`
- `PUT /teams/:id`
- `DELETE /teams/:id`

### Members (entidade filha)
- `GET /members`
- `GET /members/:id`
- `GET /teams/:id/members`
- `POST /members`
- `PUT /members/:id`
- `DELETE /members/:id`

### Health
- `GET /health`

## Configuração

1. Copie o arquivo de exemplo:

```bash
cp .env.example .env
```

2. Preencha no `.env`:
- `DATABASE_URL` (string do Neon)
- `JWT_SECRET`
- `PORT` (opcional, padrão `8080`)

Obs.: se sua string do Neon vier com `channel_binding=require`, o backend remove esse parâmetro automaticamente para compatibilidade com o driver Dart `postgres`.

## Rodar

```bash
dart pub get
dart run bin/server.dart
```

## Seed inicial

Ao subir com banco vazio, a API cria automaticamente:
- 5 times (`Vitality`, `Natus Vincere`, `FURIA`, `Spirit`, `Falcons`)
- 30 integrantes (5 players + 1 coach por time)

## Estrutura principal

```text
bin/server.dart
lib/config/app_env.dart
lib/database/database.dart
lib/routes/auth_routes.dart
lib/routes/team_routes.dart
lib/routes/member_routes.dart
```
