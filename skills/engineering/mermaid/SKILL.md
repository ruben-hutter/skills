---
name: mermaid
description: Author diagrams as Mermaid code. Use when the user asks for a diagram, flowchart, architecture sketch, or to visualize a flow, process, schema, state machine, or schedule. Mermaid is the default diagram medium; reach for Excalidraw or canvas tools only when the user names them.
---

# Mermaid diagrams

Write diagrams as Mermaid inside fenced ```` ```mermaid ```` code blocks. They render natively on GitHub, GitLab, VS Code, Obsidian, and mermaid.live.

## Steps

1. **Pick the diagram type** from the ask — see the table below. Default flow questions to `flowchart TD` (top-down) or `flowchart LR` (left-right).
2. **Write the diagram** into a fenced ```` ```mermaid ```` block. If the diagram documents repo work, write it into the file being worked on (README, design doc, `docs/`); otherwise put the block directly in the reply.
3. **Check syntax against the pitfalls below** before presenting: unquoted labels with punctuation, the word `end` as a node id, and missing relationship arrows are the common breakages.
4. Done when the block is placed where the user will see it rendered and every pitfall rule has been applied.

## Render to an image (only if the user asks)

1. Check for the CLI: `command -v mmdc`. If present, write the diagram to a `.mmd` file and run `mmdc -i diagram.mmd -o diagram.svg`.
2. If `mmdc` is missing, `@mermaid-js/mermaid-cli` installs headless Chromium — confirm with the user before installing anything.

## Diagram types

| Ask | Type |
|---|---|
| Flow, decision, process, architecture | `flowchart TD` or `flowchart LR` |
| Messages between actors over time | `sequenceDiagram` |
| Lifecycle, modes, state machine | `stateDiagram-v2` |
| Database schema, entity relations | `erDiagram` |
| Class relationships | `classDiagram` |
| Schedule over time | `gantt` |
| Brainstorm / concept map | `mindmap` |
| Branch and merge history | `gitGraph` |

## Syntax essentials

- Node shapes in flowcharts: `A[text]`, `A(rounded)`, `A{decision}`, `A([stadium])`, `A[(database)]`, `A((circle))`.
- Edge labels: `A -->|yes| B` or `A -- yes --> B`. Dotted link: `A -.-> B`. Thick link: `A ==> B`.
- Quote any label containing punctuation, parentheses, or special chars: `A["Start (v2)"]`.
- Line breaks inside labels: `<br/>`, not `\n`.
- A node id or label of exactly `end` breaks flowchart parsing — use `End` or quote it.
- Grouping: `subgraph Title ... end` blocks nest; each closes with its own `end`.
- `sequenceDiagram`: participants are implicit on first use; `->>` request, `-->>` reply, `Note over A,B: text` annotation.
- `stateDiagram-v2`: `[*]` for start/stop, `StateA --> StateB : event` for transitions.
- `erDiagram`: `CUSTOMER ||--o{ ORDER : places`, attributes one per line as `int id PK`.
- `classDiagram`: `ClassA --> ClassB`, `ClassA *-- ClassB` composition, members indented under the class.
- `gitGraph`: `commit`, `branch name`, `merge name`, `checkout name`.
