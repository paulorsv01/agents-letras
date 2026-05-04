# Skills — Review

Skills para revisão de código e simplificação de mudanças. Usam subagentes em paralelo para cobrir diff sem inflar o contexto do agente principal.

## Skills

### [`review-swarm`](review-swarm/SKILL.md)
Revisão **read-only** de um diff por quatro subagentes em paralelo. O agente principal filtra, ordena e resume só o que importa. Esta skill **não edita arquivos**.

- **Quando dispara:** "review swarm", "parallel review", "diff review", "regression review", "security review", quando quer issues de alto sinal + caminho de correção priorizado sem mexer em código.
- **Escopo (em ordem de preferência):** arquivos nomeados pelo usuário → mudanças git atuais → branch/commit/PR explicitamente pedido → mais recentemente modificados (apenas se o usuário pediu review e não há diff mais claro).
- **Cobertura:** regressões comportamentais, riscos de segurança/privacidade, problemas de performance/confiabilidade, gaps de contrato e cobertura de teste.
- **Saída:** lista priorizada de problemas, sem fixes aplicados.

### [`review-and-simplify-changes`](review-and-simplify-changes/SKILL.md)
Revisa código alterado para reuso, qualidade, eficiência e clareza. Usa subagentes Codex em paralelo (read-only) e o agente principal pode aplicar fixes seguros, preservando comportamento.

- **Quando dispara:** "simplify code", "review changed code", "check for code reuse", "review code quality", "review efficiency", "simplify changes", "clean up code", "refactor changes", "run simplify".
- **Modos:**
  - `review-only` — só revisa (pedidos como "review", "audit", "check"). Default quando o usuário pede revisão.
  - `safe-fixes` — revisa e aplica fixes seguros e high-confidence (pedidos como "simplify", "clean up", "refactor").
  - `fix-and-validate` — `safe-fixes` + roda a menor validação relevante depois das edições.
- **Regra dos subagentes:** sub-agentes só inspecionam código e mandam findings de volta. Quem aplica fix é o agente principal, e só fixes que preservam comportamento.
