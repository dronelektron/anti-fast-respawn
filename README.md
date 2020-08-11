# Anti Fast Respawn

Prevents the player from fast respawn after death when the player has changed his class.

# Installation

* Download latest [release](https://github.com/Dron-elektron/anti-fast-respawn/releases)
* Extract "plugins" and "translations" folders to "addons/sourcemod" folder of your server

# Console Variables

* sm_afr_enable - Enable (1) or disable (0) plugin [default: "1"]
* sm_afr_max_warnings - Maximum warnings about fast respawn [default: "3"]
* sm_afr_punish_type - Punish type for fast respawn (0 - freeze, 1 - kick, 2 - ban) [default: 1]
* sm_afr_freeze_time - Freeze time (in seconds) due fast respawn [default: 3]
* sm_afr_ban_time - Ban time (in minutes) due fast respawn [default: 5]

# Console Commands

* sm_afr - Show AFR menu
* sm_afr_warnings <#userid|name> - Show warnings amount for given player
* sm_afr_reset_warnings <#userid|name> - Reset warnings amount for given player
