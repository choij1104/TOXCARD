# Antidote Reference — Verification & Debug Log

**File:** index.html (115 entries, 18 categories)
**Author:** Jae Hyek Choi, MSc, PhD, DVSc
**Date closed:** 2 August 2026
**Total checks:** 75 (26 source verifications, 49 automated code and consistency tests)
**Corrections applied:** 11

---

## 1. Source verification against FDA labeling and primary literature

Twenty-six numeric or regulatory claims were checked against the FDA label, the manufacturer's
prescribing information, or the governing guideline. Every dose in the file that could cause harm
if wrong was checked; none were accepted from memory.

| # | Claim checked | Source | Result |
|---|---|---|---|
| 1 | Hydroxocobalamin is first-line for cyanide; nitrite is not | FDA 2006 approval, AHA 2023 | Confirmed |
| 2 | Andexanet ANNEXA-I thrombotic rate ~10%; heparin resistance | NEJM 2024, ATVB 2025 | Confirmed |
| 3 | Bentracimab regulatory status | SERB/SFJ BLA, ACC.25 | Not approved — marked tier D |
| 4 | Nalmefene nasal 2.7 mg, FDA May 2023, age >=12 | Opvee label | Confirmed |
| 5 | Physostigmine US manufacturing ceased (Akorn 2023) | FDA importation notice | Confirmed |
| 6 | Rivastigmine alternative dosing | Am J Emerg Med 2025; Regul Toxicol Pharmacol 2025 | Confirmed |
| 7 | Digibind discontinued in US; DigiFab only product | AHFS monograph, FDA label | Confirmed |
| 8 | Flumazenil not recommended routinely | AHA guidelines, 2016 meta-analysis | Confirmed |
| 9 | Massive APAP: fomepizole + HD adjuncts | Clin Toxicol 2023 case series | Confirmed, kept tier C |
| 10 | Glucarpidase 50 U/kg; leucovorin is a substrate | Voraxaze FDA label | Confirmed |
| 11 | Uridine triacetate 10 g q6h x20; 96-hour window | Vistogard FDA label | Confirmed |
| 12 | Radiation MCMs incl. romiplostim (Jan 2021) | FDA MCM page, ORISE REAC/TS | Confirmed |
| 13 | CroFab vs Anavip loading and maintenance | Package inserts; J Med Toxicol 2023 | Confirmed |
| 14 | Idarucizumab 5 g as 2 x 2.5 g | Praxbind FDA label | Confirmed |
| 15 | ASRA 2020 lipid emulsion volumes | ASRA LAST checklist | Confirmed |
| 16 | Methylene blue G6PD contraindication; 7 mg/kg ceiling | ProvayBlue label | Confirmed |
| 17 | BAT heptavalent via CDC EOC; BabyBIG via CA program | FDA label, CDC formulary | Confirmed |
| 18 | Nerve agent autoinjector 2.1 mg / 600 mg | DuoDote/ATNAA label | Confirmed |
| 19 | HIET 1 U/kg bolus then 1-10 U/kg/h | Am J Ther 2025; LITFL | Confirmed |
| 20 | Amatoxin: no FDA-approved therapy; silibinin investigational | MMWR May 2026 | Confirmed |
| 21 | Lead chelation sequence BAL before EDTA | AAP; Medscape guidelines | Confirmed |
| 22 | Octreotide 50-100 ug q6h for sulfonylurea | J Med Toxicol; Ann Emerg Med | Confirmed |
| 23 | DigiFab vial formula (level x kg) / 100 | DigiFab FDA label | Confirmed, entry refined |
| 24 | Andexanet 400/480 and 800/960 mg regimens | Andexxa FDA label | Confirmed, selection rule added |
| 25 | Sugammadex 2 / 4 / 16 mg/kg; 7-day contraceptive warning | Bridion FDA label | Confirmed, qualifier added |
| 26 | KI 130 / 65 / 32 / 16 mg by age | FDA KI guidance | Confirmed, ladder corrected |
| 27 | Anascorp 3 vials; BabyBIG 50 mg/kg | FDA labels | Confirmed, administration detail added |
| 28 | Dexrazoxane 1000/1000/500 mg/m2 within 6 h | Totect FDA label | Confirmed, caps added |
| 29 | Deferoxamine 15 mg/kg/h; ARDS beyond 24 h | Desferal label; INCHEM | Confirmed, 6 g ceiling added |
| 30 | Pralidoxime 30 mg/kg then 8-10 mg/kg/h | WHO regimen; Goldfrank's | Confirmed, caps added |
| 31 | Prussian blue 3 g TID adult, 1 g TID paediatric | Radiogardase FDA label | Confirmed, paediatric added |

