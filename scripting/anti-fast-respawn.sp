#include <sourcemod>

public Plugin myinfo = {
    name = "Anti fast respawn",
    author = "Dron-elektron",
    description = "Prevents the player from fast respawn after death when the player has changed his class",
    version = "0.2.0",
    url = ""
}

static char PLUGIN_PREFIX[] = "[AFR]";
static char USAGE_PREFIX[] = "[SM] Usage";
static char USAGE_COMMAND_WARNINGS[] = "sm_afr_warnings <#userid|name>";
static char USAGE_COMMAND_RESET_WARNINGS[] = "sm_afr_reset_warnings <#userid|name>";
static char EVENT_PLAYER_CHANGE_CLASS[] = "player_changeclass";
static float RESPAWN_THRESHOLD_MSEC = 0.1;

static ConVar g_pluginEnable = null;
static ConVar g_maxWarnings = null;

enum struct PlayerState {
    Handle punishTimer;
    int warnings;
}

static PlayerState g_playerStates[MAXPLAYERS + 1];

public void OnPluginStart() {
    LoadTranslations("common.phrases");
    LoadTranslations("anti-fast-respawn.phrases");
    HookEvent(EVENT_PLAYER_CHANGE_CLASS, Event_PlayerChangeClass);

    g_pluginEnable = CreateConVar("sm_afr_enable", "0", "Enable (1) or disable (0) plugin");
    g_maxWarnings = CreateConVar("sm_afr_max_warnings", "3", "Maximum warnings about fast respawn");

    RegAdminCmd("sm_afr_warnings", Command_Warnings, ADMFLAG_GENERIC, USAGE_COMMAND_WARNINGS);
    RegAdminCmd("sm_afr_reset_warnings", Command_ResetWarnings, ADMFLAG_GENERIC, USAGE_COMMAND_RESET_WARNINGS);
}

public void OnPluginEnd() {
    UnhookEvent(EVENT_PLAYER_CHANGE_CLASS, Event_PlayerChangeClass);
    DeletePunishTimerAll();
}

public void OnClientDisconnect(int client) {
    DeletePunishTimer(client);
    g_playerStates[client].warnings = 0;
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

    g_playerStates[client].punishTimer = null;

    return Plugin_Continue;
}

public Action Command_Warnings(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "%s: %s", USAGE_PREFIX, USAGE_COMMAND_WARNINGS);

        return Plugin_Handled;
    }

    char name[MAX_NAME_LENGTH];

    GetCmdArg(1, name, sizeof(name));

    int target = FindTarget(client, name);

    if (target == -1) {
        return Plugin_Handled;
    }

    int playerWarnings = g_playerStates[target].warnings;
    int maxWarnings = GetMaxWarnings();

    ReplyToCommand(client, "%s %t", PLUGIN_PREFIX, "Warnings for player", name, playerWarnings, maxWarnings);

    return Plugin_Handled;
}

public Action Command_ResetWarnings(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "%s: %s", USAGE_PREFIX, USAGE_COMMAND_RESET_WARNINGS);

        return Plugin_Handled;
    }

    char name[MAX_NAME_LENGTH];

    GetCmdArg(1, name, sizeof(name));

    int target = FindTarget(client, name);

    if (target == -1) {
        return Plugin_Handled;
    }

    g_playerStates[target].warnings = 0;

    char targetName[MAX_NAME_LENGTH];

    GetClientName(target, targetName, sizeof(targetName));
    ShowActivity2(client, PLUGIN_PREFIX, " %t", "Warnings for the player are reset to zero", targetName);

    return Plugin_Handled;
}

void CreatePunishTimer(int client) {
    if (g_playerStates[client].punishTimer == null) {
        int userId = GetClientUserId(client);

        g_playerStates[client].punishTimer = CreateTimer(RESPAWN_THRESHOLD_MSEC, Timer_Punish, userId);
    }
}

void DeletePunishTimer(int client) {
    delete g_playerStates[client].punishTimer;
}

void DeletePunishTimerAll() {
    for (int client = 0; client <= MAXPLAYERS; client++) {
        DeletePunishTimer(client);
    }
}

void PunishPlayer(int client) {
    g_playerStates[client].warnings++;

    int playerWarnings = g_playerStates[client].warnings;
    int maxWarnings = GetMaxWarnings();

    if (playerWarnings > maxWarnings) {
        KickClient(client, "%s %t", PLUGIN_PREFIX, "Fast respawn forbidden");
    } else {
        char nickname[MAX_NAME_LENGTH];

        GetClientName(client, nickname, sizeof(nickname));
        PrintToChatAll("%s %t", PLUGIN_PREFIX, "Fast respawn detected", nickname, playerWarnings, maxWarnings);
    }
}

bool IsPluginEnabled() {
    return g_pluginEnable.IntValue == 1;
}

int GetMaxWarnings() {
    return g_maxWarnings.IntValue;
}
