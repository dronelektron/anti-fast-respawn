#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define ANTI_FAST_RESPAWN "anti-fast-respawn"

public Plugin myinfo = {
    name = "Anti fast respawn [punish]",
    author = "Dron-elektron",
    description = "Kicks the player for a fast respawn",
    version = "1.0.0",
    url = "https://github.com/dronelektron/anti-fast-respawn"
};

public void OnPluginStart() {
	LoadTranslations("anti-fast-respawn-punish.phrases");
}

public void OnAllPluginsLoaded() {
    if (!LibraryExists(ANTI_FAST_RESPAWN)) {
        SetFailState("Library '%s' is not found", ANTI_FAST_RESPAWN);
    }
}

public void OnFastRespawnPunish(int client) {
	KickClient(client, "%t", "Fast respawn is forbidden");
}