## 2. Corrections applied

1. DigiFab — staged 10 + 10 vial dosing per label; paediatric <20 kg vial note added.
2. Sugammadex — 16 mg/kg indication qualified to a single 1.2 mg/kg rocuronium dose.
3. Potassium iodide — full FDA age ladder (130 / 65 / 32 / 16 mg) and the >=70 kg adolescent rule.
4. Dexrazoxane — maximum daily doses (2000 / 2000 / 1000 mg) and 50% reduction if CrCl <40 mL/min.
5. Deferoxamine — label ceiling of 6 g/24 h stated, with the note that practice commonly exceeds it.
6. Pralidoxime — 2 g loading cap and 650 mg/h infusion cap added.
7. Anascorp — dilution to 50 mL, 10-minute infusion, 60-minute post-infusion monitoring.
8. BabyBIG — infusion rate (0.5 then 1.0 mL/kg/h) and dedicated-line requirement.
9. Prussian blue (thallium) — paediatric 1 g TID and expected 30-day course.
10. Andexanet — explicit low-dose vs high-dose selection rule, including the unknown-timing default.
11. Dapsone methemoglobinemia — G6PD status check added before methylene blue.

## 3. Automated test results

All 49 automated checks pass. Coverage:

- **Structure and syntax (10):** JS parses, schema complete on all 115 entries, valid tier values,
  no duplicate toxins or toxin/antidote pairs, balanced tags, no template-literal breakers.
- **Offline integrity (5):** no external src or href, no fetch or XHR, no localStorage or
  sessionStorage, no companion assets, complete standalone document.
- **Security and escaping (4):** esc() covers & < > and quotes; the 26 entries using > or < as
  clinical thresholds are escaped at render; no tag-like sequences anywhere in the data.
- **Accessibility and presentation (6):** lang attribute, charset, viewport, visible focus styles,
  aria-pressed on filters, aria-label on search, print stylesheet, reduced-motion respected.
- **Medication-error prevention (4):** unit symbols consistent (ug throughout, no mcg), no naked
  decimals such as .5 mg, trailing-zero instances reviewed and confirmed to be pH values, FiO2, and
  serum levels rather than doses, weight-based dosing present on every paediatric-specific entry.
- **Search behaviour (3):** 18 trade names findable (Cyanokit, DigiFab, Praxbind, Andexxa, Voraxaze,
  Vistogard, Radiogardase, Anascorp, CroFab, Anavip, BabyBIG, Totect, Bridion, Opvee, Pedmark,
  Ryanodex, DuoDote, Nithiodote); nonsense queries return zero; render markup balanced across all
  115 cards.
- **Clinical consistency (10):** G6PD caution on all four methylene-blue entries, cyanide entries
  agree internally, physostigmine supply status noted, flumazenil never framed as routine, BAL
  contraindication in methylmercury captured, Digibind discontinuation flagged, all investigational
  agents held at tier D, tier-N entries never imply an antidote exists.
- **Policy compliance (4):** copyright and credentials intact, prohibited affiliation terms absent,
  disclaimer language intact, no debug artefacts left in production.

## 4. Known limitations

- Doses are adult unless stated. Paediatric weight-based dosing is given only where it differs
  materially from the adult approach.
- Regulatory status is current as of 2 August 2026. Bentracimab, IV silibinin, and cobinamide were
  in motion at the time of writing and are labelled accordingly.
- Extracorporeal indications follow EXTRIP but individual thresholds vary by workgroup revision.
- This is decision support, not a protocol. Institutional formulary confirmation is required before
  administration, and a regional poison centre remains the authority in any live case.


---

# Step 2 — Provenance completion (3 August 2026)

**Dataset version:** 2026.08.03
**Coverage:** 115/115 entries sourced · 153 source references

## What changed

Every entry now carries at least one named source. Before this pass, 32 entries were sourced
and 83 were not — meaning most of the file was, from a reader's point of view, one person's
assertion. That is the difference between a document and a reference.

### Source distribution

| Type | Count | What it means |
|---|---:|---|
| FDA label | 50 | Manufacturer's prescribing information for an approved product |
| Guideline | 41 | AHA, ASRA, WHO, UHMS, ASCO, AASLD, ATA, ONS, ASA, ESGE, HHS CHEMM/REMM |
| Textbook | 29 | Goldfrank's Toxicologic Emergencies |
| Consensus | 16 | EXTRIP, AACT/EAPCCT position papers, ACMT lipid emulsion workgroup |
| Literature | 6 | Named case series and reviews |
| CDC | 6 | CDC clinical guidance and MMWR |
| Trial | 3 | ANNEXA-I, PATCH, REVERSE-IT |
| FDA notice | 2 | Importation notices and shortage bulletins |

