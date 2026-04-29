# CS2 Players Hub (Frontend Web)

Aplicacao Flutter Web com:
- tela principal de autenticacao (login/cadastro sem confirmacao por e-mail);
- redirecionamento para `home` apos login/cadastro.

## Stack

- Flutter 3.x
- `http` para consumo da API
- `shared_preferences` para persistir sessao
- tema customizado com `google_fonts`

## Como executar (web)

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

Para build de producao:

```bash
flutter build web --release --dart-define=API_BASE_URL=http://localhost:8080
```

## Rotas da API esperadas pelo frontend

### Auth
- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`

### Times (entidade pai)
- `GET /teams`
- `GET /teams/:id`
- `POST /teams`
- `PUT /teams/:id`
- `DELETE /teams/:id`

### Integrantes (entidade filha)
- `GET /members`
- `GET /members/:id`
- `GET /teams/:id/members`
- `POST /members`
- `PUT /members/:id`
- `DELETE /members/:id`

## Estrutura atual

```text
lib/
  app/
  core/
  models/
  pages/
  services/
  widgets/
```

## Observacao

Este repositório está focado na etapa frontend web. O backend em Dart + Shelf com NeonDB será implementado na próxima etapa para atender integralmente ao trabalho.
