# Anti Fast Respawn

Prevents the player from fast respawn after death when the player has changed his class.

# Installation

* Download latest release
* Extract "plugins" and "translations" folders to "addons/sourcemod" folder of your server.

# Console Variables

* sm_afr_enable - Enable (1) or disable (0) plugin [default: "1"]
* sm_afr_max_warnings - Maximum warnings about fast respawn [default: "3"]
* sm_afr_punish_type - Punish type for fast respawn (0 - no action, 1 - kick, 2 - ban) [default: 1]
* sm_afr_ban_time - Ban time for fast respawn (in minutes) [default: 5]

# Console Commands

* sm_afr_warnings <#userid|name> - Shows warnings amount for given player
* sm_afr_reset_warnings <#userid|name> - Resets warnings amount for given player