### Corrections found during this pass

**15. EXTRIP attribution.** The extracorporeal entry listed ethylene glycol among the
EXTRIP-supported indications. The workgroup has published systematic reviews on thirteen
poisonings — acetaminophen, barbiturates, carbamazepine, digoxin, lithium, metformin,
methanol, phenytoin, salicylates, thallium, theophylline, tricyclic antidepressants, and
valproate — and ethylene glycol is not among them. It remains a standard dialysis indication
on other grounds, and the entry now says so. A note was also added that several EXTRIP
recommendations are recommendations *against* dialysis, so citing the workgroup is not
the same as citing support.

**16. Tier-A provenance floor.** Two tier-A entries — pyridoxine for isoniazid seizures and
anticholinergic therapy for acute dystonic reaction — initially rested on a textbook alone.
Both have labelled indications, and both now cite the prescribing information. No tier-A
entry now rests on a textbook as its only source.

**17. Taxonomy normalised.** Fourteen ad-hoc source types were collapsed to eight, so the
field can be filtered and so a reader can weigh an FDA label against a textbook at a glance.
The type is now rendered as a badge on each source line.

## Build defect found and fixed

Rebuilding the embedded baseline with a regular-expression substitution silently destroyed
the dataset: Python's `re.sub` processes backslash escapes in the replacement string, so every
`\n` inside the JSON dose fields became a literal newline, breaking the JavaScript string
literals and preventing the app from parsing its own data. The rebuild now uses index-based
slicing instead of regex, and the test suite gained two checks — that the data block still
parses, and that 103 entries retain multi-line dose blocks — so the same failure cannot pass
review again.

This is worth recording because the failure was silent at the point of edit and would have
shipped a blank application.

## Test results

25/25 regression checks pass, covering data integrity, newline preservation, source coverage,
version synchronisation, offline fallback, non-blocking update, same-origin fetch policy,
brand search, and policy compliance.

## Remaining work

- Weight-based dose calculation, toxidrome entry path, Dart stocking tier (step 3).
- Departmental toxicology review — the intended validation step.
- Review cadence: full dataset annually, supply-volatile agents quarterly. The next supply
  check is due 3 November 2026 and covers physostigmine, glucagon, antivenoms, and DTPA.


---

# Step 3 — Weight resolution, toxidrome triage (4 August 2026)

**Dataset version:** 2026.08.04

## Weight-based dose resolution

Enter a weight once and every weight- or BSA-indexed expression in the file resolves.
The engine recognises mg/kg, µg/kg, g/kg, mL/kg, units/kg and mg/m², with or without a rate
suffix, and handles ranges. Body surface area uses Mosteller and requires a height; without
one, mg/m² expressions say so rather than guessing.

**Ceilings are honoured** where they are stated in the same clause — `max`, `maximum`,
`up to`, and `not to exceed` are all recognised, and a capped value is flagged in red with
the ceiling named. Pralidoxime at 100 kg resolves to 3,000 mg by arithmetic and is shown as
2,000 mg capped; pyridoxine at 100 kg resolves to 7,000 mg and is shown as 5,000 mg capped.

**Design constraints, deliberately:**

- The source dose text is never rewritten. Computed values appear in a separate, differently
  coloured panel labelled with the weight used.
- Nothing is computed until a weight is entered.
- The panel carries a standing warning that the arithmetic does not know the indication,
  cannot choose between conditional regimens written for different weight bands, and cannot
  apply a ceiling that is not written in the same clause.

The rationale is the error literature: medication errors are reported in up to 41% of
paediatric resuscitations, incorrect dose accounts for up to 65% of those, and tenfold errors
recur. A validated dosing application reduced errors from 70% to 0% in a randomised
comparison. That benefit comes from removing arithmetic under stress, not from removing
judgement, which is why the original text stays visible.

### Parser test results — 18/18 correct

Verified against real strings from the dataset: deferoxamine 15 mg/kg/h, NAC 150 mg/kg,
pralidoxime dual ceilings, methylene blue 1–2 mg/kg range, pyridoxine `up to 5 g` above and
below the ceiling, glucarpidase 50 units/kg, HIET 1 U/kg and 1–10 U/kg/h, BabyBIG 50 mg/kg
with 0.5 and 1.0 mL/kg/h infusion rates, lipid emulsion 1.5 mL/kg and 0.25 mL/kg/min,
dexrazoxane 1000 mg/m² with and without a height and above its ceiling, romiplostim
10 µg/kg, succimer 10 mg/kg at 20 kg, a string with no weight-based expression, and the
no-weight-entered case.

