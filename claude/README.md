# claude

Config para Claude Code.

## Arquivos

- `settings.json`: preferências globais do Claude, permissões, statusline e comportamento padrão.
- `claude.json`: baseline de estado/config do Claude, symlinkado para `~/.claude.json`.
- `mcp.json`: template de MCP servers (endpoints HTTP públicos); não guarda tokens nem valores secretos. Credenciais, se necessárias, ficam fora do repo.
- `statusline-command.py`: statusline custom com modelo, contexto restante, custo, branch e rate limits.
- `statusline.png`: preview visual da statusline.

## Instalação

O installer cria:

```text
~/.agents/claude             -> <repo>/claude
~/.claude/settings.json      -> ~/.agents/claude/settings.json
~/.claude.json               -> ~/.agents/claude/claude.json
~/.claude/CLAUDE.md          -> ~/.agents/AGENTS.md
~/.claude/agents             -> ~/.agents/agents
~/.claude/skills             -> ~/.agents/skills
```

`mcp.json` fica versionado como template. Se alguém quiser ativar no Claude:

```bash
ln -sf "$HOME/.agents/claude/mcp.json" "$HOME/.claude/mcp.json"
```

## Statusline

`settings.json` chama:

```text
python3 ~/.agents/claude/statusline-command.py
```

Requer Python 3.9+. A statusline honra `NO_COLOR` e `CLAUDE_STATUSLINE_NO_COLOR=1`.

## Segurança

Não coloque tokens reais neste diretório. Se uma integração exigir credencial, cada pessoa deve configurar o valor fora do repo.

Esta versão usa permissões mais seguras que uma config pessoal com bypass total. Quem quiser modo mais permissivo deve configurar isso localmente.
