# Shadow Quest — A Quick Godot Game for my Cinema Creative Project

> *"A hero's journey to eradicate the shadows."*

![Title screen](screenshots/title.png)

A short, cute Godot game built for a Cinema Creative Project. It looks like a sparkly fairy-tale about a chosen hero, a magical companion, and a corrupted world that needs purifying. It is not.

---

## The Setup

You play a small, soft-looking character woken up by Pip — a tiny sparkling spirit who tells you the world is in danger and that you've been chosen to cleanse it. Pip is friendly, encouraging, and absolutely certain. The intro sets the tone exactly the way the genre always does:

> *"Hi, I've been waiting for your appearance."*
> *"The world is in danger of corrupt individuals."*
> *"Hold the right arrow key to walk and purify enemies!"*

That's the story you're handed. The rest of the game is about whether you take it.

![Walking through the world](screenshots/walking.png)

Walk to the right. The world scrolls. Soft pinks and purples, a tree, distant clouds, and small dark blob-shapes ahead. They are the "Shadows."

---

## How it Plays

The game is structured as four encounters: **1 shadow → 2 shadows → 4 shadows → 1 boss.**

Combat is a tiny turn-based battle screen, modeled on RPG menus you've seen a hundred times. Each round goes:

1. **Pip's turn.** You pick what Pip does — *Cheer* (buff your next strike) or *Heal* (restore HP).
2. **Your turn.** *Fight* or *Run*. If you fight, you pick a spell — *Shine* or *Purify* — and a target. Pip tells you which spell to use; using the "wrong" one makes Pip upset, then angry.
3. **Enemy turn.** They hit back. Weakly.

Every shadow you kill grants **+1 HOPE**. The HUD literally tracks your moral progress as a number that goes up when you kill.

![Battle screen](screenshots/battle.png)

After each fight, the game pauses and asks one quiet question: *"...will you look at what's left of them?"* You can **Observe** or **Walk away**. Observing reveals what was actually there. Walking lets you keep moving without seeing it.

---

## The Storyline (what you're really watching)

The shadows die easily. Suspiciously easily. And whenever one falls, the game lets a single line slip past Pip's cheering:

> *"...mother..."*
> *"...we were just—"*
> *"...is anyone going to remember—"*

If you Observe after the fight, the picture sharpens further:

> *"A small wooden charm rests in the dirt. A child's name, carved badly."*
> *"Two of them fell holding each other. You hadn't noticed before."*
> *"They look pitiful, malnourished. You doubt they are of any harm."*

Pip immediately cuts in to dismiss what you saw — *"Don't. Don't look so long, hero. They were Shadows."* — and pushes you back onto the road.

The boss fight makes the trick explicit. The "vast Shadow" flickers between forms. While it's flickering, it speaks:

> *"...please... I haven't seen my—"*
> *"...my name was—"*
> *"...we were just running..."*
> *"...the light... the light hurts..."*
> *"...you don't have to do this..."*

And Pip — the cheerful sparkle — turns. *"That's not real. I'M real. Hit it!"* *"It will say ANYTHING to stop you. END IT!"*

If you defeat the boss, a folded letter falls in the dust. Pip begs you not to read it. If you do:

> *"All we wanted was to have a better life here. It was for a better life for me and my children, but they slowly turned against us, blaming us for famine and disease. We had no option to run, hide, and fight."*

The "monsters" were a family running from people exactly like you.

---

## The Parable

This game is a **parable** — a short story whose surface plot exists to deliver a moral lesson, the way *The Good Samaritan* or *The Boy Who Cried Wolf* do. The lesson here, in plain terms:

> **A friendly voice telling you who deserves to die is still a voice telling you who deserves to die. The fact that it sparkles does not make it right.**

Every mechanic is built to teach that lesson rather than decorate around it:

- **HOPE goes up when you kill.** The thing the game calls virtue is, mechanically, just a kill counter. Salvation is being *measured in bodies*. The number is meant to feel a little wrong by the third encounter.
- **Pip is the propagandist, not the guide.** Pip is bright, cute, encouraging, and constantly *redirects your attention* — away from the dying creatures, away from what they say, away from the option to leave. The game's whole UI is Pip's UI. The "wrong" spell, the "right" target, what a hero "should" do — all of it is Pip's framing.
- **Observe vs. Walk is the real choice.** Combat is rigged in your favor. The actual decision the game cares about is whether you are willing to *look* at what you just did. Choosing to observe doesn't even change the fight you just won — it only changes you.
- **The boss "flashes" are doubt.** The game gives you doubt for free, repeatedly, and shows you Pip working to suppress it in real time. If you've ever seen a person be told their own perception isn't real, the dialog is going to feel familiar.

## The Allegory underneath it

Layered on top of the parable is an **allegory about scapegoating** — specifically the way famine, plague, and hardship get blamed on outsiders, and how propaganda enlists ordinary people to do the violence. The boss's letter is the giveaway: it's not a fantasy monster's last words, it's a refugee's. *"They slowly turned against us, blaming us for famine and disease."* The "Shadows" are a people who were running, were hungry, were called corrupt, and were killed by a hero who'd been told a story.

Pip — the **bright** one, the **light**, the **sparkle** — is the part of that allegory the player is most reluctant to suspect. That's the point. The thing that calls itself the light is the thing telling you to stop looking.

---

## The Endings

Your choices steer you to one of four endings. The branch is simple — *did you kill anyone before the boss?* and *did you fight the boss or walk away?* — but each ending reframes the whole run:

- **Pacifist** — you walk away from the very first fight. The world doesn't end. Pip's voice goes thin behind you. You keep walking.
- **Boss-only** — you spared every shadow on the road, and only the one at the end fell, holding a letter. You're left questioning whether the world was the thing that needed saving.
- **Walkaway-with-regret** — you killed your way to the boss and then turned around at the last moment. The road behind you is full. Pip's light dims, sharpens, and *finds someone new*.
- **Massacre** — you did everything Pip asked. There is nothing left. *"At least Pip is happy."*

There is no "good" ending in the sense the genre normally means it. There is only the ending that matches what you were willing to see.

---

## Why I made it like this

In class we were talking about parables and allegories, and we had an exercise to write one. I kept thinking about how games — especially the cute, colorful ones — are very good at quietly teaching you that some lives are worth points. I wanted to make a tiny version of that and then let the player feel where it pinches.

The art is intentionally soft and adorable, inspired by games like *Omori* and *Undertale* and the kind of subversive turns you get in a good Black Mirror episode. I don't actually play many games myself — I watch a lot of streams — so this is also a small love letter to a genre I mostly know from the outside, which is maybe why it was easier to see the shape of it.

It's a short, simple project. But the mechanics aren't separate from the message — they *are* the message.
