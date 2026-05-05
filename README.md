# Iron Fist

Anime-style Roblox punch simulator. Punch the bag, get stronger, buy
upgrades, unlock new zones.

## MVP scope

- One **PunchingBag** in the world. Clicking or touching it grants the
  player **Strength** (the only currency).
- Two upgrades, both spent in Strength:
  - **Stronger Punches** — adds flat damage per click.
  - **Faster Hands** — reduces the server-side punch cooldown.
- Player stats persist across sessions via DataStore (`PunchData_v1`).
- A minimal Lua HUD shows the Strength counter and the two upgrade
  buttons. It is intended to be replaced by a hand-built ScreenGui in
  Studio once the visual style is locked in.

## Layout

```
src/
├── shared/               (replicated to ReplicatedStorage.Shared)
│   ├── Config.lua            game tuning + cost / damage formulas
│   └── RemoteObjects.lua     RemoteFunction / RemoteEvent factory
│
├── server/               (in ServerScriptService.Server)
│   ├── init.server.lua       server entry point
│   └── services/
│       ├── DataStoreService.lua     load / save player stats
│       ├── PlayerStatsService.lua   in-memory stats + Remote handlers
│       └── PunchingBagService.lua   spawns the bag, wires its events
│
└── client/               (in StarterPlayer.StarterPlayerScripts.Client)
    ├── init.client.lua       client entry point
    └── controllers/
        ├── HUD.lua               Strength counter + shop buttons
        └── PunchEffects.lua      visual burst when anyone punches
```

## Running locally

```sh
aftman install         # one-time, installs rojo
rojo serve             # then attach Studio via the Rojo plugin
```

The Roblox place is gitignored (`/iron-fist.rbxlx`); you build it
locally and Rojo syncs `src/` into it.

## Next steps (post-MVP)

- More upgrades (Multiplier, AutoPunch, RebirthBonus).
- Multiple zones with progressively tougher bags / enemies.
- Pet system (multiplier collectibles).
- Rebirth (reset Strength for a permanent multiplier).
- Replace the Lua HUD with hand-built ScreenGuis in StarterGui.
- Anime-style FX: KI auras, screen-shake on heavy hits, charge-up
  animations.
