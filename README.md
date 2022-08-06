# Anti fast respawn

Allows you to prevent a fast respawn

### Supported Games

* Day of Defeat: Source

### Installation

* Download latest [release](https://github.com/dronelektron/anti-fast-respawn/releases) (compiled for SourceMod 1.11)
* Extract "plugins" and "translations" folders to "addons/sourcemod" folder of your server

### Console Variables

* sm_afr_enable - Enable (1) or disable (0) plugin [default: "1"]
* sm_afr_min_active_players - Minimum amount of active players to enable protection [default: "1"]
* sm_afr_frozen_player_block_attack - Block (1 - yes, 0 - no) attack from a frozen player [default: "1"]
* sm_afr_frozen_player_block_damage - Block (1 - yes, 0 - no) damage to a frozen player [default: "1"]
* sm_afr_warnings_saving - Enable (1) or disable (0) warnings saving [default: "1"]
* sm_afr_max_warnings - Maximum number of warnings [default: "3"]
* sm_afr_freeze_time - Freeze time (in seconds) due to fast respawn [default: "5"]
* sm_afr_min_spectator_time - Minimum time (in seconds) in spectator team to not be frozen for a fast respawn [default: "5"]
* sm_afr_show_freeze_timer - Show (1 - yes, 0 - no) freeze timer [default: "1"]

### Console Commands

* sm_afr - Show AFR menu
* sm_afr_warnings <#userid|name> - Show player warnings
* sm_afr_warnings_reset <#userid|name> - Reset player warnings
* sm_afr_warnings_reduce <#userid|name> - Reduce player warnings

### API

* client - Client's number

```
forward void OnFastRespawnPunishment(int client);
```

See [this plugin](https://github.com/dronelektron/anti-fast-respawn/blob/master/scripting/anti-fast-respawn-punishment.sp) for API usage example
