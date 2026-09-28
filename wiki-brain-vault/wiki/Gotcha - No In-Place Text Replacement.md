# Gotcha — No In-Place Text Replacement

## Symptom
The prototype "replaces every message on screen". On Android, other apps' text can't be changed.

## Root cause
AccessibilityService can *read* other apps' view trees and set text only in **editable** fields
(`ACTION_SET_TEXT`). Message bubbles are not editable, and there is no API to modify another app's views.

## Fix
Draw translated boxes in our own overlay exactly over each message node's `getBoundsInScreen`, styled
with [[Design System - Industry]]. Remove them on scroll/window-change (they'd drift). Tapping a box
opens the detail sheet.

## State (2026-09-28)
Implemented in Kotlin: `TranslationLayer` draws blueprint-styled boxes; cleared on scroll/window change.
Open: whether to re-position boxes on scroll instead of removing them (later improvement).

Links: [[Android Overlay and Accessibility]], [[Design Source]], [[Bubble Interaction Model]]