## Toxidrome triage

Eight patterns for the patient who arrives with no history: cholinergic, anticholinergic,
sympathomimetic, opioid, sedative-hypnotic, serotonin syndrome, neuroleptic malignant
syndrome, and metabolic acidosis with hyperventilation.

Each carries onset, pupils, skin, vitals, mental status, likely agents, and — the reason the
layer exists — the **discriminating finding**. Anticholinergic against sympathomimetic turns
on dry versus wet skin. Serotonin syndrome against neuroleptic malignant syndrome turns on
rapid onset with lower-limb clonus against days of lead-pipe rigidity with hyporeflexia.
Those two confusions send clinicians to the wrong antidote, so they are stated explicitly
rather than left to be inferred from a table.

Every toxidrome links through to the matching antidote entries; all eight searches were
verified to resolve to at least one entry.

## Dart stocking tier — deliberately not populated

The schema now carries a `stockingTier` field, and it is empty. The Dart expert consensus
considered 45 antidotes and recommended stocking 44, of which 23 should be immediately
available, 14 within one hour of the decision to administer, and a further 8 stocked but not
necessarily within the hour. Those counts are confirmed. The per-antidote assignment lives in
Table 2 of the paper, which was not obtainable during this pass.

Assigning tiers from inference would produce a field that looks authoritative and is not. The
field is therefore present and empty, so it can be filled from the source table without a
schema change. Ann Emerg Med 2018;71(3):314–325.

## Test results

22 integration checks plus 18 parser cases plus a full JavaScript syntax check on the
109,000-character script block. One defect was caught and fixed: the embedded baseline had
not been re-injected after the schema gained `stockingTier`, so the shipped copy and the
canonical dataset had diverged. The re-injection uses index-based slicing, and the newline
integrity check from step 2 confirmed no escape corruption.


---

# Step 4 — Normalized model, expansion tranche 1, application rebuild (10 August 2026)

**Version:** 2026.08.10 · 173 toxins · 77 antidote agents · 173 protocols · 8 toxidromes · 24 categories

## Data model

The flat file was normalized into three linked tables. The links were written out explicitly,
one record at a time, rather than inferred from the agent text — a wrong link is worse than no
link, and string matching on drug names produces wrong links.

The payoff is bidirectional retrieval that the flat model could not express: hemodialysis
resolves to 16 toxins, benzodiazepines to 12, sodium bicarbonate to 11, methylene blue and
atropine to 5 each. An agent can now be opened directly to see everything it treats.

## Expansion tranche 1 — 58 new toxins

Plants and mushrooms (10), household and consumer products (11), substances of abuse (10),
drug-class gaps (9), paediatric high-lethality exposures (4), pesticides (4), marine and food
toxins (4), envenomation (3), and three others.

26 of the 58 have no antidote and were included anyway, because the clinical decision still
exists — button battery removal within two hours, Cortinarius renal failure at two to twenty
days, water hemlock status epilepticus within ninety minutes.

### Corrections found during this pass

**18. Kratom tier.** Filed as tier N, "no antidote". Naloxone gives partial and variable
reversal, so the label was inaccurate. Reclassified to tier C with the agent line corrected.
The automated check that every tier-N entry declares no antidote in its agent line is what
caught it.

**19. Duplicate category.** "Industrial & household" and "Household & consumer" overlapped to
the point of meaninglessness. Split into "Industrial & occupational" and "Household & consumer
products", with caustics and hydrocarbons moved to the consumer side where the exposures
actually occur.

## Application rebuild

Rebuilt as a five-tab application on the new model: home with search and recents, toxin
browser, agent browser, tools, and saved entries. Dark by default with a light theme for
brightly lit resuscitation bays, persisted per device.

Two design commitments were held against the reference mockup that prompted the rebuild.

**The pitfall was not moved behind a tab.** The mockup separated overview, antidote, pitfalls,
and pearls into tabs, which would have put the dose on one screen and the thing that kills on
another. Information behind a tap is not read under pressure. Dose, computed dose, and pitfall
render as one continuous screen, and a test asserts that ordering.

