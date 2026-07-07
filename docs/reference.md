---
summary: "Full PT-BR reference for the agents-letras repo structure, files, configs, skills, and sync flow."
read_when:
  - Auditing the complete agents setup.
  - Updating broad repo documentation after structural changes.
---

# Referência Completa

Referência do repositório `agents-letras`.

## Visão geral

Este repo é a fonte versionada do setup de agentes. Ele centraliza:

- instruções em `AGENTS.md`
- skills source em `skills/`
- subagents em `agents/`
- config de Claude em `claude/`
- scripts de instalação e validação em `scripts/`

Estado local e sensível fica fora do Git.

## Estrutura

```text
AGENTS.md
LICENSE
README.md
install.sh
skills.toml
.githooks/
agents/
claude/
docs/
instructions/
scripts/
skills/
```

## AGENTS.md

Regras globais para agentes. Deve conter só regras duráveis. Fluxos reutilizáveis vão para skills. Racional mais longo vai para docs.

## skills/

Árvore source categorizada. Cada skill tem `SKILL.md` no topo.

`skills-cli` gera `.runtime/skills`, que não é versionado. Esse runtime flat é o que o Claude consome quando instalado pelo `install.sh`.

## claude/

- `settings.json`: config do Claude.
- `mcp.json`: template de MCP servers com tokens via env vars.
- `statusline-command.py`: statusline custom.

`claude/claude.json` é uma base de config/estado do Claude. OAuth, IDs, projetos e histórico local não entram.

## instructions/

Docs de instrução de longo formato referenciados por `AGENTS.md`: `instruction-architecture.md`, `engineering-principles.md`, `git-github.md` e `tooling.md`. O `install.sh` liga essa pasta como `~/.agents/instructions`.

## scripts/

Scripts de validação de docs (`validate-docs.py`) e listagem de docs (`docs-list.py`). Detalhes em `scripts/README.md`.

## install.sh

Cria symlinks em `~/.agents`, gera runtime de skills e conecta o Claude ao hub.

O installer não instala pets e não copia caches de plugin.

## Segurança

Nunca versionar:

- `.env*`
- tokens e secrets
- dumps de ambiente
- trusted projects
- caches locais
- logs ou sessões
- OAuth e IDs de usuário de `claude/claude.json`
- `.runtime/`

Valores sensíveis devem ser lidos por env vars fora do repo.
