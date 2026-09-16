# TOXCARD

**Toxin · Agent · Pitfall**

Emergency toxicology decision support. 186 toxins, 78 antidote agents, 8 toxidromes.
Offline-first progressive web app. No server, no accounts, no patient data.

**Live:** https://choij1104.github.io/TOXCARD/

The name is the structure. Every entry is one card: what the patient took, what you give, and
the thing that kills them if you get it wrong.

## What this is

A bedside reference for trained clinicians. Every entry is toxin → agent → dose → **pitfall**,
because in poisoning the antidote is rarely the hard part; the timing, the endpoint, and the
contraindication are.

Not a protocol. Not a substitute for a regional poison center — 1-800-222-1222.

## Design commitments

Two things are deliberate and will not change without a reason better than aesthetics.

**The pitfall shares a screen with the dose.** No tab, no second page, no "see more". Anything
hidden behind a tap is not read during a resuscitation, and the pitfall is the part that
prevents the death.

**There is no account.** No sign-in, no guest mode, no gate of any kind between a clinician at
three in the morning and a dose. This is also what keeps the app serverless, offline-reliable,
and free of any patient data.

## Data model

Normalized into three tables with bidirectional links, so an agent resolves to every toxin it
treats — hemodialysis to 16, benzodiazepines to 14, sodium bicarbonate to 11.

```
index.html                view; carries an embedded baseline of all data
data/toxins.json          186 toxins — name, category, antidote availability
data/antidote-agents.json 78 agents — brands, class, the toxins each treats
data/protocols.json       186 protocols — tier, dose, pitfall, window, sources
data/toxidromes.json      8 patterns for the undifferentiated patient
data/version.json         version, review dates, changelog
sw.js                     service worker — offline shell and data
manifest.json             installable to the home screen
QA-log.md                 verification record
```

**Offline behaviour.** All data ships inside `index.html`, so the app opens with no network on
first launch, from any origin, even off the filesystem. When online it checks `version.json`
and pulls newer data in the background. A failed fetch changes nothing. The app never waits on
the network to render. There is no API and no backend.

The service worker serves the shell stale-while-revalidate: the cached copy answers at once,
and a background fetch refreshes it for the next launch, so a release reaches clients that
already have the app installed. Data is network-first with cache fallback. Web fonts are
cached on first sight so the typeface survives offline; if they never load, the system stack
is used.

**Platforms.** The same build runs as an installable PWA, as a Windows desktop app (Electron
wrapper, see the release notes), and as an Android package (Capacitor, for Play Store
distribution). Privacy policy: `privacy.html` — the app collects nothing.

## Features

**Weight-based dose resolution.** Enter a weight in Tools and every mg/kg, µg/kg, mL/kg,
units/kg and mg/m² expression resolves on the entry page. Ceilings stated in the same clause —
`max`, `up to`, `not to exceed` — are applied and flagged. mg/m² uses Mosteller and needs a
height. The source dose text is never rewritten; computed values sit in a separate panel
labelled with the weight used, carrying a standing note that the arithmetic does not know the
indication and cannot choose between conditional regimens.

**Toxidrome triage.** Eight patterns, each stating its discriminating finding — dry versus wet
skin for anticholinergic against sympathomimetic, rapid clonus against days of lead-pipe
rigidity for serotonin syndrome against neuroleptic malignant syndrome. Those confusions send
clinicians to the wrong antidote.

**Bidirectional browsing.** Open an agent to see every toxin it treats; open a toxin to see
every agent involved.

**Scoped search.** One search box over toxins, agents, brand names and tools, with scope chips
to narrow it. Synonyms and trade names are indexed.

**Chemical, fire and environmental casualties.** Vesicants (sulfur mustard, lewisite, phosgene
oxime), pulmonary agents (chlorine, phosgene), smoke inhalation as a single combined card,
Hymenoptera sting anaphylaxis, tick paralysis, and the industrial agents most often seen in an
emergency department — phosphides, methylene chloride, toluene, nickel carbonyl, cyanide salts,
carbon disulfide.

Saved entries, recently viewed, weight, and theme persist in browser storage and degrade
silently where storage is unavailable.

## Evidence tiers

| Tier | Meaning |
|---|---|
| A | FDA-approved specific antidote, strong or definitive evidence |
| B | Approved or guideline-endorsed standard of care, moderate evidence |
| C | Off-label; case series and expert consensus |
| D | Investigational, contested, or not obtainable in the US |
| N | No specific antidote exists; supportive care is the treatment (renders as "—") |

The badge beside the tier never contradicts it. A tier D entry reads **Investigational or
not obtainable**. A tier N entry with adjunct agents reads **No specific antidote ·
adjuncts only**, and its agent list is headed *Adjunct agents*, because bicarbonate for a
cocaine-related wide complex is not an antidote and the card should not imply it is.

72 of the 186 entries have no specific antidote (32 of those carry adjunct agents), and 10 more name an antidote that is investigational or not obtainable in the United States. They are included because the judgement still matters:
a button battery has no antidote and needs endoscopy within two hours, and Cortinarius has no
antidote and declares renal failure two to twenty days later.

## Updating

1. Edit the files in `data/`.
2. Bump `version`, `lastReviewed`, and the changelog in `data/version.json`.
3. Rebuild the embedded baseline in `index.html` and bump `CACHE` in `sw.js`.

Every protocol carries at least one named source. Review cadence is annual for the full
dataset and quarterly for supply-volatile agents — physostigmine, glucagon, antivenoms, DTPA.
Both dates are printed in the app, and the supply date is surfaced on the home screen.

---

TOXCARD is compiled by **Jae Hyek Choi, MSc, PhD, DVSc**
© 2026 Jae Hyek Choi. All rights reserved.
