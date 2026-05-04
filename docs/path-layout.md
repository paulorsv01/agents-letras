# Como é meu setup

Este repo é só **uma fatia** do meu setup de agentes — o que faz sentido compartilhar. O setup completo (com config local, estado runtime, tokens, plugins) vive separado.

Este doc explica como eu organizo o setup completo na minha máquina, e como esta fatia se encaixa nele.

## A ideia

Cada ferramenta lê config de um lugar fixo:

| Ferramenta | Onde lê |
|---|---|
| Claude Code | `~/.claude/CLAUDE.md`, `~/.claude/skills/`, `~/.claude/settings.json` |
| Codex CLI | `~/.agents/AGENTS.md`, `~/.codex/config.toml`, `~/.agents/skills/`, `~/.codex/AGENTS.md` |

Em vez de manter cópias separadas do mesmo `AGENTS.md` e do mesmo conjunto de skills pra cada ferramenta, mantenho **uma fonte da verdade num repo git** e cada ferramenta aponta pra lá via symlink.

## Hub central: `~/.agents/`

Crio uma pasta `~/.agents/` que é o **hub**. Cada item dela é um symlink pro repo:

```
~/.agents/AGENTS.md  →  <repo>/AGENTS.md
~/.agents/skills     →  <repo>/skills
~/.agents/claude     →  <repo>/claude
```

Daí, cada ferramenta aponta pro hub:

```
~/.claude/CLAUDE.md  →  ~/.agents/AGENTS.md
~/.claude/skills     →  ~/.agents/skills
~/.codex/AGENTS.md   →  ~/.agents/AGENTS.md
```

Vantagem dos dois níveis (`~/.agents/` → repo): se eu trocar o path do repo, atualizo só os links de `~/.agents/*` e o resto continua funcionando.

## O que **não** entra no repo

- **Estado runtime das ferramentas** — sessões, sqlite, logs, cache de plugins. Efêmeros e específicos de máquina.
- **Configs com trusted projects ou paths absolutos** — `~/.claude.json`, `~/.codex/config.toml` ativo.
- **Tokens, secrets, bearer values** — só env vars referenciadas, nunca o valor.
- **Outputs gerados** — imagens, downloads, etc.

Por isso este repo aqui só tem `AGENTS.md`, skills e o `statusline-command.py`. Settings de ferramenta, config Codex, MCP tokens e cia ficam fora.

## Skills: global vs por projeto

Skills podem viver em dois lugares:

| Path | Escopo |
|---|---|
| `~/.claude/skills/<nome>/` ou `~/.agents/skills/<nome>/` | Disponíveis em todas as máquinas pro teu user |
| `<repo>/.claude/skills/<nome>/` ou `<repo>/.agents/skills/<nome>/` | Só naquele projeto |

Eu uso o global pro que é genérico (review, bootstrap, browser) e crio skills locais quando o projeto tem fluxo próprio.
Quando é algo específico, sigo a mesma ideia do symlink. Coloco tudo na pasta `.agents` do repo e faço symlink para Claude, etc.