**No account gate.** The mockup opened with sign-in and guest options. An account means a
backend, an authentication surface, and a login wall between a clinician and a dose at three in
the morning. It also forfeits the serverless, offline-reliable, no-patient-data properties that
make the current architecture defensible.

## Defects found and fixed

**Broken deep link.** The home screen tile for cyanide referenced a toxin id without its
numeric prefix, so the tile would have opened nothing. A test that resolves every hard-coded
`data-tox` link against the toxin table now runs on every build.

**Two false failures in the test harness itself, worth recording.** An assertion sliced the
source between `function viewToxin` and `function viewAgent` to check screen ordering — but
`indexOf` matched `viewToxins` and `viewAgents`, the list views, so the assertion was
inspecting the wrong 545 characters and failing on code that was correct. Boundaries were
changed to include the parameter list. A test that fails for its own reasons is worse than no
test, because the next real failure gets assumed to be another false one.

## Test results

37 checks pass: referential integrity across the three tables, provenance coverage, newline
preservation through data injection, deep-link resolution, screen-layout guarantees, weight
engine with ceilings, storage degradation, same-origin fetch policy, update sanity gate, and
policy compliance. Full JavaScript syntax check on the 213 KB build.

## Remaining

- Expansion tranche 2 to reach 250: occupational solvents and metals, antimicrobials, remaining
  anticonvulsants, ophthalmic and dermatologic exposures, additional plants, veterinary and
  agricultural products.
- Dart stocking tier — schema field present and still empty, pending Table 2 of the source.
- Departmental toxicology review.


---

# Verification round 2 — 23 August 2026

**Reviewer:** Jae Hyek Choi, MSc, PhD, DVSc
**Scope:** every tier A and B claim read against its authority; all perishable
regulatory and supply claims re-checked; the full dataset re-run through the
integrity and browser gates.
**Result:** 8 engineering defects fixed, 8 clinical corrections applied.

## Source verification

