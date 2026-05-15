# AGENTS.md

## Escopo

- Regras globais para agentes de código que trabalham nesta família de repositórios.
- Instruções locais do repositório podem adicionar ou sobrescrever detalhes de arquitetura, stack, fluxo de trabalho e fonte da verdade.
- Restrições de segurança, proteção e ações destrutivas prevalecem sobre preferências locais.
- Mantenha este arquivo para regras duráveis. Coloque fluxos reutilizáveis em skills e decisões mais profundas em docs.
- Antes de trabalho não trivial, leia as instruções locais mais próximas e docs relevantes da área alterada.

## Comunicação

- Responda no idioma do usuário.
- Use linguagem simples e direta. Corte encheção. O suficiente para ser claro.
- Identificadores de código ficam em inglês.
- Comentários no código e textos de PR podem seguir a convenção de idioma do repositório.
- Se uma ideia vai quebrar, diga diretamente o motivo.
- Infira intenção pelo contexto antes de pedir esclarecimento.

## Regras de Decisão

- `analyze only`, `analysis only`, `let's discuss` ou equivalente significa não editar.
- Alvo ambíguo significa parar com `CLARIFICATION NEEDED` e perguntas numeradas.
- Verbos de ação claros como `fix`, `add`, `remove`, `run`, `install` ou `update` significam executar.
- Se o alvo está claro e apenas o método é incerto, descubra o método.
- Para trabalho não trivial, declare brevemente escopo, suposições, riscos principais e verificação antes de editar.
- Ao receber `continue`, `update` ou `keep going`, reancore no estado atual do repo, contexto da thread e última fatia combinada.
- Se receber correção, pare, reafirme a direção pedida, nomeie a lacuna e siga com o alvo corrigido.

## Ferramentas

- Prefira `rg` para busca em código quando disponível.
- Verifique ferramentas opcionais com `command -v tool &>/dev/null`.
- Use o gerenciador de pacotes e wrappers de tarefa já existentes no repositório.
- Não troque gerenciadores de pacote por preferência pessoal.
- Para helpers Python sem tooling específico do repo, prefira `uv` quando disponível.
- Use `gh` para operações no GitHub. Não use curl direto contra a API do GitHub.
- Use `gh` do `PATH`; não hardcode paths de binários específicos de máquina.

## Skills e Docs

- Skills são a camada de roteamento para fluxos reutilizáveis.
- Descrições de skills devem ser gatilhos curtos com escopo claro.
- O corpo da skill deve ser operacional: comandos, fontes da verdade, restrições, validação e armadilhas conhecidas.
- Não copie paths pessoais, contas, nomes de máquina, secrets, tokens ou hábitos locais para skills compartilhadas.
- Se um plugin instalado já fornece a mesma skill, mantenha uma cópia local apenas quando este repo adapta intencionalmente o comportamento.
- Prefira helper scripts apenas quando o fluxo for repetido e testável.
- Depois de editar skills, valide frontmatter, `name` e `description` obrigatórios, nomes duplicados, metadados e links runtime gerados quando houver tooling.

## Execução

- Leia código suficiente antes de editar. Leia o arquivo inteiro antes de alterá-lo.
- Planeje a mudança inteira, depois faça uma passada completa.
- Toque apenas os arquivos necessários para a tarefa.
- Não refatore código adjacente a menos que seja necessário para a correção pedida.
- Corrija a causa raiz quando for razoável. Band-aids precisam de justificativa explícita.
- Reuse helpers, padrões e limites de módulo existentes.
- Mantenha a implementação simples. Sem flexibilidade especulativa, abstrações de uso único, código morto ou breadcrumbs de compatibilidade.
- Se uma mudança tocar contratos, schemas, APIs, eventos ou formato de config, identifique consumidores antes de implementar.

## Verificação

- Nunca chame o trabalho de pronto sem prova.
- Rode testes, checks ou a validação disponível mais próxima.
- Para mudanças apenas em docs, rode pelo menos `git diff --check`.
- Reporte o que foi verificado e o que não foi.
- Se a validação falhar, a tarefa não está completa.

## Segurança

- Sem secrets hardcoded.
- Não leia `.env*`, dumps de ambiente, secrets locais ou output amplo de env a menos que seja pedido explicitamente.
- Se contexto de env for necessário, leia apenas `.env.example`.
- Se um secret for exposto, pare e avise para que ele seja rotacionado.
- Para textos públicos no GitHub com Markdown, shell snippets, crases, `$`, nomes de env ou texto vindo do usuário, escreva em um arquivo temporário, inspecione e use `--body-file`.

## Git

- Rode `git status --short` antes de editar em worktrees sujas ou multiagente.
- Nunca reverta mudanças do usuário sem pedido explícito.
- Não stage arquivos não relacionados.
- Não faça push, amend, force-push, rebase, merge ou troca de branch a menos que seja pedido explicitamente ou claramente exigido pelo comando solicitado.
- Nunca use `--no-verify`.
- Prefira comandos git não interativos. Use `GIT_EDITOR=true` quando um fluxo git puder abrir editor.
- Formato de commit: `<type>: <message>` com `feat|fix|docs|style|refactor|test|chore|perf`.
- Use o idioma e modo de commit esperados pelo repositório.
- Uma mudança lógica por commit.

## Ações Destrutivas

- Não edite arquivos via scripts shell como `perl`, `sed` ou rewrites em Python. Use edições por patch.
- Deletar arquivos é permitido apenas quando for exigido diretamente pela tarefa. Diga o que será deletado e por quê.
- `git reset --hard`, `git clean -fd`, `rm -rf` e comandos destrutivos de banco exigem aprovação explícita.
- Não crie arquivos de backup ou variantes como `_v2`, `_backup` ou `_new`.
