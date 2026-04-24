# Claude Code Game Studios -- Жопокалипсис: Оборона Трона

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.6
- **Language**: GDScript (statically typed, primary)
- **Version Control**: Git with trunk-based development
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Target**: Mobile (Android + iOS), portrait orientation, Mobile renderer

## Game Identity

**Title**: Жопокалипсис: Оборона Трона (Apocabutt: Defense of the Throne)
**Genre**: Vertical portrait TD-RPG with active manual combat
**Tone**: Gross-out cartoon comedy — grotesque, adult, funny. NOT sexual/erotic/fetish.
**Platform**: Mobile first (Android/iOS). Portrait. Mobile renderer.
**Rating target**: 17+/Mature. Two content builds: `director_build` and `store_build`.

### Content Boundary (enforced on all agents)
- KEEP: toilet humor, slime, gross gags, crude language, cartoon violence, adult comedy
- BANNED: explicit nudity, sexual content, fetish framing, realistic bodily gore, minors in gross contexts

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **Game concept and engine are configured.** See `design/gdd/game-concept.md`.
> Master GDD at `design/gdd/master-gdd.md`. To continue: `/create-architecture` or `/dev-story`.

## Store Compliance

@docs/platform/store-compliance.md

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
