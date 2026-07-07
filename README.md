# agents-letras

Setup versionado para agentes de código: instruções globais, skills, subagents, configs do Claude, scripts de instalação e docs operacionais.

Este repo versiona o que é útil reaproveitar. Ele não versiona runtime gerado, trusted projects, tokens, caches, logs, pets ou estado sensível específico de uma máquina.

## Modos de uso

### Simples

Use os arquivos diretamente:

- `AGENTS.md` como instrução base.
- `skills/<categoria>/<skill>/` como catálogo de skills source.
- `claude/statusline-command.py` se quiser a statusline custom do Claude.

Nesse modo não precisa rodar installer nem `skills-cli`.

### Completo

Use o installer:

```bash
./install.sh
```

Ele cria um hub em `~/.agents`, gera `.runtime/skills` com o `skills-cli` e cria symlinks para o Claude.

## Layout

```text
AGENTS.md              # instruções base para agentes
agents/                # subagents
claude/                # settings, MCP template e statusline do Claude
docs/                  # docs operacionais: layout de paths e referência
instructions/          # docs longos de instrução referenciados pelo AGENTS.md
scripts/               # helpers de sync, validação e config
skills/                # skills source, agrupadas por categoria
skills.toml            # config do skills-cli
install.sh             # installer idempotente por symlink
.githooks/             # hooks locais opcionais
```

## O que fica fora

- `.runtime/`: gerado pelo `skills-cli`.
- trusted projects, OAuth, IDs de usuário e histórico local.
- `pets/`: não faz parte deste repo.
- secrets, tokens, `.env*`, trusted projects, logs e dumps de ambiente.

## Validação

```bash
skills --config skills.toml validate --plain
skills --config skills.toml plan --plain
python3 scripts/validate-docs.py
git diff --check
```

Quem não usa `skills-cli` pode ignorar os comandos de skills e copiar/symlinkar as pastas manualmente.

## Licença

O `LICENSE` (MIT) cobre apenas os arquivos próprios deste repo. Skills de terceiros em `skills/` mantêm suas licenças originais (ex.: várias skills do Google são Apache License 2.0); veja o arquivo de licença de cada skill.
