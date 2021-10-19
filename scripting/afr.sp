#include <sourcemod>
#include <sdktools>
#include <afr>

public Plugin myinfo = {
    name = "Anti fast respawn (core)",
    author = PLUGIN_AUTHOR,
    description = "Detects fast respawn if a player has changed his class after death near respawn zone",
    version = PLUGIN_VERSION,
    url = ""
}

static const float CHECKER_TIMER_DURATION = 0.1;

static GlobalForward g_onClientFastRespawned = null;
static ConVar g_pluginEnabled = null;
static ConVar g_minActivePlayers = null;
static bool g_isRoundEnd = false;
static Handle g_checkerTimer[MAXPLAYERS + 1] = {null, ...};
static bool g_killed[MAXPLAYERS + 1] = {false, ...};

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int errMax) {
    CreateNative("Afr_IsProtectionEnabled", Native_IsProtectionEnabled);
    CreateNative("Afr_IsPlayerKilled", Native_IsPlayerKilled);
    CreateNative("Afr_SetPlayerKilled", Native_SetPlayerKilled);

    return APLRes_Success;
}

public void OnPluginStart() {
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_changeclass", Event_PlayerChangeClass);
    HookEvent("dod_round_start", Event_RoundStart);
    HookEvent("dod_round_win", Event_RoundWin);

    g_onClientFastRespawned = new GlobalForward("OnPlayerFastRespawned", ET_Ignore, Param_Cell);
    g_pluginEnabled = CreateConVar("sm_afr_enable", "1", "Enable (1) or disable (0) detection of fast respawn");
    g_minActivePlayers = CreateConVar("sm_afr_min_active_players", "1", "Minimum amount of active players to enable protection");

    LoadTranslations("anti-fast-respawn.phrases");
    AutoExecConfig(true, "afr");
}

public void OnClientConnected(int client) {
    g_checkerTimer[client] = null;
    g_killed[client] = false;
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
        Call_OnClientFastRespawned(client);
    }

    g_checkerTimer[client] = null;

    return Plugin_Continue;
}

static void Call_OnClientFastRespawned(int client) {
    Call_StartForward(g_onClientFastRespawned);
    Call_PushCell(client);
    Call_Finish();
}

static void CreateCheckerTimer(int client) {
    if (!Afr_IsProtectionEnabled()) {
        return;
    }

    if (g_checkerTimer[client] == null) {
        int userId = GetClientUserId(client);

        g_checkerTimer[client] = CreateTimer(CHECKER_TIMER_DURATION, Timer_Checker, userId);
    }
}

static bool IsEnoughActivePlayers() {
    int activePlayers = GetActivePlayers();
    int minActivePlayers = GetMinActivePlayers();

    return activePlayers >= minActivePlayers;
}

static int GetActivePlayers() {
    return GetTeamClientCount(TEAM_ALLIES) + GetTeamClientCount(TEAM_AXIS);
}

static bool IsPluginEnabled() {
    return g_pluginEnabled.IntValue == 1;
}

static int GetMinActivePlayers() {
    return g_minActivePlayers.IntValue;
}

static any Native_IsProtectionEnabled(Handle plugin, int numParams) {
    return IsPluginEnabled() && IsEnoughActivePlayers() && !g_isRoundEnd;
}

static any Native_IsPlayerKilled(Handle plugin, int numParams) {
    int client = GetNativeCell(1);

    return g_killed[client];
}

static any Native_SetPlayerKilled(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    bool isKilled = GetNativeCell(2);

    g_killed[client] = isKilled;
}
