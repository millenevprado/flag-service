# CI/CD Workflows

Este diretório contém o workflow do GitHub Actions do `flag-service` (`ci.yml`), disparado em `push` e `pull_request` para a branch `main`. Os jobs rodam em sequência via `needs`, então uma falha em um estágio impede os estágios seguintes de rodar.

## `build-test` — Build & Unit Test

- Instala as dependências do `requirements.txt`.
- Valida a sintaxe do `app.py` (`py_compile`).
- Executa os testes unitários com `pytest`, se houver arquivos `test_*.py` ou `*_test.py` no repositório.

## `lint` — Lint & Static Analysis

- Instala as dependências do projeto.
- Executa `flake8` (limite de 120 colunas por linha) para checagem de estilo e qualidade do código Python.

## `security-scan` — Security Scan (SAST & SCA)

Depende de `build-test` e `lint`.

- Roda `bandit` (SAST) contra o código-fonte com severidade mínima `high`.
- Roda `trivy` (SCA) em modo filesystem para vulnerabilidades `CRITICAL` nas dependências.

## `gitleaks` — Secret Scanning

- Escaneia o histórico do repositório em busca de segredos vazados (chaves, tokens, credenciais).

## `docker-build-push` — Docker Build & Push

Depende de `security-scan` e `gitleaks` — só roda se ambos passarem.

- Faz lint do `Dockerfile` com `hadolint`.
- Gera uma tag de imagem no formato `v1.0.0-<sha curto>`.
- Constrói a imagem Docker e roda `trivy` em modo image scan (`CRITICAL,HIGH`).
- Em eventos de `push` para `main`: autentica na AWS, faz login no Amazon ECR e publica a imagem no repositório `flag-service`.
- Em seguida, faz checkout do repositório [`fiap-challenge-3-gitops`](https://github.com/millenevprado/fiap-challenge-3-gitops), atualiza a linha `image:` do `flag-service/deployment.yaml` com a nova tag e faz commit/push automático (entrega contínua).

### Secrets necessários

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `GITOPS_PAT` — Personal Access Token com permissão de escrita (`Contents: Read and write`) no repositório `fiap-challenge-3-gitops`.
