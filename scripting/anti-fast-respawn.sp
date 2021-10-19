#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include "morecolors"

#include "anti-fast-respawn"
#include "attack-blocker"
#include "commands"
#include "map-warnings"
#include "menu"
#include "punishment"

public Plugin myinfo = {
    name = "Anti fast respawn",
    author = "Dron-elektron",
    description = "Detects fast respawn if a player has changed his class after death near respawn zone",
    version = "0.16.0",
    url = ""
}

static bool g_isRoundEnd = false;
static Handle g_checkerTimer[MAXPLAYERS + 1] = {null, ...};
static bool g_killed[MAXPLAYERS + 1] = {false, ...};

public void OnPluginStart() {
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("player_changeclass", Event_PlayerChangeClass);
    HookEvent("dod_round_start", Event_RoundStart);
    HookEvent("dod_round_win", Event_RoundWin);

    CreateConVars();
    RegisterAdminCmds();
    CreateMapWarningsTrie();
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
    g_checkerTimer[client] = null;
    g_killed[client] = false;

    SetPlayerAuthId(client, NO_AUTH_ID);
    ClearPunishment(client);
}

public void OnClientAuthorized(int client, const char[] auth) {
    LoadPlayerWarnings(client);
}

public void OnClientPutInServer(int client) {
    HookTakeDamage(client);
}

public void OnClientDisconnect(int client) {
    UnhookTakeDamage(client);
    SavePlayerWarnings(client);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    g_killed[client] = true;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    g_killed[client] = false;

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

    if (g_killed[client]) {
        CreateCheckerTimer(client);
    }
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    g_isRoundEnd = false;
}

public void Event_RoundWin(Event event, const char[] name, bool dontBroadcast) {
    g_isRoundEnd = true;
}

public Action Timer_Checker(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    if (IsPlayerAlive(client)) {
        PunishPlayer(client);
    }

    g_checkerTimer[client] = null;

    return Plugin_Continue;
}

void CreateCheckerTimer(int client) {
    if (!IsProtectionEnabled()) {
        return;
    }

    if (g_checkerTimer[client] == null) {
        int userId = GetClientUserId(client);

        g_checkerTimer[client] = CreateTimer(CHECKER_TIMER_DURATION, Timer_Checker, userId);
    }
}

bool IsEnoughActivePlayers() {
    int activePlayers = GetActivePlayers();
    int minActivePlayers = GetMinActivePlayers();

    return activePlayers >= minActivePlayers;
}

int GetActivePlayers() {
    return GetTeamClientCount(TEAM_ALLIES) + GetTeamClientCount(TEAM_AXIS);
}

bool IsProtectionEnabled() {
    return IsPluginEnabled() && IsEnoughActivePlayers() && !g_isRoundEnd;
}

bool IsPlayerKilled(int client) {
    return g_killed[client];
}

void SetPlayerKilled(int client, bool isKilled) {
    g_killed[client] = isKilled;
}
