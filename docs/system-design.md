# System Design - CS2 Players Hub

Este documento explica a arquitetura geral do projeto de ponta a ponta. A ideia e mostrar como o app Flutter consome a API, como o backend organiza as regras de negocio e como o Neon persiste os dados.

## Visao geral

O projeto foi estruturado em 4 partes:

- **Frontend Flutter Web**: interface do usuario, navegação entre telas e chamadas para a API.
- **API Dart + Shelf**: recebe as requisicoes HTTP, valida os dados, aplica as regras de negocio e responde em JSON.
- **Banco de dados Neon Postgres**: armazena usuarios, times e integrantes.
- **Insomnia**: coleção usada para testar os endpoints da API antes e durante a integracao com o Flutter.

O app nao consome APIs externas. Toda a informacao exibida na interface vem da nossa propria API.

## Arquitetura em camadas

### 1. Cliente Flutter

O Flutter Web e a camada visual do projeto. Ele concentra:

- tela de autenticacao;
- home com a navegacao principal;
- pagina de time;
- pagina de jogador;
- pagina de perfil do usuario.

Dentro do frontend existem tres responsabilidades principais:

- **widgets e paginas**: montagem da interface;
- **servicos HTTP**: acesso a API;
- **estado da aplicacao**: carregamento do usuario logado e atualizacao dos dados na tela.

O Flutter nao acessa o banco diretamente. Ele conversa apenas com o backend via HTTP/JSON.

### 2. Servidor API

O backend foi feito em **Dart + Shelf**. Ele segue uma divisao simples em camadas:

- **pipeline/middlewares**: processamento inicial da requisicao, com CORS e logs;
- **router**: identifica qual rota vai tratar a chamada;
- **routes**: exposicao dos endpoints de auth, teams e members;
- **services**: aplicam regras de negocio, autenticao e atualizacao do perfil;
- **repositories**: fazem o acesso ao banco;
- **models**: representam os dados da aplicacao em objetos Dart.

Essa separacao facilita manutencao e evita que a regra de negocio fique misturada com SQL ou com a interface.

### 3. Banco de dados

O banco usado e o **Neon Postgres**. As tabelas principais sao:

- `users`
- `teams`
- `members`

Relacao principal:

- um `team` possui varios `members` (`1:N`).

Os dados de perfil do usuario tambem ficam em `users`, junto com:

- nome;
- nick;
- imagem;
- DPI;
- sensibilidade;
- resolucao;
- crosshair;
- viewmodel.

### 4. Insomnia

O Insomnia foi usado como ferramenta de validacao da API. Ele serve para:

- testar a rota antes do Flutter consumir;
- conferir payloads;
- validar headers e token JWT;
- checar status code e resposta JSON;
- organizar a demo da apresentacao.

Na pratica, ele faz o mesmo papel que o Postman faria no fluxo do trabalho.

## Fluxo das telas no Flutter

O fluxo de navegacao da aplicacao e este:

1. **Auth Page**
   - usuario faz cadastro ou login;
   - ao autenticar, recebe um token JWT.

2. **Home Page**
   - mostra os times em formato de carrossel;
   - permite acessar o perfil do usuario;
   - direciona para a pagina do time selecionado.

3. **Team Page**
   - lista os integrantes do time;
   - mostra jogadores e coach;
   - permite abrir o detalhe de um jogador.

4. **Member Page**
   - exibe o perfil do jogador;
   - mostra nome, idade, funcao, time, configuracoes e imagem.

5. **Profile Page**
   - exibe os dados do usuario autenticado;
   - permite editar nome, nick, foto e configuracoes;
   - faz persistencia real no banco.

## Conexao entre telas e endpoints

### Autenticacao e perfil

- `POST /auth/register`
  - cria um novo usuario.
- `POST /auth/login`
  - autentica e retorna token JWT.
- `GET /auth/me`
  - busca os dados do usuario logado.
- `PUT /auth/me`
  - atualiza o perfil do usuario logado.
- `DELETE /auth/me`
  - remove o usuario logado.

### Times

- `GET /teams`
  - lista todos os times.
- `GET /teams/:id`
  - retorna um time especifico.
- `POST /teams`
  - cria um time.
- `PUT /teams/:id`
  - atualiza um time.
- `DELETE /teams/:id`
  - remove um time.

### Integrantes

- `GET /members`
  - lista todos os integrantes.
- `GET /members/:id`
  - retorna um integrante especifico.
- `GET /teams/:id/members`
  - lista os integrantes de um time.
- `POST /members`
  - cria um integrante.
- `PUT /members/:id`
  - atualiza um integrante.
- `DELETE /members/:id`
  - remove um integrante.

## Fluxo de dados ponta a ponta

### Login

1. O usuario informa email e senha na tela de autenticacao.
2. O Flutter envia `POST /auth/login`.
3. A API valida os dados e gera o token JWT.
4. O Flutter salva a sessao e redireciona para a home.

### Listagem de times

1. A home chama `GET /teams`.
2. A API consulta o banco.
3. O backend devolve os times em JSON.
4. O Flutter monta o carrossel de logos.

### Detalhe de time

1. O usuario clica em um time.
2. O Flutter chama `GET /teams/:id/members`.
3. A API busca os integrantes daquele time.
4. O Flutter renderiza os cards dos jogadores e do coach.

### Detalhe de jogador

1. O usuario clica em um jogador.
2. O Flutter chama `GET /members/:id`.
3. A API retorna os dados completos do integrante.
4. O Flutter mostra nome, idade, funcao, time, imagem e configuracoes.

### Perfil do usuario

1. O usuario abre a pagina de perfil.
2. O Flutter chama `GET /auth/me` com o token JWT no header.
3. A API identifica o usuario autenticado.
4. O Flutter exibe os dados atuais.
5. Ao editar, o app envia `PUT /auth/me`.
6. O backend valida e persiste a alteracao no Neon.

## Estrutura interna do backend

O backend usa uma organizacao simples e facil de explicar na apresentacao:

- **routes**: definem os endpoints HTTP;
- **services**: concentram login, validacao de token e regras do perfil;
- **repositories**: fazem CRUD no Postgres;
- **models**: representam `User`, `Team` e `Member`;
- **database.dart**: inicializa a conexao, cria as tabelas e aplica os seeds.

Essa estrutura ajuda a manter o codigo previsivel:

- a rota recebe a requisicao;
- o service decide o que fazer;
- o repository fala com o banco;
- o model formata a resposta.

## Persistencia no Neon

Os dados ficam no Neon Postgres para garantir persistencia real.

O banco guarda:

- usuarios cadastrados;
- times exibidos na home;
- jogadores e coachs de cada time;
- dados de perfil do usuario autenticado.

Isso significa que:

- fechar e abrir o app nao apaga os dados;
- alterar o perfil realmente atualiza o banco;
- criar, editar e excluir continuam funcionando apos reiniciar a aplicacao.

## Como essa arquitetura ajuda na apresentacao

Essa arquitetura facilita explicar o trabalho porque separa claramente:

- **frontend**: experiencia do usuario;
- **backend**: regras e endpoints;
- **database**: persistencia;
- **Insomnia**: validacao tecnica da API.

Na demo, o fluxo demonstrado e direto:

1. autenticar;
2. listar times;
3. abrir um time;
4. abrir um jogador;
5. editar o perfil;
6. validar a mudanca persistida no banco.

## Arquivos de apoio

- `README.md` - guia rapido do projeto
- `Flutter.drawio` - diagrama visual da arquitetura
- `insomnia/collection.json` - coleção de testes da API
- `docs/architecture.md` - resumo em Mermaid

