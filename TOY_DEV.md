# Toy Model Development (Project-Agnostic)

_Toys validate complex patterns and techniques before integrating into production code. They remain in the repo as reference artifacts—intermediate code that informs the final implementation._

---

## What Toy Models Are

- **Domain understanding tools**: Build minimal implementations to comprehend complex behavior
- **Pattern validators**: Test unfamiliar techniques, libraries, or approaches in isolation
- **Intermediate artifacts**: Code stays in repo as reference; lessons transfer to production
- **Risk reducers**: Validate complex subsystems before integrating into main codebase
- **Pattern libraries**: Discover reusable idioms and techniques for production use

## What Toy Models Are Not

- Not production code (production code lives in src/ or equivalent)
- Not comprehensive solutions (focus on one tricky subsystem)
- Not deleted after use (kept as reference, allowed dead code)
- Not shortcuts (experiments inform proper implementation)

---

## The Toy Model Cycle

**CRITICAL**: Every toy starts AND ends with LEARNINGS.md

### 1. Define Learning Goals (LEARNINGS.md - First Pass)
Before any implementation, write down what you need to learn.
- Questions to answer (e.g., "Does technique X work with constraint Y?")
- Decisions to make (e.g., "Which library/approach to use?")
- Success criteria (what patterns must be clear)
- **Start with questions, not answers**

### 2. Research & Implementation Loop
Iterate until learning goals are met:
- Study reference documentation/examples
- Try approaches in isolated context
- Test against known-good behavior or reference implementation
- **Update LEARNINGS.md with findings after each cycle**

### 3. Finalize Learnings (LEARNINGS.md - Final Pass)
Extract portable patterns for production implementation.
- Answer all initial questions
- Document chosen approach and rationale
- Patterns and techniques discovered
- How to integrate into main codebase

**Key insight**: LEARNINGS.md is both roadmap (goals) and artifact (findings)  

---

## Guiding Principles

- **Reference-driven validation**
  Test toy against known-good behavior or reference implementation. Same inputs → same outputs.

- **Unconstrained experimentation**
  Relax production constraints (performance, style, architecture). This is learning phase.

- **Pattern discovery**
  Document which approaches work and why. Understand trade-offs.

- **Minimal scope**
  One complexity axis per toy. Don't try to build entire system in toy.

- **Reusable idioms**
  Extract patterns that apply to similar problems elsewhere in production code.  

---

## Patterns That Work

- **Library validation toys**: Test unfamiliar libraries/APIs in isolation
- **Technique exploration toys**: Experiment with unfamiliar patterns or approaches
- **Subsystem toys**: Understand one complex module/component before integration
- **Integration toys**: Test how two validated subsystems interact

---

## Testing Philosophy

- **Golden tests**: Known-good reference is the oracle - same input must produce same output
- **Behavioral equivalence**: Toy must match reference behavior in observable ways
- **Contract tests**: Ensure libraries/APIs work as documented
- **Correctness validation**: Verify assumptions about behavior, performance, constraints  

---

## Strategic Guidance

- Pivot to simpler approach when patterns become too complex
- Extract reusable patterns for production implementation
- Toys remain in repo as reference - intermediate artifacts that inform production
- Use toys to de-risk complex subsystems before main implementation

---

## North Star

Toys are **reconnaissance, not construction**.

Scout unfamiliar territory without production constraints. Focus: understanding patterns and discovering constraints. Result: lessons applied to production code, toy kept as reference artifact.  