> 🔒 **FROZEN foundation doc.** Governed by [FOUNDATION.md](FOUNDATION.md). This is **Chapter 1**
> of [MISSION_TREE.md](MISSION_TREE.md). **80% Rule** applies.

# BizTown — Prototype Spec (v2)

Merged spec: the Mission framing, completion summit, and first design law (from the
"Save My First Shop" direction) + the margin dial, reputation-as-pricing-power model,
trait tags, and fairness guardrails (from our build-focused spec).

---

## 0. The First Design Law

> **Players should never feel they are completing levels. They should feel they are building a business.**

Everything below serves this. No "Level 1." No "Challenge complete." Just one continuous story:
a dreamer turning a tiny rented shop into a real business.

---

## 1. Purpose & success test

This prototype answers **one emotional question**:

> *Can we make someone feel like an entrepreneur in 20–30 minutes?*

**Duration:** 20–30 min. **The player should finish feeling: "I built my first successful business."**

It succeeds if the player says **"I want to continue building my business"** — *not* "I understood inventory."

Two things we watch a real player for:
1. **Margin dial** — does setting price feel like a *real decision* (do they hesitate, reconsider)?
2. **Hiring Ravi** — does it feel like a *milestone*, or just a button labeled HIRE?

---

## 2. The Mission — "Save My First Shop"

The player starts with:
- **₹10,000**
- One rented shop, one product (Soap), no employee, no experience
- A dream: build a successful shop

The whole prototype is **one mission of 5 beats**, each teaching exactly one business principle
through consequence, ending in a real summit.

---

## 3. Stats & resources (minimal)

**During play, show only two:** **Cash** and **Reputation** (0–100, starts 50).
Plus the **margin dial** (slider + live demand hint) and a visible, growing **cash reserve**.

*Turnover / disposable income are **felt** as the pile grows — never separate meters. Never an account screen.*

**On the completion screen only**, proudly show the full growth summary:
**Cash · Net Worth · Daily Customers · Employees · Reputation.** That's a "look how far you came"
moment, not a dashboard.

---

## 4. Margin / demand model

Price sets margin (**profit is never punished**). **Reputation decides how high you can price
before customers leave.** There's a profit *sweet spot* that moves right as reputation grows.

`daily_profit = demand(price, reputation) × (price − cost)`

Soap: cost **₹20**, slider **₹20–₹55**.

**Sample curve @ Reputation 50:**

| Price | ~Customers/day | Daily profit |
|---|---|---|
| ₹25 | 34 | ₹170 |
| ₹30 | 30 | ₹300 |
| **₹35** | **25** | **₹375 ← sweet spot** |
| ₹40 | 18 | ₹360 |
| ₹50 | 6 | ₹180 |

**@ Reputation 80** (premium becomes viable): sweet spot shifts to ~₹50 → ~₹600/day.

**Teaching:** there's an optimal margin; **earning reputation lets you push it higher.** Low price
= more customers + reputation (future pricing power) but thin profit now. *Exact constants = a
separate tuning pass; the shape is the intent.*

---

## 5. Challenge data schema

Every beat — now and across all future missions — is one data object:

```
Challenge = {
  id:           String
  discipline:   String        # Financial | Inventory | HR | ...
  principle:    String        # the one thing taught
  setup_text:   String        # the problem, felt — never explained
  telegraph:    String        # a hint of what's coming next (fairness)
  type:         "dial" | "choice"

  # for type == "dial":
  product:      { name, cost, price_min, price_max }
  days_to_run:  int

  # for type == "choice":
  options: [
    { text, cash_delta, rep_delta, recurring_cost, result_text, tags }
  ]

  lesson:       String        # one in-world line, shown after
  unlock:       String        # what solving it opens
}
```

---

## 6. Trait tags (record only — no engine yet)

Every choice quietly tallies traits, stored from day one so the future mirror/leadership system
has real history. **Nothing shown to the player in the prototype.**

Dimensions: `pricing` (premium/fair/value) · `risk` (bold/cautious) ·
`people` (trusting/self_reliant/pressuring) · `integrity` (honest/cuts_corners).

Stored as running tallies in `GameState.traits`.

---

## 7. The five beats (full)

### Beat 1 — Opening Day  *(dial)*
- **Financial · margin vs. demand.**
- **Setup:** Nobody knows your shop yet. Your shelf of soap is stocked. *What's your price?*
- **Play:** Drag slider; demand + projected profit update live. Lock it, run **5 days**, reserve builds.
- **Tags:** ≤₹30 → `pricing:value` (+small rep); ₹31–42 → `pricing:fair`; ≥₹43 → `pricing:premium`.
- **Telegraph:** *"Word is spreading — more customers this week."*
- **Lesson:** *"Price too high, customers leave. Too low, you work for free. Profit lives in the middle."*

### Beat 2 — Running Out of Stock  *(choice)*
- **Inventory · read demand; overstock freezes cash, understock loses sales.**
- **Setup:** Soap is nearly gone and customers keep asking. Supplier offers a bulk discount.

| Option | Cash | Rep | Result | Tags |
|---|---|---|---|---|
| Small order (safe) | −400 | 0 | Safe, but you sell out again and miss sales. | `risk:cautious` |
| Large order (bulk) | −1200 | +5 | Full shelves, happy customers — cash tied up in stock. | `risk:bold` |
| Emergency buy (small, fast) | −600 | +2 | Stays open now, but you pay a premium for speed. | `risk:cautious` |

