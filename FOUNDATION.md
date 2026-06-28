# BizTown — Foundation (FROZEN)

> 🔒 **FROZEN as of 2026-06-20.** This document and the foundation it governs do not change again
> *unless real playtesting reveals a genuine weakness.* No more vision rewrites. We build now.

---

## The Capstone (the soul of the whole thing)

> **BizTown is not about becoming rich. It is about becoming capable.**
> Money, buildings, factories, brands — all of it is *evidence* of capability. Capability is the
> real progression. (Full vision: [WHY_BIZTOWN.md](WHY_BIZTOWN.md).)

---

## The 80% Rule (the master filter — read first)

> **If a feature does not make the player better at building a business or thinking like an
> entrepreneur, it does not belong in BizTown.**

Apply it to every future suggestion. Fishing, dating, pets, decorating, combat, cooking, fashion —
*does it help build businesses or entrepreneurial thinking?* If no, don't build it. This rule saves years.

---

## The Four Pillars

1. **Business Growth** — the player builds an empire. *The visible progression.*
2. **Business Knowledge** — the player learns business concepts, never by lecture, always by challenge.
3. **Entrepreneur Growth** — the player gradually changes how they think, because the game *rewards*
   good entrepreneurial thinking (not because it tells them to).
4. **Identity** — the player starts a **Dreamer** and becomes an **Empire Builder**. *The emotional journey.*

---

## The Design Laws

1. **First Design Law** — players must never feel they are *completing levels*; they must feel they
   are *building a business.* One continuous journey.
2. **Learn by consequence, never by lecture** — no jargon, no spreadsheets, no accounting screens.
   One business principle per mission, taught through felt outcomes.
3. **Dual Growth Law** — every mission teaches **one business concept AND strengthens one
   entrepreneurial mindset.** The mindset is earned through the choice's risk/reward — **never labeled**
   ("Mindset: Courage +1" is banned).
4. **One-Question Law** — every mission is built around **one meaningful entrepreneurial question**
   (e.g. *"Can you trust your first employee?"*). If a mission has no clear question, it isn't ready.
5. **Reputation rewards value, never punishes profit** — premium pricing is good once earned.
6. **Fairness** — telegraph what's coming; **no hard game-over** (broke = a harder path, never death);
   two stats + one dial during play, never a ledger.
7. **Stable spine, evolving surface** — one core verb (allocate scarce resources under uncertainty),
   transformation by accumulation not replacement (no Spore trap). Keep it **intimate** — a founder's
   rise, not a detached "civilization."
8. **The BizTown Triangle** — every mission must be **Fun** (someone would play it even if they learned
   nothing) AND **Valuable** (teaches a principle a real entrepreneur would actually use — not trivia,
   not common sense) AND **Meaningful** (the player *cares*; it carries emotional weight). All three are
   mandatory; **none outranks the others.** If one is missing, cut the mission.
9. **Mirror Principle** — the game reflects the player's *own* journey back to them (their decisions,
   consequences, and the story they made), never as a grade.
10. **Coffee Shop Test** — every mission must be explainable as a one-sentence *story worth telling*
    ("I almost ran out of money because I bought too much stock"), never "I completed Mission 14."
    If it can't become a story, it won't become a memory.
11. **New decision per chapter** — each chapter introduces **one new entrepreneurial decision that
    builds on the same core loop** — never just a bigger number.

---

## What BizTown will NOT add

Not because they're bad — because they don't strengthen the core:

> bolt-on AI chatbot mentors · NFTs · multiplayer · open world · VR · crypto · hundreds of side
> systems · fishing · decorating · dating · pets · fashion · cooking · combat.

The core is strong. Protect it.

---

## Long-term direction (post-V1 — NOT a current build path)

**AI as Dungeon Master.** Once 50–100 *handcrafted* scenarios define the quality bar, AI may
generate **personalized situations** — events, dilemmas, customers, suppliers, competitors, and the
*consequences of the player's own history*. But AI **never** touches the rules, economy, or scoring;
those stay deterministic in the Simulation Engine. **AI personalizes the world, never the mathematics.**
This is the deliberate exception to the "AI mentors" line above (which bans bolt-on chatbots, not this).
V2+. Handcrafted Chapters 1–2 come first — they teach us what a great entrepreneurial challenge *is*.

---

## The foundation documents (also frozen)

- **`FOUNDATION.md`** — this charter (pillars + laws + filters).
- **`KNOWLEDGE_MAP.md`** — the Entrepreneur Framework (business skills + mindset curriculum).
- **`PROTOTYPE_SPEC.md`** — the playable "Save My First Shop" prototype (= Chapter 1).

## Design phase complete — now we engineer

The single filter from here on:

> **Does this make Chapter 1 more fun?** Yes → build it. No → don't.

**Roadmap:** Foundation ✅ → Business Simulation Engine → Game Architecture → Godot Prototype →
Internal Playtest → Iteration → Public Playtest → Build Chapter 2.

**Build order (one complete Chapter, no more):**

- **Sprint 1 — Business Simulation Engine:** cash · demand · pricing · inventory · reputation ·
  customer flow. *Built for Chapter 1's retail shop, but cleanly abstracted so it can LATER be
  reconfigured for restaurants, manufacturing, farming, services. We do **not** build that generality
  now — design for extension, build for Chapter 1 (no gold-plating before playtest).*
- **Sprint 2 — Mission Engine:** challenge → decision → consequence → reward.
- **Sprint 3 — World Engine:** shop · customers · Ravi · animations · UI.
- **Sprint 4 — Playtest Build:** one complete Chapter 1. No more.
