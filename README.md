<h1 align="center">Mors Longa Revival</h1>
<p align="center">
  <i>"A long and painful death" in latin</i>
  <br/>
  <img width="120" src="https://static.wikia.nocookie.net/logopedia/images/7/79/Teardown_2022_%28Icon%29.png/revision/latest/scale-to-width-down/250?cb=20221215232436" />
  <br/>
  A co-op port of Overdrive Studios' <b>Mors Longa</b> by SirH to Teardown 2.x multiplayer (up to 4 players).
  <br/><br/>
  <b>Original mod:</b>
  <b><a href="https://steamcommunity.com/sharedfiles/filedetails/?id=2906369984">Workshop</a></b> |
  <b><a href="https://discord.gg/j3ZW4fBdDT">Discord</a></b> |
  <b><a href="https://steamcommunity.com/groups/OverdriveStudiosTD">Overdrive Studios Steam group</a></b>
</p>

## AI DISCLOSURE

This project's whole porting process was done with Claude.

## About this port

Mors Longa Revival brings the original to Teardown 2.x and its co-op multiplayer:

- **Co-op for up to 4 players.** Each player has their own inventory, health, injuries, guns and money; the road is
  generated ahead of the player furthest along, and players left behind are brought along. Only the host starts a
  run (the host's difficulty, rules, perks and garage apply).
- **Vehicles with seats.** Every drivable vehicle has seats; friendly NPCs ride along too.
- **Mounted guns without the separate AVF mod.** Technicals, tanks, BMPs, the Katyusha, the Kornet / AGS-30 tripods
  and the other armed vehicles work on their own: a gunner place and AVF's shells, ported with credit.
- **Flyable AS350 helicopter** with seats and a mouse-aim flight model (the enemy helicopters keep their original
  AI).
- Many original bugs fixed along the way. The full list of changes against the original is in
  [docs/TECHNICAL_REFERENCE.md](docs/TECHNICAL_REFERENCE.md) §8, unfinished or set-aside content in §9.

**Status:** everything is tested in single-player; multiplayer testing is next. Not yet in the port: the CH-47 and
Hind helicopters (single-player only for now), horde mode (unfinished in the original too), the unfinished PKM, M9,
Bauer-553 and MGL guns, and the AGS-30 aiming up and down.

## Story

The Country of Alashya, heavily influenced by America in the middle east, has entered lockdown due to a deadly,
paranoia inducing virus. Civilians are outraged, attempting to flee the country, but the Alashyan government has shut
down the inner cities and rural areas making it almost impossible to leave. Insurgents and anarchists have risen up.
The population is frantic as everyone is trying escape Alashya. The AAF forces have now been given the green light to
eliminate anyone attempting to escape through the country's vast highways with lethal force.

## Gameplay objective

Now since the highway is endless and you literally cannot finish the game, your task will be to survive as long as
you can, by continuing to move forwards, finding food and fuel to keep you going. Search abandoned roadside buildings
for loot, optimize your inventory storage and tread carefully, as getting shot can lead to bleeding damage and bone
fractures. And lastly, kill anyone that means you harm.

## Official Mors Longa soundtrack

- [YouTube](https://www.youtube.com/watch?v=dr5BksAVvcI)
- [SoundCloud](https://soundcloud.com/deffcolony/mors-longa-main-theme)

## Credits

- **Overdrive Studios** – the original Mors Longa (assets free to use with credit).
- Extra credits of the original: Elboydo, OpaBlyat1, Artzert, The Mafia, Micro, Morvex, Dounut.
- **elboydo** – AVF (Armed Vehicles Framework): its shell simulation is ported for the mounted guns.

## Temporary bug solutions

- **Inventory flush** – drop everything in your inventory by holding D+R+O and pressing P last, with the other keys
  still held down (affects only your own inventory).
- **Continue button greyed out** when it shouldn't be – hold C+T+N in the main menu (the host; only the host
  starts the game).
- **NPCs lying on the ground inactive** – press Backspace (debug menu) → Reset NPCs.

<img src="https://i.imgur.com/MWABJaF.jpeg" width="100%">

## For developers

Start with [CLAUDE.md](CLAUDE.md) (handoff notes), then [docs/TECHNICAL_REFERENCE.md](docs/TECHNICAL_REFERENCE.md),
[docs/PORTING.md](docs/PORTING.md) and [tools/porting/README.md](tools/porting/README.md). The Workshop upload is built
with `tools/porting/make_release.py` (a copy without the development files).
