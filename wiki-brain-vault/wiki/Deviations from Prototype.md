# Deviations from Prototype

Recorded when the shipped app intentionally differs from `wiki-brain-vault/raw/design/`.

## Home translate-into card caption (Phase 4)

| Prototype | App |
|---|---|
| Always "From any language · detected automatically" | **Ready model:** "From any language · works offline". **Downloading:** "Downloading for offline use…". **Otherwise:** prototype line. |

Reason: the card reflects ML Kit model download state after the user picks a language (`Translator.ensureModel`).

Links: [[Screens and Flows]], [[Translation Pipeline]], [[Flutter App]]

## Update available sheet (Phase 13)

Not in the prototype. Bottom sheet on Home when a newer GitHub release exists: kicker "Update available",
"Version x.y.z", "Installed: …", release notes, buttons **Later** / **Update** (→ "Downloading n%" → **Install**).
Errors: "Couldn't download the update. Try again." / "Allow Relay to install apps, then tap Install."
See [[App Updates]].
