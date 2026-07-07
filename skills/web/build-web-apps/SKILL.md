---
name: build-web-apps
description: "End-to-end web UI work — single entry point that pulls in the design, build, polish, and React/Next performance skills. Use when designing or building a website, landing page, app UI, or component, from direction through audit."
---

# Build Web Apps

Umbrella entry point for web UI work. Invoke this, then load member skills by phase as the task moves from direction to build to polish to audit.

## When to use

- Designing or building a website, landing page, app screen, or component
- Any multi-step web UI task that spans direction, build, polish, and review

For a single narrow task, the specific member skill below still applies on its own.

## Member skills — load by phase

**Direction & aesthetics**
| Skill | Pull in when |
|---|---|
| `product-ui-direction` | Deciding what kind of interface this should be (category, mode, pattern, style) before designing |
| `frontend-design` | Setting a distinctive aesthetic direction, palette, and typography that doesn't read as templated |

**Build**
| Skill | Pull in when |
|---|---|
| `tailwind-ui` | Building new UI with the ui.sh Tailwind design-guideline system — the primary build skill |
| `markup-from-image` | Starting from a screenshot, Figma export, mockup, or wireframe → semantic unstyled markup |
| `material-3` | Implementing Material Design 3 / Material You tokens and theming (MD3 for web or Flutter) |
| `ui-picker` | Comparing multiple candidate UI options in-browser with the ui.sh picker before committing to one |

**Polish & craft**
| Skill | Pull in when |
|---|---|
| `design-engineering` | Accessible, polished craft: components, forms, touch, a11y, layout shift, dark mode, performance |
| `web-animation-design` | Motion: easing, springs, transitions, Framer Motion, reduced motion |

**Refactor & adapt**
| Skill | Pull in when |
|---|---|
| `make-responsive` | Adapting an existing desktop UI across mobile/tablet/desktop breakpoints |
| `componentize` | Extracting repeated UI into reusable components with thoughtful APIs |
| `canonicalize-tailwind` | Sorting, normalizing, deduplicating, and resolving conflicting Tailwind classes |

**Audit**
| Skill | Pull in when |
|---|---|
| `web-design-guidelines` | Auditing existing UI code against the Vercel Web Interface Guidelines |

**Framework & performance (React / Next.js)**
| Skill | Pull in when |
|---|---|
| `next-best-practices` | Next.js file conventions, RSC boundaries, data patterns, metadata, route handlers |
| `next-cache-components` | Next.js 16 Cache Components: PPR, `use cache`, `cacheLife`, `cacheTag`, `updateTag` |
| `react-best-practices` | Vercel React/Next performance rules: waterfalls, bundle size, RSC/SSR, hydration |
| `react-component-performance` | Profiling and fixing a slow component: re-render thrash, laggy lists, expensive work |

## How to use

1. Invoke the member skills relevant to the task; you rarely need all of them at once.
2. Typical flow: `product-ui-direction` → `frontend-design` → `tailwind-ui` (build) → `design-engineering` + `web-animation-design` (polish) → `make-responsive` / `componentize` / `canonicalize-tailwind` (refactor) → `web-design-guidelines` (audit).
3. Pull the React/Next members when the stack is React/Next; add `react-component-performance` / `react-best-practices` when the performance concern is in a React or Next.js app.
4. Follow each member skill's own guidance; they are the source of truth.

## Note

This is a dispatcher. It holds no rules of its own — the authority lives in the member skills. Keep them as the source of truth and update them, not this file.
