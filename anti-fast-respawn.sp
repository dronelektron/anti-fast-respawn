#include <sourcemod>

public Plugin myinfo = {
    name = "Anti fast respawn",
    author = "Dron-elektron",
    description = "Prevents the player from fast respawn after death when the player has changed his class",
    version = "0.1.0",
    url = ""
}

static char EVENT_PLAYER_CHANGE_CLASS[] = "player_changeclass";
static float RESPAWN_THRESHOLD_MSEC = 0.1;

static ConVar g_pluginEnable = null;
static ConVar g_maxWarnings = null;

static Handle g_punishTimers[MAXPLAYERS + 1] = {null, ...};
static int g_playerWarnings[MAXPLAYERS + 1] = {0, ...};

public void OnPluginStart() {
    LoadTranslations("anti-fast-respawn.phrases");
    HookEvent(EVENT_PLAYER_CHANGE_CLASS, Event_PlayerChangeClass);

    g_pluginEnable = CreateConVar("sm_afr_enable", "0", "Enable (1) or disable (0) plugin");
    g_maxWarnings = CreateConVar("sm_afr_max_warnings", "3", "Maximum warnings about fast respawn");
}

public void OnPluginEnd() {
    UnhookEvent(EVENT_PLAYER_CHANGE_CLASS, Event_PlayerChangeClass);
    DeletePunishTimerAll();
}

public void OnClientDisconnect(int client) {
    DeletePunishTimer(client);
    ResetPlayerWarnings(client);
}

public void Event_PlayerChangeClass(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    if (IsPluginEnabled() && !IsPlayerAlive(client)) {
        CreatePunishTimer(client);
    }
}

public Action Timer_Punish(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    if (IsPlayerAlive(client)) {
        PunishPlayer(client);
    }

    g_punishTimers[client] = null;

    return Plugin_Continue;
}

void CreatePunishTimer(int client) {
    if (g_punishTimers[client] == null) {
        int userId = GetClientUserId(client);

        g_punishTimers[client] = CreateTimer(RESPAWN_THRESHOLD_MSEC, Timer_Punish, userId);
    }
}

void DeletePunishTimer(int client) {
    delete g_punishTimers[client];
}

void DeletePunishTimerAll() {
    for (int client = 0; client <= MAXPLAYERS; client++) {
        DeletePunishTimer(client);
    }
}

void PunishPlayer(int client) {
    IncrementPlayerWarnings(client);

    int playerWarnings = GetPlayerWarnings(client);
    int maxWarnings = GetMaxWarnings();

    if (playerWarnings > maxWarnings) {
        KickClient(client, "%t", "Fast respawn forbidden");
    } else {
        char nickname[MAX_NAME_LENGTH];

        GetClientName(client, nickname, sizeof(nickname));
        PrintToChatAll("%t", "Fast respawn detected", nickname, playerWarnings, maxWarnings);
    }
}

void ResetPlayerWarnings(int client) {
    g_playerWarnings[client] = 0;
}

void IncrementPlayerWarnings(int client) {
    g_playerWarnings[client]++;
}

int GetPlayerWarnings(int client) {
    return g_playerWarnings[client];
}

bool IsPluginEnabled() {
    return g_pluginEnable.IntValue == 1;
}

int GetMaxWarnings() {
    return g_maxWarnings.IntValue;
}
