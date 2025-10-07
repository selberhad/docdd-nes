# CODE_MAP.md

Root-level project structure for docdd-nes NES game development.

## Documentation (Agent Instructions)

### **AGENTS.md**
Condensed quick reference for AI assistants. Bullet-point version of CLAUDE.md covering critical rules, workflow, tools, and key documents.

### **CLAUDE.md**
Full development guidelines for Claude Code. Covers methodology, best practices (autonomy, constraints, testing), tooling philosophy, documentation conventions, and NES-specific guidelines.

### **ORIENTATION.md**
Navigation guide for the project. Describes structure, tools, utilities, testing infrastructure, workflow patterns, and common commands. Stable reference (updates only when structure changes).

### **NEXT_SESSION.md**
Ephemeral session handoff notes (gitignored). Current status and next steps. Written at end of session for next AI agent.

## Documentation (Methodology)

### **DDD.md**
Doc-Driven Development methodology (project-agnostic). Economic inversion, role-based division, operational modes (Discovery/Execution/Porting), core artifacts, workflow.

### **TOY_DEV.md**
Toy development workflow (project-agnostic). Learning-first approach for experimental validation.

### **TOY_DEV_NES.md**
NES-specific toy development workflow. Builds on TOY_DEV.md with hardware-specific patterns.

### **TESTING.md**
Testing strategy for LLM-driven NES development. Play-spec design (Perl DSL), 3-phase automation plan, 14 design questions answered.

### **STUDY_PLAN.md**
NESdev wiki study roadmap. 52 pages organized by priority, study workflow, learning goals.

### **README.md**
Project overview and vision. Dual deliverable (mdBook + toy library), DDD in greenfield context.

## Code

### **lib/**
Testing infrastructure code (production). Contains NES::Test Perl module (play-spec DSL) and nes-test-harness.js (jsnes wrapper). See lib/CODE_MAP.md.

### **tools/**
Utility scripts for scaffolding, testing, inspection, and documentation. Bash/Perl automation tools.

## Artifacts

### **toys/**
Experimental test ROMs (Discovery mode). Each toy validates one subsystem (toolchain, sprites, PPU, controllers, NMI, scrolling). Treated as historical artifacts.

### **learnings/**
Technical learning documents extracted from wiki study. Architecture, techniques, toolchain, optimization, audio, mappers. See learnings/README.md.

### **docs/**
Project documentation including blog posts (AI-written reflections) and guides. See docs/blog/README.md for blog index.
