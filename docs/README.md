---
summary: "Index of durable docs for the agents setup."
read_when:
  - Looking for setup documentation.
  - Updating docs organization.
---

# docs

Documentação operacional do setup.

- `path-layout.md`: como as pastas locais se conectam e o mapa de symlinks.
- `reference.md`: referência completa do repo.

Docs de instrução de longo formato ficam em `../instructions/`:

- `../instructions/instruction-architecture.md`: como dividir instruções entre `AGENTS.md`, docs e skills.
- `../instructions/engineering-principles.md`: princípios de implementação.
- `../instructions/git-github.md`: fluxo de Git e GitHub.
- `../instructions/tooling.md`: catálogo de ferramentas.

Arquivos em `docs/` usam frontmatter para facilitar busca por agentes. Depois de editar, rode:

```bash
python3 scripts/validate-docs.py
```
