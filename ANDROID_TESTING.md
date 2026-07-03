# Developing & testing BizTown from an Android phone

BizTown's development loop runs entirely phone + cloud — no desktop needed:

> Claude Code (cloud) writes code and pushes to GitHub → you pull/open the
> project on your phone → you run the tests and play the game → you send back
> screenshots or notes → Claude fixes and pushes again.

Your phone is the runtime and the playtest device. Since BizTown is
Android-first anyway, this is testing on the real target.

## One-time setup

1. Install the official **Godot Engine editor for Android** from the Play
   Store (published by Godot Engine — pick the standard 4.x editor, *not*
   the .NET one).
2. Get the project onto the phone. Either:
   - **ZIP (simplest):** on GitHub, open the branch (e.g.
     `claude/new-session-alp84t`) → the green **Code** button → **Download
     ZIP** → unzip into a folder like `Documents/townbiz` with your Files app.
     Re-download whenever Claude pushes an update.
   - **Git app (better for repeated updates):** install a Git client (MGit,
     or Termux with `git`), clone
     `https://github.com/vikashamitian-claude/townbiz.git`, check out the
     working branch. Then each update is just a `pull`.
3. In the Godot editor: **Import** → browse to the folder → select
   `project.godot` → **Import & Edit**.

## Run the automated tests (do this before playing)

1. In the FileSystem dock, open `tests/TestRunner.tscn`.
2. Tap **Run Current Scene** (the clapperboard icon next to the main Play
   button).
3. Wait — the screen stays dark while the suites run. The event sweep does
   100 seeds × 30 days, so give it up to a minute or two on a phone.
4. A report appears on screen: green **ALL TESTS PASSED**, or a red failure
   count with the failing checks listed first. **Screenshot it and send it to
   Claude.** (The same lines also print to the editor's Output panel.)

Then the balance sweep: run `tests/BalanceSweep.tscn` the same way and
screenshot the numbers (survival %, median expansion day).

**Note:** the test scenes exercise save/load, so they wipe the game's save
file when they finish. Fine while testing — just know a play-through won't
survive a test run.

## Play the game

Tap the main **Play** button (runs `scenes/Game.tscn`). Portrait 720×1280,
fully touch-driven: set your price with the slider, **Start / Continue** runs
the days, and decision pop-ups (credit requests, bulk orders, the lender)
pause the clock until you choose.

## What to send back to Claude

- Screenshots of the TestRunner report and the BalanceSweep numbers
  (or type out any FAIL lines)
- Anything that crashed, looked wrong, or felt confusing while playing
- Your read on the fun: did a day feel uncertain? did losing a regular sting?