| # | Claim checked | Source | Result |
|---|---|---|---|
| 32 | Andexanet alfa available as a factor Xa inhibitor reversal agent | FDA, Update: Safety of Andexxa, 18 Dec 2025 | **Superseded** — withdrawn from the US market 22 Dec 2025, BLA voluntarily withdrawn |
| 33 | ANNEXA-I thrombotic rate ~10% | NEJM 2024;390:1745-55 (PMID 38749032); FDA final 30-day analysis | **Corrected** — 10.3% vs 5.6% at interim; 14.6% vs 6.9% in FDA's final analysis of all 530 patients |
| 34 | Ethylene glycol hemodialysis at level >50 mg/dL | EXTRIP, Crit Care 2023;27:56 (PMID 36765419) | **Corrected** — 50 mmol/L is 310 mg/dL on an antidote; 62 mg/dL without. The old figure was a dropped unit conversion |
| 35 | Methanol hemodialysis at pH <7.3, level >50 mg/dL | EXTRIP, Crit Care Med 2015;43:461-72 (PMID 25493973) | **Corrected** — pH ≤7.15, anion gap >24, coma and seizures added, threshold split by ADH blockade |
| 36 | 4F-PCC 25–50 U/kg by INR | Kcentra prescribing information, rev. 5/2023 | **Corrected** — per-band ceilings 2500/3500/5000 U and a 100 kg dosing-weight limit added |
| 37 | Succimer is the only FDA-approved lead chelator | Chemet PI rev. 9/2024; edetate calcium disodium ANDA216435 rev. 1/2025; BAL in Oil NDA 005939 | **Corrected** — only the oral one; CaNa₂EDTA and dimercaprol carry approved lead indications |
| 38 | Chemet 10 mg/kg q8h × 5 d then q12h × 14 d, threshold 45 µg/dL | Chemet PI rev. 9/2024; AAP, updated April 2025 | **Confirmed** — with ">45" not "≥45" and an age floor of 1 year |
| 39 | Lipid emulsion for LAST is an FDA-approved antidote | Intralipid 20% PI rev. 5/2023 — parenteral nutrition indication only | **Corrected** — tier A to B; off-label, guideline-endorsed |
| 40 | ASRA LAST infusion 200–250 mL over 15–20 min | ASRA LAST Checklist 2020 v1.1 (current) | **Corrected** — ~250 mL; escalation and the ≥15 min continuation rule added; 12 mL/kg is a hard maximum |
| 41 | Salicylate hemodialysis at >90–100 mg/dL | EXTRIP, Ann Emerg Med 2015;66:165-81 (PMID 25986310) | **Confirmed, refined** — >100 (>90 with impaired kidney function); ARDS needing oxygen and failure of standard therapy stated; pH ≤7.20 added |
| 42 | Hypertonic saline as an alternative to bicarbonate in TCA toxicity | AHA 2023 focused update (PMID 37721023) — silent on it | **Corrected** — no guideline endorses it; qualified as a refractory adjunct on animal and case-report evidence |
| 43 | Totect stocked for anthracycline extravasation | Drugs@FDA NDA 022025 — Discontinued; Fed. Reg. 13 Apr 2022 | **Corrected** — brand gone; no marketed dexrazoxane carries the extravasation indication |
| 44 | Ca-DTPA / Zn-DTPA commercially available | Drugs@FDA NDA 021749 / 021751 — Discontinued; NDC inactivated; REAC/TS | **Corrected** — procurement route named (Golden State Medical Supply, 1-805-477-9866) |
| 45 | Silibinin obtainable via poison centre | ClinicalTrials.gov NCT00915681 — terminated 10 Apr 2020 | **Superseded** — no active US supply pathway; single-patient IND only |
| 46 | Physostigmine importation ended; last lot expired 31 May 2026 | FDA importation notice, current 31 Oct 2023; DailyMed Anticholium, eff. 11 Nov 2025; active NDC listing | **Corrected** — importation route remains in force |
| 47 | Glucagon emergency kits discontinued | DailyMed — Amphastar, Fresenius Kabi, Cipla, Lupin, Mylan 1 mg kits active; Gvoke VialDx IV-approved | **Corrected** — only Lilly's branded kit went, in 2022. Dasiglucagon and nasal glucagon are not usable for this indication |
| 48 | Bentracimab not FDA-approved | Drugs@FDA, DailyMed, CDER novel approvals 2025 and 2026 | **Confirmed** — last documented action is BLA acceptance 2 Aug 2024; PDUFA outcome undocumented |
| 49 | Enoxaparin protamine 1 mg/mg <8 h, 0.5 mg/mg 8–12 h, ~60% reversal | Lovenox PI rev. 12/2021; Fragmin PI rev. 12/2020 | **Confirmed, extended** — dalteparin is dosed per anti-Xa IU, not per mg |
| 50 | CroFab, Anavip, Anascorp, glucarpidase, uridine triacetate, methylene blue, pralidoxime, fomepizole, deferoxamine, DigiFab | FDA Drug Shortages (CDER data 22 Aug 2026); CBER shortage list (10 Apr 2026) | **Confirmed** — all marketed, none in shortage. ASHP is login-gated, so the negative is FDA-only |
| 51 | CDC EOC 770-488-7100 · CA IBTPP 510-231-7600 · MHAUS 800-644-9737 · Poison Help 800-222-1222 | CDC Drug Service Formulary; CDPH; MHAUS; HRSA Poison Help | **Confirmed** — all four current |

## Automated results

`tc_check.py` — 0 ERROR, 0 WARN across 11 check groups: structure, links in both
directions, tier and badge agreement, adjunct labelling, unit hygiene, render
escaping, offline integrity, version counts, review staleness, coverage.

`tc_smoke.py` — 0 ERROR, 0 WARN. Headless Chromium at 390×844, mobile and touch:
five tabs, 60 toxin cards, 12 agent cards, eight trade-name searches, the weight
calculator at 70 kg and 175 cm, touch-target sizing, console and network. The pitfall
sat below the fold on **0 of 60** cards.

The background data-refresh path was exercised over HTTP against a deliberately newer
served dataset — applied once, stored, reapplied on cold start — and against a
deliberately corrupt one, which was rejected with the embedded baseline left standing.

# Verification round 3 — 15–16 September 2026

**Reviewer:** Jae Hyek Choi, MSc, PhD, DVSc
**Scope:** coverage gaps in chemical warfare agents, smoke inhalation, envenomation and
industrial toxicology; the application rebuilt to a new interface with feature parity
proven; the service-worker release path and a field-reported phone defect.
**Result:** 13 entries added (173 → 186), 1 agent added (77 → 78), no clinical text changed
in existing entries; 6 engineering defects fixed. Published as 2026.09.16 → .b → .c.

## Source verification — new entries

Every claim below was read against the named source before the entry was written. Where a
PMID is given it was resolved on PubMed; where a label is given it was read on DailyMed or
Drugs@FDA.

