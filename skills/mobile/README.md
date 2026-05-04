# Skills — Mobile

Skills para desenvolvimento mobile: Android (Kotlin/Compose, AGP, R8, Play Billing, Navigation 3, Material 3) e Apple (SwiftUI, Swift Concurrency, XcodeBuildMCP, KMP).

## Android

### [`agp-9-upgrade`](agp-9-upgrade/SKILL.md)
Migra um projeto Android para Android Gradle Plugin (AGP) versão 9. Skill oficial do Google.

- **Quando dispara:** "atualiza para AGP 9", "migra esse projeto para AGP 9", problemas de compatibilidade após upgrade.
- **Como usar:** se o projeto está em AGP < 9, ela pede para você rodar o AGP Upgrade Assistant no Android Studio primeiro. A partir de AGP 9, segue o guia de migração (`references/android/build/releases/agp-9-0-0-release-notes.md`) para tratar mudanças breaking, novo DSL e built-in Kotlin.

### [`android-bootstrap`](android-bootstrap/SKILL.md)
Scaffold de app Android Kotlin/Compose **sem Android Studio**.

- **Quando dispara:** "cria um app Android do zero", "monta esse projeto sem IDE".
- **Fluxo de 2 passos:** (1) `bootstrap.sh <AppName> <package.id>` gera estrutura com AGP/Gradle pinados, ktlint, JUnit + MockK + Turbine, pre-commit hook, `version.env`. Pergunta sobre add-ons (Koin DI, multi-módulo). (2) Loop de dev via `Makefile`: `make dev`, `make emulator`, `make test`, `make release` (gera AAB assinado e cria release no GitHub via `gh`).
- **Delega para `agents-bootstrap`** se o repo precisar de `AGENTS.md` local.

### [`android-cli`](android-cli/SKILL.md)
Referência do CLI `android` para criação de projetos, deploy, gerenciamento do SDK e diagnóstico de ambiente.

- **Quando dispara:** comandos como `android sdk install`, `android create`, `android docs`, ou quando outras skills (`android-bootstrap`) precisam da camada de baixo nível.
- **Inclui:** `sdk install/update/remove/list`, `create` a partir de templates, busca em docs oficiais via `android docs`.

### [`android-emulator-qa`](android-emulator-qa/SKILL.md)
Valida fluxos de feature em emulador Android usando `adb`: launch, input, inspeção de UI tree, screenshots, logcat.

- **Quando dispara:** "testa esse fluxo no emulador", "reproduz esse bug de UI", "captura logcat enquanto navego".
- **Quick start:** `adb devices` → `./gradlew :<module>:install<Variant>` → `adb shell am start` → `screencap` para verificação visual.
- **Cobre:** taps por coordenadas vindas da UI tree, swipes, captura de logs.

### [`edge-to-edge`](edge-to-edge/SKILL.md)
Migra apps Jetpack Compose para suporte adaptativo de edge-to-edge e resolve problemas comuns de UI sob status/navigation bar.

- **Quando dispara:** "implementa edge-to-edge", "componentes obscurecidos pela navigation bar", "status bar legível", "IME insets quebrado".
- **Cobre:** insets adaptativos, legibilidade de system bars, fix de componentes obscurecidos, IME handling em Compose.

### [`kmp-bootstrap`](kmp-bootstrap/SKILL.md)
Scaffold de Kotlin Multiplatform (Android + iOS) **sem Android Studio nem iteração apertada com Xcode**.

- **Quando dispara:** "cria um app KMP do zero", "monta projeto multiplataforma".
- **Layout:** segue o "full restructure" do AGP 9 — `shared/` (KMP library) consumido por `androidApp/` e `iosApp/`. Compose Multiplatform por cima.
- **Dev loop:** `xcrun simctl` para iOS, `adb` para Android, sem IDE para o dia a dia. Makefile com `make dev-android`, `make dev-ios`, `make xcframework`, `make test`, `make ios-test`.

### [`material-3`](material-3/SKILL.md)
Implementa Material Design 3 (Material You). Foco principal: Jetpack Compose Material3. Cobre também Flutter e `@material/web` (esse em modo manutenção).

- **Quando dispara:** "material design", "MD3", "Material You", "Jetpack Compose", "MaterialTheme", componentes M3 específicos.
- **Cobre:** tokens, 30+ componentes, layout adaptativo (5 window size classes), theming (dynamic color, surfaces tonais), M3 Expressive (matriz de plataformas), acessibilidade.
- **Invocável também via:** `/material-3 [component|theme|layout|scaffold|audit] [descrição ou URL]`.

### [`migrate-xml-views-to-jetpack-compose`](migrate-xml-views-to-jetpack-compose/SKILL.md)
Workflow estruturado em 10 passos para migrar uma View Android XML para Jetpack Compose. Skill oficial do Google.

- **Quando dispara:** "migra essa tela XML para Compose", "converte essa View legada".
- **Cobre:** planejamento, dependências, tema, migração de layout, validação visual e funcional, limpeza do XML antigo. Mantém interoperabilidade durante a transição. Migra **só UI**, não lógica.

### [`navigation-3`](navigation-3/SKILL.md)
Instala e migra para Jetpack Navigation 3. Skill oficial do Google.

