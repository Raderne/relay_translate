# Relay Translate — Wiki Index

Maintained by Claude. Entry point for the vault.

## Entities
- [[Relay Translate]] — the product: floating translate bubble over any Android app; links to everything
- [[Architecture]] — Flutter + native Kotlin + on-device ML Kit; Azure/Node/SQLite as backup; key decisions
- [[Flutter App]] — `app/` layout, conventions, platform channels
- [[Android Overlay and Accessibility]] — Translator (ML Kit), bubble service, accessibility reader, translation layer, paster
- [[Backend API]] — CONDITIONAL (Phase 12): Node proxy to Azure Translator
- [[Database Schema]] — on-device sqflite tables (+ server SQLite if Phase 12)

## Concepts
- [[Bubble Interaction Model]] — gesture state machine and every timing/size number (mirrored Dart ↔ Kotlin)
- [[Screens and Flows]] — all screens and the 5 main user flows
- [[Translation Pipeline]] — ML Kit on-device: batch language-id → model download → translate; Phase 10 evaluation gate
- [[Privacy and Permissions]] — permissions, user-facing promises, disclosure text
- [[Design System - Industry]] — blueprint visual language and Flutter port rules
- [[Deviations from Prototype]] — intentional UI/copy differences from the Claude Design file
- [[Phases Roadmap]] — phase list + status, points to `phases/`

## Sources
- [[Design Source]] — Claude Design prototype (raw copies in `raw/design/`) and what it fakes

## Known Gotchas
- [[Gotcha - No In-Place Text Replacement]] — other apps' text can't be edited; draw boxes over it
- [[Gotcha - Play Accessibility Policy]] — Play restrictions on AccessibilityService; de-risk early
- [[Gotcha - Short Message Language Detection]] — ML Kit mis-detects short chat messages; detect on the batch

## Meta
- [[CLAUDE.md Rules]] — summary of repo hard rules
- [[Wiki-Brain Setup]] — how this vault is wired and maintained
