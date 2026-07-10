# DA Music Licensing & Originality Policy

This policy guarantees that all integrations, features, and code written for DA Music are original and legally compliant, maintaining full licensing hygiene.

---

## 1. Reference & Copyleft Policy

- **Architectural Reference Only**: External repositories (such as `echo-nightly`) may only be studied to understand general client architectures, API endpoints, flow concepts, and session lifecycles.
- **Strict Clean-Room Principles**:
  - The repository MUST be closed before designing and implementing the corresponding feature in DA Music.
  - Translating, porting, or adapting external copyleft (e.g., GPL-3.0) source code is strictly prohibited.
- **Prohibited Code Reuse**: No copied lines of code, classes, functions, variable names, method names, algorithms, comments, request builders, or parsers from any copyleft project are permitted.

---

## 2. DA Music Service Architecture

- All integrations must be implemented from scratch to fit DA Music's native architecture:
  - **State Management**: Natively mapped via Riverpod providers and local SQLite/JSON storage systems.
  - **Networking & API Requests**: Built on top of DA Music's native request handler abstractions and services.
  - **Aesthetics & UI**: Built natively using the established design systems, spacing tokens, and typography definitions in `DATokens` and custom widgets.

---

## 3. Pull Request & Commit Review Rules

Every code change must be verified against:
- [ ] Fully original code, written from scratch.
- [ ] No copied source code, functions, classes, comments, or variable naming hierarchies.
- [ ] Maintain unmistakably original DA Music design.
