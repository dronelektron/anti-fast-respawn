#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include "morecolors"

#pragma semicolon 1
#pragma newdecls required

#include "afr/game-state"
#include "afr/menu"
#include "afr/message"
#include "afr/sound"
#include "afr/use-case"

#include "modules/api.sp"
#include "modules/client.sp"
#include "modules/console-command.sp"
#include "modules/console-variable.sp"
#include "modules/game-state.sp"
#include "modules/menu.sp"
#include "modules/message.sp"
#include "modules/sound.sp"
#include "modules/storage.sp"
#include "modules/use-case.sp"

#define FAST_RESPAWN_DETECTOR "fast-respawn-detector"

public Plugin myinfo = {
    name = "Anti fast respawn",
    author = "Dron-elektron",
    description = "Allows you to prevent a fast respawn",
    version = "1.2.2",
    url = "https://github.com/dronelektron/anti-fast-respawn"
};

public void OnPluginStart() {
    Api_Create();
    Command_Create();
    Variable_Create();
    Storage_Create();
    HookEvent("dod_round_start", Event_RoundStart);
    HookEvent("dod_round_win", Event_RoundWin);
    HookEvent("player_spawn", Event_PlayerSpawn);
    LoadTranslations("common.phrases");
    LoadTranslations("anti-fast-respawn.phrases");
    AutoExecConfig(true, "anti-fast-respawn");
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax) {
    RegPluginLibrary("anti-fast-respawn");

    return APLRes_Success;
}

public void OnAllPluginsLoaded() {
    if (!LibraryExists(FAST_RESPAWN_DETECTOR)) {
        SetFailState("Library '%s' is not found", FAST_RESPAWN_DETECTOR);
    }
}

public void OnPluginEnd() {
    Api_Destroy();
    Storage_Destroy();
}

public void OnMapStart() {
    Sound_Precache();
}

public void OnMapEnd() {
    Storage_Clear();
}

public void OnClientConnected(int client) {
    Client_Reset(client);
}

public void OnClientPostAdminCheck(int client) {
    UseCase_LoadWarnings(client);
}

public void OnClientDisconnect(int client) {
    UseCase_SaveWarnings(client);
}

public void OnClientFastRespawned(int client, float spectatorsTime) {
    UseCase_ClientFastRespawned(client, spectatorsTime);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    GameState_SetRoundEnd(ROUND_END_NO);
}

public void Event_RoundWin(Event event, const char[] name, bool dontBroadcast) {
    GameState_SetRoundEnd(ROUND_END_YES);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    UseCase_BlockPlayerAfterSpawn(client);
}