- **Quando dispara:** "migra para Navigation 3", "implementa deep links", "como faço múltiplas backstacks", "como retornar resultado de um flow".
- **Cobre:** `NavKey`, `NavHost`, `NavDisplay`, scenes (dialogs, bottom sheets, list-detail, two-pane, supporting pane), navegação condicional (logado vs anônimo), retorno de resultados, integração com Hilt/ViewModel/Kotlin, interop com Views.

### [`play-billing-library-version-upgrade`](play-billing-library-version-upgrade/SKILL.md)
Atualiza qualquer versão legada da Google Play Billing Library (PBL) para a última estável. Skill oficial do Google.

- **Quando dispara:** "atualiza Play Billing", "migra PBL", builds quebrando por APIs deprecated do `BillingClient`.
- **Como usa:** Phase 0 anuncia a ação. Phase 1 descobre a versão atual via `build.gradle(.kts)` ou `libs.versions.toml`, tenta um build inicial, e se falhar varre o código por artefatos deprecated. Depois aplica as mudanças necessárias e valida.

### [`r8-analyzer`](r8-analyzer/SKILL.md)
Analisa keep rules de R8/ProGuard para identificar redundâncias, regras pacote-amplas e regras que englobam consumer keep rules de bibliotecas. Skill oficial do Google.

- **Quando dispara:** "otimiza o tamanho do app", "remove keep rules redundantes", "audita ProGuard", "por que meu APK está grande".
- **Saída:** gera `R8_Configuration_Analysis.md` com a configuração atual, libs com keep rules desnecessárias (Google, AndroidX, Kotlin, Room, Gson, Retrofit), regras subsumidas, e recomendação de remover ou refinar cada regra.

## Apple / iOS / macOS

### [`swift-concurrency`](swift-concurrency/SKILL.md)
Best practices de Swift Concurrency: `async/await`, actors, tasks, Sendable, isolated conformances, migração para Swift 6 e Swift 6.2.

- **Quando dispara:** menções a Swift Concurrency, "use modern concurrency patterns", migração para Swift 6, approachable concurrency / main-actor-by-default, data races, `@MainActor`/`Sendable`/isolation, warnings de lint relacionados.
- **Contrato de comportamento:** identifica primeiro o language mode (Swift 5.x vs 6) e a fronteira de isolation. Não recomenda `@MainActor` como bala de prata. Prefere structured concurrency. Exige justificativa documentada para `@preconcurrency`, `@unchecked Sendable`, `nonisolated(unsafe)`.

### [`swiftui-expert-skill`](swiftui-expert-skill/SKILL.md)
Escreve, revisa ou melhora código SwiftUI seguindo best practices Apple-native: arquitetura MV simples (não MVVM por padrão), state management `@Observable`-first, composição de view, performance, e Liquid Glass (iOS 26+) opcional.

- **Quando dispara:** novas features SwiftUI, refatoração, padronização de arquitetura, code review, adoção de Liquid Glass.
- **Workflow:** usa árvore de decisão e referências internas (`references/state-management.md`, `view-structure.md`, `performance-patterns.md`, `list-patterns.md`, `animation-basics.md`, `liquid-glass.md`).

### [`swiftui-performance-audit`](swiftui-performance-audit/SKILL.md)
Diagnostica problemas de performance em SwiftUI a partir de revisão de código primeiro, depois pede evidência de profiling se o código sozinho não basta.

- **Quando dispara:** "scroll travado", "renderização lenta", "alto CPU/memória", "view atualizando demais", "layout thrash".
- **Workflow:** classifica o sintoma → revisão code-first via `references/code-smells.md` → se inconclusivo, guia o usuário pelo Instruments via `references/profiling-intake.md` → resume causas, evidências, remediação e validação via `references/report-template.md`.

### [`swiftui-ui-patterns`](swiftui-ui-patterns/SKILL.md)
Padrões de UI SwiftUI: hierarquias de navegação, view modifiers customizados, layouts responsivos com stacks e grids.

- **Quando dispara:** criar/refatorar UI SwiftUI, arquitetar tabs com `TabView`, compor telas com `VStack`/`HStack`, gerenciar `@State`/`@Binding`, precisar de exemplo concreto por componente.
- **Tracks:** projeto existente (procura exemplo próximo no repo, aplica convenções locais) ou scaffold novo (começa em `references/app-wiring.md` para `TabView` + `NavigationStack` + sheets).
- **Regras:** state SwiftUI moderno (`@State`, `@Binding`, `@Observable`, `@Environment`), evita view models desnecessários.

### [`xcodebuildmcp-cli`](xcodebuildmcp-cli/SKILL.md)
CLI oficial do XcodeBuildMCP — substitui `xcodebuild`, `xcrun` e `simctl` brutos.

- **Quando dispara:** trabalho em iOS/macOS/watchOS/tvOS/visionOS — build, test, run, debug, log, automação de UI.
- **Como usar:** verifique `xcodebuildmcp --help`. Instale via `brew tap getsentry/xcodebuildmcp && brew install xcodebuildmcp` ou `npm install -g xcodebuildmcp@latest`.
