#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include "morecolors"

#pragma semicolon 1
#pragma newdecls required

#include "attack-blocker"
#include "commands"
#include "detector"
#include "map-warnings"
#include "menu"
#include "message"
#include "punishment"
#include "team"

#include "modules/attack-blocker.sp"
#include "modules/commands.sp"
#include "modules/convars.sp"
#include "modules/detector.sp"
#include "modules/map-warnings.sp"
#include "modules/menu.sp"
#include "modules/punishment.sp"

public Plugin myinfo = {
    name = "Anti fast respawn",
    author = "Dron-elektron",
    description = "Prevents fast respawn if a player changes class on the spawn zone after dying",
    version = "1.0.6",
    url = ""
};

public void OnPluginStart() {
    CreateConVars();
    RegisterAdminCmds();
    CreateMapWarningsTrie();
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("player_changeclass", Event_PlayerChangeClass);
    HookEvent("dod_round_start", Event_RoundStart);
    HookEvent("dod_round_win", Event_RoundWin);
    LoadTranslations("anti-fast-respawn.phrases");
    AutoExecConfig(true, "anti-fast-respawn");
}

public void OnPluginEnd() {
    DestroyMapWarningsTrie();
}

public void OnMapStart() {
    PrecacheDamageMessageSound();
    PrecachePunishmentSounds();
}

public void OnMapEnd() {
    ClearMapWarningsTrie();
}

public void OnClientConnected(int client) {
    SetPlayerKilled(client, false);
    ResetPlayerCheckerTimer(client);
    SetPlayerAuthId(client, NO_AUTH_ID);
    ClearPunishment(client);
}

public void OnClientAuthorized(int client, const char[] auth) {
    LoadPlayerWarnings(client);
}

public void OnClientDisconnect(int client) {
    SavePlayerWarnings(client);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    SetPlayerKilled(client, true);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    SetPlayerKilled(client, false);

    if (IsPlayerPunished(client)) {
        BlockPlayer(client);
    }
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);
    int newTeam = event.GetInt("team");

    CheckFastRespawnFromSpectator(client, newTeam);
}

public void Event_PlayerChangeClass(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    if (IsPlayerKilled(client)) {
        CreateCheckerTimer(client);
    }
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    SetRoundEnd(false);
}

public void Event_RoundWin(Event event, const char[] name, bool dontBroadcast) {
    SetRoundEnd(true);
}