| # | Entry | Tier | Authority | Result |
|---|---|---|---|---|
| 52 | Sulfur mustard — no antidote; decontamination in minutes is the only outcome-changing act | N | ATSDR MMG H/HD (rev. 25 Oct 2011); JTS CPG 69 CBRN Part 2 (25 Mar 2022); USAMRICD Handbook 4th ed.; Kehe 2009 (PMID 19482056) | **Written** — latent 4–8 h, ocular before skin, marrow nadir day 7–14 |
| 53 | Lewisite — dimercaprol for systemic arsenical toxicity only | B | BAL in Oil PI, NDA 005939 (labelling supplement 18 Mar 2026, Provepharm); ATSDR MMG L/HL; JTS CPG 69 | **Written** — the drug named British Anti-Lewisite was linked only to lead and arsenic before this round |
| 54 | Phosgene — split from chlorine; latent up to 72 h; rest; 48 h observation; no diuresis | N | ATSDR MMG Phosgene (rev. 21 Oct 2014); NIOSH ERSH-DB; JTS CPG 69; Rendell 2018 (PMID 29574134); Russell 2006 (PMID 16714497) | **Written** — NAC recorded as experimental, not recommended |
| 55 | Phosgene oxime — urticant, immediate pain, no antidote | N | ATSDR MMG CX; Goswami 2018 (PMID 29141200); Singh 2021 (PMID 33297803) | **Written** |
| 56 | Smoke inhalation — hydroxocobalamin empirically; nitrite withheld; draw COHb and lactate before the vial | B | Cyanokit PI rev. 05/2021; Nithiodote / Sodium Nitrite PI rev. 12/2024; AHA 2023 (PMID 37721023); Baud 1991 (PMID 1944484); Borron 2007 (PMID 17481777); Weaver 2000 (PMID 10713010); CDC CO guidance (rev. 21 Aug 2026) | **Written** — tier B because the smoke-inhalation use is guideline-endorsed, not a labelled indication |
| 57 | Hymenoptera anaphylaxis — IM epinephrine, anterolateral thigh, 0.01 mg/kg to 0.5 mg | A | Golden 2023 practice parameter (PMID 38108678); Shaker 2020 (PMID 32001253); WAO 2020 (PMID 33204386); Golden 2016 (PMID 28007086); neffy PI rev. 4/2026 (≥15 kg); Adrenalin PI rev. 1/2022; Simons 2001 (PMID 11692118); Pumphrey 2000 (PMID 10931122) | **Written** — antihistamines and steroids recorded as not outcome-changing; observation window stated per the 2023 parameter |
| 58 | Tick paralysis — the tick is the treatment | N | CDC MMWR 2006;55:933-7; MMWR 1996;45:325-6; Diaz 2010 (PMID 20186584); Diaz 2015 (PMID 26359765); Grattan-Smith 1997 (PMID 9397015) | **Written** — North American recovery within hours of removal; Australian *Ixodes holocyclus* may worsen for 48 h after removal |
| 59 | Aluminum / zinc phosphide — rewritten; no antidote; early VA-ECMO decision; staff off-gassing risk | N | ATSDR MMG Phosphine (rev. 21 Oct 2014); Karakaya 2025 Turk J Emerg Med 25(3):178-90; Aghebat-Bekheir 2026 (PMID 42454906); Front Cardiovasc Med 2023;10:1226827; J Cardiothorac Surg 2026 (PMID 42324466) | **Rewritten** — the earlier card omitted the ECMO conversation and the staff hazard |
| 60 | Methylene chloride — metabolised to CO; delayed COHb peak; observe | N | ATSDR MMG (rev. 12 Jan 2017); OSHA 29 CFR 1910.1052; EPA TSCA §6(a) final rule eff. 8 Jul 2024 | **Written** |
| 61 | Toluene — distal RTA, hypokalaemia; catecholamine sensitisation, beta-blocker before epinephrine | N | Batlle 1991 (PMID 1912400); Cruz 2003 Br J Pharmacol 140:653-60; Tormoehlen 2014 (PMID 24911841); ATSDR Tox Profile | **Written** |
| 62 | Nickel carbonyl — dithiocarb historical, not on any US shelf; admit all confirmed exposures | D | NIOSH Pocket Guide; Sunderman 1990 (PMID 2155573); Shi 1999 (PMID 10382560); IPCS INCHEM PIM | **Written** — tier D with the agent linked so the card states why it cannot be given |
| 63 | Sodium / potassium cyanide — hydroxocobalamin on suspicion; HCN off-gassing from vomitus and NG aspirate | A | Cyanokit PI rev. 05/2021; Nithiodote PI rev. 12/2024; CHEMM (HHS/ASPR); Hospes 2025 Toxicol Rep 15:102127 | **Written** — kept distinct from the smoke-inhalation card because nitrite is not withheld here |
| 64 | Carbon disulfide — no antidote; benzodiazepine; occupational report | N | NIOSH Pocket Guide npg 0104; OSHA PEL; EPA Hazard Summary 75-15-0; Huang 2004 Acta Neurol Taiwan 13:3-9 | **Written** |

