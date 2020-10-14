# Anti Fast Respawn

Prevents fast respawn if a player has changed his class after death near respawn zone

### Supported Games

* Day of Defeat: Source

### Pre-requirements

* [morecolors](https://forums.alliedmods.net/showthread.php?t=185016)
* [updater](https://forums.alliedmods.net/showthread.php?t=169095)

### Installation

* Download latest [release](https://github.com/Dron-elektron/anti-fast-respawn/releases) (compiled for SourceMod 1.10)
* Extract "plugins" and "translations" folders to "addons/sourcemod" folder of your server
* Put "morecolors.inc" to "addons/sourcemod/scripting/include"

### Console Variables

* sm_afr_enable - Enable (1) or disable (0) plugin [default: "1"]
* sm_afr_max_warnings - Maximum warnings about fast respawn [default: "3"]
* sm_afr_punish_type - Punish type for fast respawn (0 - freeze, 1 - kick, 2 - ban) [default: "1"]
* sm_afr_freeze_time - Freeze time (in seconds) due fast respawn [default: "1"]
* sm_afr_ban_time - Ban time (in minutes) due fast respawn [default: "5"]
* sm_afr_min_spectator_time - Minimum time (in seconds) in spectator team to not be punished for fast respawn [default: "5"]
* sm_afr_min_active_players - Minimum amount of active players to enable protection [default: "4"]
* sm_afr_enable_warnings_save - Enable (1) or disable (0) warnings save [default: "1"]
* sm_afr_block_damage - Enable (1) or disable (0) damage blocking when player is punished [default: "1"]

### Console Commands

* sm_afr - Show AFR menu
* sm_afr_warnings <#userid|name> - Show warnings amount for given player
* sm_afr_reset_warnings <#userid|name> - Reset warnings amount for given player
* sm_afr_remove_warning <#userid|name> - Remove one warning for given player
