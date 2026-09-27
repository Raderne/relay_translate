# Relay Translate

Android app that puts a floating **bubble** over any app (WhatsApp, Telegram, email…). **Hold** it to
translate every message on screen, **drag** it onto one message to translate just that one, **tap** a
translated message to copy it or reply in your language, and the reply gets translated back and pasted
into the app.

- Stack: Flutter (Android) + native Kotlin services + **on-device Google ML Kit translation** + sqflite.
  Azure Translator behind Node.js + SQLite is the backup plan if testers find ML Kit quality lacking. See [[Architecture]].
- Design source: [[Design Source]]; visual language: [[Design System - Industry]].
- Behaviour: [[Screens and Flows]], [[Bubble Interaction Model]].
- Build plan: [[Phases Roadmap]].

## State (2026-09-27)
Planning only. No application code yet; phases written in `phases/`.

## Parts
- [[Flutter App]] — onboarding, settings, history, Chatter demo.
- [[Android Overlay and Accessibility]] — the bubble over other apps + reading screen text.
- [[Backend API]] — conditional Azure proxy (Phase 12).
- [[Database Schema]] — on-device sqflite (+ server SQLite if Phase 12).
- [[Translation Pipeline]] — how text becomes a translation.
- [[Privacy and Permissions]] — what we read, when, and what Play requires.

## Known gotchas
- [[Gotcha - No In-Place Text Replacement]]
- [[Gotcha - Play Accessibility Policy]]
- [[Gotcha - Short Message Language Detection]]