Badge rule, restated because tier D with a linked agent is new in this round: tier D reads
**Investigational or not obtainable** regardless of links; tier N with agents reads **No
specific antidote · adjuncts only**; tier N without agents reads **Supportive care only**;
tiers A–C with agents read **Antidote available**. `hasAntidote` is true only for A–C with
agents. `tc_check.py` enforces this and treats D-with-agents as INFO, not ERROR.

## Application rebuild — feature parity

The interface was rebuilt to a four-screen design: welcome on first launch, scoped search
(All / Toxins / Antidotes / Brands / Tools), dose text rendered one row per line with →
steps kept verbatim, calculator with Antidotes / By-toxin / Custom modes, an overflow menu,
and a drawn icon set. IBM Plex Sans and Mono, light theme by default, dark by choice.

Parity was proven, not asserted. `parity.py` loads the previous build and the new one in
headless Chromium and compares what each actually produces across eight dimensions — table
counts and version; every toxin row; every protocol field the interface is responsible for
showing; every agent with its brands, class and reverse links; the toxidrome table; the
category set; search results for a battery of 20 queries; and the dose engine's output for
every dose string at 3, 70 and 120 kg — and reported identical on all eight. `dosecheck.py`
compares every dose string as rendered against the source text and found zero drift, numeric
or textual. Pitfall-below-the-fold is checked separately by `tc_smoke.py`.

## Defects found and fixed

**Releases were not reaching installed clients.** The service worker was cache-first for
the shell with a cache name that had not changed between releases, so a returning client
kept the old build indefinitely. Rewritten to stale-while-revalidate for the shell and
network-first for `data/`; `CACHE` is now bumped every release and `tc_check.py` fails the
build if it is not.

**Black, unresponsive screen on the phone.** Reported from the field on the first day of
the new interface. Two causes, one fix. The overflow menu and the welcome overlay both used
`display:flex` on their container, which overrode the `hidden` attribute, so the overlay
stayed on top of the app and took every touch. A global `[hidden]{display:none!important}`
rule now wins. Separately, the theme defaulted to the system setting, which on the reporting
phone was dark; the default is now light, with system-dark and dark available from the menu.

**Category chips regressed to 36 px.** Restored to 44 px; `tc_smoke.py` checks touch targets.

**Overflow menu opened on load.** Same `display:flex` versus `hidden` cause as above.

**Chevron overlapped tile text** on long names. Right padding added to the label.

**Tools icon read as a sun.** Redrawn as an eight-tooth cog with a hub. No functional change.

**A stray `@media print` block** inserted mid-stylesheet during a patch broke the cascade for
everything after it. Removed; brace balance is now checked after every CSS edit.

## Automated results

`tc_check.py` on the 2026.09.16.c build — 0 ERROR, 0 WARN in the dataset groups across 186
toxins, 78 agents, 186 protocols; 42 INFO, all of them tier-N adjunct and tier-D notes that
are correct by design. The remaining "offline asset" notes refer to the Google Fonts links,
which the service worker now caches on first sight and which fall back to the system stack.

`tc_smoke.py` — 0 ERROR, 0 WARN. 30 sampled cards; pitfall below the fold on **0**.

`parity.py` — identical on 8 of 8 dimensions. `dosecheck.py` — 0 of 186 dose strings drifted.

Live verification after each push: `git fetch` against the remote and an MD5 comparison of
`index.html` and `sw.js` against the local build. Commits 500dd32 → b9cf926 → 11c9aa1 →
5627490 → 1f3703c → 17622ab → 74454cb → 977cfce → c592962 → 1197b9e → 1f6a544.

## Remaining

- Expansion tranche 2 to reach 250 — occupational solvents and metals, antimicrobials,
  remaining anticonvulsants, ophthalmic and dermatologic exposures, additional plants,
  veterinary and agricultural products.
- Windows NSIS installer must be built on a Windows machine (`MAKE-INSTALLER-ON-WINDOWS.bat`);
  a portable zip is available now.
- Android AAB must be built and signed in Android Studio (`BUILD-AAB-ON-WINDOWS.md`); Play
  Console listing text, data-safety answers, icon, feature graphic and privacy policy are ready.
- Dart stocking tier — still deliberately empty.
- Departmental toxicology review.
