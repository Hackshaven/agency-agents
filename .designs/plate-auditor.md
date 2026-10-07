# Design: Plate Auditor

Attribution: Eric Hackathorn. Probably a personal contribution rather than a NOAA one, since it isn't mission work; settle that before upstreaming. Branch `claude/confident-mendel-lm2275`.

**Status:** Proposal only; no agent file yet. This doc proposes the workflow, the checks, the logging path, and a test plan, and ends with the decisions to make before the build.

- **Track and home:** Upstream. Proposed file `healthcare/healthcare-plate-auditor.md`; skill name `agency-plate-auditor`. It fits `healthcare/` because what it produces is a health record. The other choice is `specialized/`, next to the Aging Parent Care Companion, where the catalog's other consumer-facing health agents live.
- **Name:** "Plate Auditor" (working title). The job isn't really counting calories. It's never logging a number it can't defend, so the name leads with the checking.
  - **Alternatives:** "Meal Logger" is plain and accurate, but it hides the checking. "Plate Reader" names the photo step and nothing after it. Avoid "Nutritionist" and "Dietitian": both suggest a credential, and dietitian is a licensed title in most US states.
- **Who uses it:** People who log food to manage weight, training, or a health condition; athletes tracking protein; people counting carbohydrates for diabetes (high stakes, see Rule 9); caregivers logging meals for someone else; and dietary-intake researchers who want something less burdensome than a 24-hour recall. Eric's own use is the request that started it. Broad audience; not mostly Eric.
- **Can Eric validate it himself:** Yes, with a kitchen scale. Ground truth is cheap at home: weigh each component before plating and weigh the leftovers after. A script, not the agent, turns the weights into nutrient totals from USDA data. See the test plan.
- **Closest catalog agents** (checked 2026-10-07 against the 294 agents on `hackshaven`; open upstream PRs not checked, because this session can't reach `msitarzewski/agency-agents`): no agent in the catalog estimates food or logs nutrition. A search for meal, nutrition, and calorie turns up only passing mentions, such as a "Nutrition" tab in an example for the Filament Optimization Specialist and meal service in Hospitality Guest Services.
  - **Requirements Interviewer** (`product/`) supplies the interview discipline: every question earns its place, one question per turn (its Rules 3 and 4). Here a question earns its place by how many calories its answer could move. The jobs are different.
  - **Healthcare Clinical Evidence Agent** (`healthcare/`) answers clinical evidence questions. It's where to send "is this diet advice right?", and it doesn't log anything.
  - **Mobile App Builder** and **AI Engineer** (`engineering/`) would build the harness: the Shortcut or iOS app and the pipeline. They're not the agent.
- **Origins:** Eric's request, 2026-10-07: "an agent that can take a photo of a meal and analyze it for nutritional value, caloric content, macronutrients, etc. … accept voice or text input and interview the user with additional questions as necessary … a workflow to minimize error, double check values for accuracy and ultimately be able to log this information somewhere like Apple Health." The sources that shaped the design:
  - **Photos alone are off by about a third.** [Fridolfsson et al., 2025, *Current Developments in Nutrition* 9(10):107556](https://pmc.ncbi.nlm.nih.gov/articles/PMC12513282/) photographed weighed meals and compared three models with values from a nutrient database. GPT-4o and Claude 3.5 Sonnet each had 35.8% MAPE for energy and 36.3% and 37.3% for weight. Macronutrient errors were worse: carbohydrates 47.9–72.8%, protein 60.7–61.7%, fat 41.7–51.8%. "All models exhibited systematic underestimation that increased with portion size," partly because vegetables in front hid the starch and protein. These are 2024 models, so the test plan runs its own baseline. Takeaways: never log a photo-only point value, always show a range, and lean the range upward on big plates.
  - **Weight beats pixels.** A Virginia Tech master's thesis ([Bhatambarekar, 2025](https://vtechworks.lib.vt.edu/items/b67c2a61-f283-41ba-9602-9798306b9529); abstract only read) tested eight models on Nutrition5k and MetaFood3D. Calorie error fell "from approximately 51% in the image-only setting" to "as low as 29%" with per-ingredient mass. "Providing just the total mass reduces calorie prediction error across all models, making it the single most impactful cue." A second view helped "3-7 percentage points." A self-questioning workflow beat a fixed prompt by more than 8 points. And "errors persist in estimating invisible elements such as oils and dressings." Takeaways: ask for a weight when one exists, make a second angle optional, and point the first questions at hidden fats.
  - **Context helps.** [Coburn et al., 2025, arXiv:2507.07048](https://arxiv.org/abs/2507.07048) (abstract only) found that venue type, meal time, and the list of foods present "can significantly reduce" both MAE and MAPE. So the agent asks where and when first, and prefers a restaurant's published nutrition to its own estimate.
  - **Geometry is the upgrade path.** In a 2026 preprint, [Liao & Li, arXiv:2607.16514](https://arxiv.org/abs/2607.16514) (abstract only, not peer reviewed), a portion head on a frozen vision backbone "cuts per-food portion error by 33-41% relative to the MLLM alone," with no depth sensor. That's for a later version, not v1.
  - **Even labels aren't exact.** FDA rules at 21 CFR 101.9(g)(5) let calories, sugars, total fat, saturated fat, and sodium run up to 20% above the declared value. Every source carries uncertainty, so ranges go all the way down.
  - **Apple Health still has no food logging of its own.** Apple's AI health service was "scrapped well before the iOS 27 beta came out." iOS 27's Visual Intelligence food reading "does not give exact calorie counts," and its "Data does not sync to the Health app" ([MacRumors iOS 27 Health guide](https://www.macrumors.com/guide/ios-27-health-app/), read 2026-10-07). Some third-party coverage says iOS 27 can scan nutrition labels into Health; MacRumors doesn't mention it, so check on a device before counting on it. Getting meals into Health still means HealthKit, written from a third-party app or from Shortcuts.
- **Assumptions made without asking:**
  - The persona and the harness are separate. The catalog's External Services rule says an agent has to stand on its own, so the agent's output is a checked meal record. Writing that record to Health is the harness's job: a Shortcut or a small app. With no tools at all, the agent still runs the interview and shows its arithmetic, and labels every number "no database: unverified."
  - The v1 nutrients are energy, protein, carbohydrate, fat, fiber, sugar, and sodium. Micronutrients get logged only when the source is a label, a barcode, a restaurant's published values, or a weighed recipe, never from a photo estimate.
  - Health gets the likely value. The range, sources, and confidence go in metadata and in the agent's own log, because Health has nowhere to show a range.
  - It's one agent with a blind second-opinion pass, not a team. One conversation, one record.
  - Not medical advice, and no dosing (Rule 9).
  - Services: USDA FoodData Central (free API key) and Open Food Facts (open barcode database).
  - The name, the division, color `#9A3412` (unused on `hackshaven`; a terracotta plate), and emoji 🍽️ (unused).

---

# Proposed Workflow

## Where the error comes from

Most of the work goes where most of the error is.

| Source | How big | What reduces it |
|---|---|---|
| **Portion size** | The biggest source: about 36% on its own, and growing with portion size (Fridolfsson) | A weight from the user; a reference object in the frame (fork, card, hand); a second angle; a question |
| **Hidden ingredients**: cooking oil, butter, dressing, sugar in drinks, sauces | 1 tbsp of oil is about 120 kcal; a meal can hide 300 or more | Questions; these are the first ones asked |
| **Identity of look-alikes**: diet or regular soda, whole or skim milk, fried or grilled | 0 vs. about 140 kcal for a 12 oz soda | A question, but only when the variants differ materially |
| **Database match**: raw vs. cooked, generic vs. brand | Cooked white rice is about 130 kcal/100 g and raw about 365; mixing them up is a 2.8× error | Matching cooked to cooked; an energy-density check |
| **Arithmetic and units**: oz vs. g, cups, "a serving," kJ vs. kcal | Unbounded | Code does all the math; the model never does |
| **What was actually eaten**: leftovers, shared plates | Up to 100% | One question, or an "after" photo |
| **Logging**: duplicates, wrong time, double counting from other apps | A whole meal | Idempotent writes and a duplicate check |
| **The floor**: label tolerance, natural variation | ±10–20% | Nothing removes it, so the record shows ranges |

## Rules

1. **The model looks; code counts.** The model identifies foods, estimates portions, picks database matches, and runs the conversation. Every nutrient number comes from a database value times grams, computed in code. A number the model "knows" from memory is a last resort, labeled `model estimate, unverified`.
2. **Every number has a range and a source.** Each item carries low, likely, and high grams, and a source ID (an FDC ID, a barcode, a restaurant item, a user recipe, or the model). Totals carry ranges too. Never show false precision: "about 820 kcal (680–970)," never "823 kcal."
3. **Best evidence wins.** In order: a weight from the user → a package label or barcode → a restaurant's published nutrition → the user's saved recipe or usual meal → a generic USDA entry → a model estimate. Better evidence for an item replaces the estimate for that item; it isn't averaged with it.
4. **A question earns its place by the calories it can move.** Rank every unknown by its swing (the high value minus the low). Ask about the biggest swing first, one question per turn, as a choice that can be answered in a word, with "not sure" always allowed. Recompute after every answer, because one answer can make the next question unnecessary. Don't ask what the photo or the user's words already settle, and don't ask about swings under about 50 kcal or 10% of the meal. Stop at three questions, when the range is inside the target, or when the user says "just log it." Whatever is left unasked shows up as range width, not as a guess.
5. **Two independent estimates before one log.** A blind second pass estimates the meal without seeing the first pass's answer (Check V7). When the two disagree, the agent finds the item behind the disagreement and either asks about it or widens the range. It never quietly averages the two.
6. **Checks are a gate.** A record with a failed check isn't offered for logging until the failure is fixed or explained to the user in a line.
7. **Nothing is logged without a yes, and anything logged can be undone.** The user sees the summary card and confirms it. Every write carries the meal's ID, so an edit replaces the old entry instead of adding a second one.
8. **Keep the evidence.** Keep the photos (with location data stripped), the transcript, every intermediate value, and the final record, so a meal can be recomputed when a database entry improves or the user corrects something a week later.
9. **Not medical advice, and no dosing.** For anyone counting carbohydrates for insulin, the agent shows the carb range plainly, never suggests a dose, and says that photo-based carb estimates (47.9–72.8% MAPE in Fridolfsson) aren't accurate enough to dose from. It never says a meal is free of an allergen based on a photo.
10. **Neutral about food.** No "good," "bad," "cheat," or "guilt-free." Never set a target or a deficit the user didn't ask for. A numbers-off mode logs the meal without showing totals. If someone describes restriction, purging, or distress, the agent sets the numbers aside and suggests professional support.
11. **Private by default.** Read the capture time from the photo's metadata, then strip GPS and other metadata before anything leaves the phone. Crop or blur other people in the frame. Keep photos only as long as the user chooses. Apple's App Review Guidelines (5.1.3) bar using HealthKit data for advertising, and in the US the FTC's Health Breach Notification Rule covers health apps.

## The flow

```text
 0 CAPTURE      photo(s) + voice or text ("dinner at home", "Chipotle, ate about 3/4")
     │          prompts: top-down + 45°, fork or card in frame; label/barcode/menu if any
 1 CONTEXT      when (photo timestamp) · where (home / restaurant / packaged) · whose plate
     │          taken from the user's words first; asked only if missing and it matters
 2 LOOK         vision pass A ─► items[]: name, visible prep, grams {low, likely, high},
     │          how much is hidden, top-3 database candidates, confidence, "can't see" flags
 3 RESOLVE      lookup tool ─► best source per item (Rule 3); raw/cooked state matched
 4 COMPUTE      code ─► nutrients per item and totals, each low/likely/high; swing per unknown
 5 TRIAGE       rank unknowns by swing ─► at most 3 questions, biggest first   (Rule 4)
 6 INTERVIEW    one question per turn ─► recompute ─► re-rank ─► stop rule
     │                    ▲                                 │
     │                    └──────── loop ───────────────────┘
 7 CHECK        V1–V11 (below) ─► fix, ask, or widen; a failure blocks step 8
 8 CONFIRM      summary card: items, grams, kcal, macros, range, sources, assumptions
     │          "Log it / Edit / Cancel"; edits by voice ("the rice was more like a cup")
 9 LOG          canonical log first (meal_id) ─► Apple Health / Health Connect / sheet
10 LEARN        corrections and weighed meals ─► personal portion calibration, saved meals
```

### A worked example

Photo: spaghetti with red sauce, a side salad with dressing, and a glass of dark soda. Voice: "Dinner. Made it at home." (All numbers approximate.)

| Unknown | Range | Swing | Asked? |
|---|---|---|---|
| Pasta amount | 180–320 g cooked | ~220 kcal | **Q1:** "Do you know how much dry pasta went in, like half a box for two?" "Half a one-pound box, two of us." That's 113 g dry, about 420 kcal. Dry weight converts exactly, which is the "total mass" cue at work. |
| Soda | diet or regular | ~140 kcal | **Q2:** "Diet or regular?" "Regular." |
| Dressing | none to 2 tbsp | ~140 kcal | **Q3:** "Dressing: none, a drizzle, or a pour?" "A drizzle." That's about 1 tbsp. |
| Oil in the sauce | 0–1 tbsp | ~120 kcal | Not asked; the three-question budget is spent. Stays in the range. |
| Parmesan | 5–15 g | ~40 kcal | Below the threshold |
| Lettuce variety | — | <10 kcal | Never |

The total goes from about 370–1,090 kcal before the questions to about 680–970 after (likely about 820). The card says the oil in the sauce was assumed, not asked.

## The checks

| # | Check | Catches | Passes when | On failure |
|---|---|---|---|---|
| V1 | **Recompute** totals from the line items, independently | Arithmetic slips | Exact match | Bug; block |
| V2 | **Energy vs. macros**: kcal ≈ 4·protein + 4·carbs + 9·fat + 7·alcohol | Wrong entry, wrong units, a dropped macro | Within ±15% (tune on test data; databases use food-specific factors and handle fiber differently) | Re-resolve the item that's off |
| V3 | **Mass balance**: protein + carbs + fat + fiber ≤ the item's grams | Unit mix-ups, per-serving vs. per-100 g | Always | Re-resolve |
| V4 | **Energy density by food class** (kcal/100 g): greens 10–30; cooked grains and pasta 100–180; cooked lean meat or fish 100–250; cheese 250–450; nuts 550–700; oils about 880 | Raw/cooked swaps, a wrong match | Inside the class band | Re-resolve; ask if still out |
| V5 | **State and units**: cooked food matched to a cooked entry; every "serving," "cup," or "piece" turned into grams with a stated conversion | The 2.8× rice error | Always | Fix the match |
| V6 | **Portion plausibility**: grams vs. plate size and the reference object; vs. typical serving weights (FNDDS portion weights) | Wild portion guesses | Inside the typical range, or the user confirmed it | Ask; on a large plate, widen the range upward and never narrow it (the underestimation finding) |
| V7 | **Blind second estimate**: a fresh-context pass gets only the photos and the user's own words, and returns its own items and total range | Anchoring and one-pass blind spots | Likely values within 25% and ranges overlap | Compare the two item lists, find the item behind the gap, then ask about it or widen and label low confidence |
| V8 | **Source cross-check**: label photo vs. barcode database; restaurant's posted values vs. what's on the plate (size, sides) | A database entry for the wrong size or recipe | Agree within label tolerance | Prefer the label; ask about size |
| V9 | **History**: vs. this user's past logs of the same meal and their usual daily pattern | Unit errors that pass every other check | Within the user's normal range | Confirm: "This is about twice your usual breakfast. Right?" |
| V10 | **Duplicate**: same photo hash, or a similar meal within 30 minutes; other apps writing the same meal to Health | Double logging | No match | Ask before writing |
| V11 | **Range honesty**, measured over time: how often the truth (weighed meals) lands inside the stated range | Ranges that are too narrow or too wide to be useful | 75–85% for an 80% range | Recalibrate how ranges are built |

V7 has limits. A second pass that uses the same model shares that model's blind spots, including the systematic underestimation of big portions. A different model family lowers the overlap. Either way, the second opinion catches anchoring and careless matches; it doesn't replace a weight or a good question.

## The meal record

The agent's real output is the record. Logging is a projection of it.

```json
{
  "meal_id": "2026-10-07T18:42-7f3a",
  "eaten_at": "2026-10-07T18:42:00-06:00",
  "meal_type": "dinner",
  "context": { "where": "home", "who": "self", "fraction_eaten": 1.0 },
  "items": [
    {
      "name": "spaghetti, cooked",
      "grams": { "low": 255, "likely": 265, "high": 280 },
      "basis": "user: 1/2 lb box dry, split 2 ways -> 113 g dry",
      "source": { "type": "usda_fdc", "id": "<fdc id>", "state": "cooked" },
      "confidence": "high"
    },
    {
      "name": "cola, regular",
      "grams": { "low": 370, "likely": 370, "high": 370 },
      "basis": "user: regular; glass ~12 fl oz",
      "source": { "type": "usda_fdc", "id": "<fdc id>" },
      "confidence": "medium"
    }
  ],
  "totals": {
    "energy_kcal":  { "low": 680, "likely": 820, "high": 970 },
    "protein_g":    { "low": 19,  "likely": 22,  "high": 26 },
    "carbs_g":      { "low": 125, "likely": 135, "high": 145 },
    "fat_g":        { "low": 12,  "likely": 19,  "high": 27 }
  },
  "assumptions": ["olive oil in sauce 0-1 tbsp (not asked)"],
  "questions": [
    { "id": "Q1", "text": "How much dry pasta?", "swing_kcal": 220, "answer": "half a 1 lb box, two people" },
    { "id": "Q2", "text": "Diet or regular?",   "swing_kcal": 140, "answer": "regular" },
    { "id": "Q3", "text": "Dressing amount?",   "swing_kcal": 140, "answer": "a drizzle" }
  ],
  "checks": [ { "id": "V2", "status": "pass", "detail": "4P+4C+9F = 799 kcal, 2.6% off" } ],
  "second_opinion": { "energy_kcal": { "low": 650, "likely": 760, "high": 900 }, "agrees": true },
  "confirmed_by_user": "2026-10-07T18:44:10-06:00",
  "logged_to": [ { "target": "apple_health", "sync_identifier": "2026-10-07T18:42-7f3a", "version": 1 } ]
}
```

## Logging

**Canonical log first, then sinks.** The record goes to the agent's own store (a JSON-lines file, SQLite, or a Google Sheet), and every other destination is written from it. That's what makes edits, recomputation, and moving to another app possible.

**Apple Health.** HealthKit data lives on the phone, and there's no server-side write API. A backend can run the agent, but the phone does the write. Two ways to get there:

| | **A. Shortcuts (MVP)** | **B. Small iOS app** |
|---|---|---|
| Flow | Take Photo → Dictate Text → Get Contents of URL (agent backend) → loop: Ask for Input / Dictate → Get Contents of URL → Show Result (card) → Choose from Menu (Log / Edit / Cancel) → Log Health Sample for each nutrient | SwiftUI + camera + Speech + HealthKit; an App Intent "Log a meal" for Siri and Shortcuts |
| Health write | One sample per nutrient (Dietary Energy, Protein, Carbohydrates, Total Fat, Fiber, Sugar, Sodium) | One `HKCorrelation` of type `.food` holding the nutrient samples, with `HKMetadataKeyFoodType` (the meal's name), `HKMetadataKeySyncIdentifier` = `meal_id`, and `HKMetadataKeySyncVersion`. Saving version 2 replaces version 1. Custom keys hold the range, confidence, and source. |
| Edits | Delete samples by hand in Health; no meal ID to tie them together | Automatic and idempotent |
| Effort | An afternoon | Days to weeks, plus a developer account |
| Later | — | LiDAR depth on Pro iPhones for portion volume; on-device photo pre-processing |

**Android:** Health Connect's `NutritionRecord` fits better than HealthKit. One record per meal holds energy, macros, micronutrients, `mealType`, and `name`.

**Elsewhere:** A Google Sheet works as the MVP's canonical log and makes review and analysis easy. FHIR `NutritionIntake` (R5) is there if the data ever has to reach a clinical system. Most consumer diet apps don't offer an open write API, so confirm one exists before planning on it.

**Units:** energy in kcal (`HKUnit.kilocalorie()`), macros in grams, sodium in milligrams. V3 and V5 guard the conversions.

## Voice

- Transcribe on the device (Dictation in Shortcuts, or the Speech framework in an app).
- Read back every number and unit before using it: "I heard fifteen grams of almonds. Right?" Speech recognition confuses fifteen and fifty, and ounces and grams.
- Questions have to work by ear: short, with the choices in the question ("Diet or regular?").
- Spoken edits after the card ("make the rice a cup") go back through steps 3–7, not straight to the log.

## Learning

- **Saved meals:** after the third time, "the usual oatmeal" becomes a one-tap template, with its source marked as the user's recipe.
- **Personal calibration:** the user's corrections and occasional weighed meals produce a per-user, per-food-class portion factor (for example, rice portions run 1.3× the model's estimate). It's applied visibly ("adjusted using your past corrections"), never silently, and only after about five data points.
- **Places:** a restaurant the user visits often gets its menu's published values cached.

## Test plan

1. **Kit:** 25 home meals with every component weighed before plating and leftovers weighed after, each photographed top-down and at 45° with a fork in frame; 5 packaged items with their labels; 5 restaurant items with published nutrition. A script computes ground truth from FDC entries, so the agent never grades itself. A Nutrition5k subset serves as an outside benchmark.
2. **Traps:** diet vs. regular soda in the same glass; fried rice (oil you can't see); "100 grams of rice" said by someone who weighed it dry; a half-eaten plate; a shared plate with two forks; a packaged item whose label disagrees with the generic database entry; a menu photo whose posted calories are for a smaller size than the one served; "fifteen" vs. "fifty" grams of almonds by voice; the same photo sent twice; a photo that isn't food; a photo with GPS metadata and a stranger's face in the background; a user who says they'll dose insulin from the carb count.
3. **Baseline:** a plain model with the same photos and words, asked "How many calories and macros?" The agent has to beat it on MAPE and on range honesty while averaging three or fewer questions a meal.
4. **Score:** meal energy MAPE (proposed target: median under 20%, against about 36% for photo-only in Fridolfsson); how often the truth lands in the stated range (75–85%), plus average range width; macro MAPE; questions per meal and calories moved per question; arithmetic errors (target 0); logs without confirmation (target 0); duplicate writes (target 0); traps handled.

## Decisions for Eric

1. **Harness:** Shortcuts first (recommended: it gets the accuracy test running this week), or straight to a small iOS app?
2. **Canonical log:** a Google Sheet, a local file, or Health only? I recommend a Sheet or a JSON file plus Health; Health alone can't hold ranges, sources, or photos.
3. **Accuracy target and question budget:** ±20% and three questions are proposals, not requirements.
4. **Nutrients:** the v1 list above, or more?
5. **Second opinion:** the same model with a fresh context (cheaper), or a different model family (fewer shared blind spots)?
6. **Division and attribution:** `healthcare/` or `specialized/`; personal or NOAA.

## At build time

Recheck open upstream PRs for overlap. Write the agent file from the rules above (persona, interview, checks, record format, handoffs) with `services` frontmatter for FoodData Central and Open Food Facts. Run lint, the originality check, the converter, and the skill build. Then run the test loop. Before writing the Shortcut, confirm on a device which nutrient types Log Health Sample offers and whether iOS 27's label scanning writes to Health.

- **Proposed frontmatter:**
  - color `#9A3412`
  - emoji 🍽️
  - vibe "Asks what the camera can't see, and logs only numbers it can defend."
  - description "Meal nutrition auditor that turns a photo and a few spoken or typed answers into a checked log entry: identifies each food, estimates portions with ranges, asks only the questions that move the numbers, takes nutrient values from food databases rather than memory, runs arithmetic and plausibility checks plus a blind second estimate, and logs to Apple Health or another store only after the user confirms."
- **Revisions:** none yet.