- **Telegraph:** *"The queue at your counter grows longer every day."*
- **Lesson:** *"Empty shelves lose customers. Too much stock locks your cash. Order to match demand."*

### Beat 3 — The Long Queue → Hire Ravi  *(choice + micro-moment)* — **centerpiece**
- **HR · you can't grow past your own two hands; delegation = letting go.**
- **Micro-moment:** a queue builds; player taps to serve, **can't keep up**, some customers leave
  (visible lost sales, small rep dip). Then **Ravi**, nervous, appears: *"Sir… do you need help?"*

| Option | Cash | Rep | Recurring | Result | Tags |
|---|---|---|---|---|---|
| **Hire Ravi** | 0 | +15 | −150/day | Queue clears. You watch Ravi handle a sale *you* used to handle. | `people:trusting` |
| Raise prices to thin the crowd | +300 | −15 | 0 | Fewer customers, you cope alone — growth stalls. | `people:self_reliant`,`pricing:premium` |
| Push through alone | 0 | −10 | 0 | No cost today, but the queue keeps breaking. Unsustainable. | `people:self_reliant` |

- **Consequence (if hired):** Ravi serves his first customer. *"Thank you for the chance, boss.
  I won't let you down."* Queue clears, rep recovers; you now carry a daily wage. **First "it ran
  without me" beat.** Capacity rises → more customers/day from here on. (Seeds the future mirror.)
- **Lesson:** *"You can only grow as far as your own two hands — until you trust someone else's."*

### Beat 4 — Month-End  *(choice)* — **tests the reserve**
- **Financial · cash flow ≠ profit.**
- **Setup:** First month closes. **Rent ₹3,000** and **Ravi's wages** are due. *Can you cover it?*
- This is where margin discipline pays off. If the reserve covers it → relief + pride. If short →
  the **fallback path** (see guardrails), not game-over.

| Option | Cash | Rep | Result | Tags |
|---|---|---|---|---|
| Pay everything on time | −(rent+wages) | +10 | Bills cleared. You feel the cost of running a business — and that you made it. | `integrity:honest` |
| Take a small loan to cover the gap | +gap, then −repay later | 0 | You survive, but a debt now hangs over you. | `risk:bold` |
| Delay the supplier payment | 0 now | −10 | You stall — but trust with your supplier takes a hit. | `integrity:cuts_corners` |

- **Telegraph:** *"The shop next door just went up for rent…"*
- **Lesson:** *"Profit on paper isn't money in hand. Cash flow keeps the doors open."*

### Beat 5 — Expansion → Mission Complete  *(choice → summit)*
- **Strategy · invest to grow.**
- **Setup:** The shop next door is available. Doubling your space needs a big investment (~₹8,000).

| Option | Result | Tags |
|---|---|---|
| Expand now | Shop doubles — customers and capacity grow. Mission complete. | `risk:bold` |
| Stay small for now | A safe, proud first shop — mission complete, smaller summit. | `risk:cautious` |

- **Completion screen:** *"Congratulations — you built your first successful business."* Show the
  growth summary (Cash · Net Worth · Daily Customers · Employees · Reputation) + one **mirror line**
  reading the trait tallies (e.g. *"You priced fair and trusted people — a builder's instinct."*)
  + the hook: **Next Mission → Become a Wholesaler.**

---

## 8. Core loop

```
Receive mission ("Save My First Shop")
  → Beat 1: set margin → run days → reserve builds
  → Beat 2: stock-out decision → spends reserve
  → Beat 3: queue you can't handle → hire Ravi (the handoff)
  → Beat 4: month-end bills → reserve tested
  → Beat 5: expand → COMPLETION SCREEN + next-mission hook
```

Each beat: **setup (felt) → decision → consequence (Cash/Rep move) → lesson → growth.**

---

## 9. Data structures (for build later)

**`GameState` (autoload):**
```
cash: int = 10000
reputation: int = 50
day: int = 0
beat: int = 0
has_employee: bool = false
daily_costs: int = 0          # Ravi's wage once hired
customers_per_day: int = 0    # rises after hiring / expansion
traits: Dictionary = { pricing:{}, risk:{}, people:{}, integrity:{} }
```

**Challenges:** array of `Challenge` objects (§5) — start as a GDScript array of dictionaries,
upgrade to `.tres` Resources later.

**Scenes:** `Main.tscn` (shop view + HUD, reuse existing iso building) · `ChallengeCard.tscn`
(setup + options/dial, emits `choice_made`) · `ResultPanel.tscn` (consequence + lesson) ·
`CompletionScreen.tscn` (summit summary + mirror + next-mission hook). Signal-driven.

---

## 10. Guardrails (non-negotiable)

1. **Never feel like levels — always feel like building a business.** (The First Design Law.)
2. **Telegraph what's coming** — every beat hints at the next, so saving is informed, never a gotcha.
3. **No hard game-over** — broke at Month-End = a harder path (loan / delay), never death.
   The fragility *is* the lesson.
4. **One dial, one pile, two stats** during play — never a ledger.
5. **One principle per beat**, taught through consequence, never a lecture.
6. **Reputation rewards value, never punishes profit.**
7. **No business jargon, no spreadsheets** — everything learned through play.

---

## 11. Explicitly NOT in the prototype

Factories · manufacturing · branding · marketing campaigns · multiple cities · logistics ·
the Competitor challenge (deferred to v2) · taxes · share market · multiple businesses ·
advanced HR · trait/leadership *engine* (tags are stored but not yet acted on) · save system ·
art/sound polish · monetization. **Anything beyond one successful shop.**
