#include <sourcemod>

#define PLUGIN_PREFIX "[AFR] "

#define USAGE_PREFIX "[AFR] Usage"
#define USAGE_COMMAND_WARNINGS "sm_afr_warnings <#userid|name>"
#define USAGE_COMMAND_RESET_WARNINGS "sm_afr_reset_warnings <#userid|name>"

#define COMMAND_FREEZE_FORMAT "sm_freeze #%d %d"

#define EVENT_PLAYER_CHANGE_CLASS "player_changeclass"
#define RESPAWN_THRESHOLD_MSEC 0.1
#define MAX_TEXT_LENGHT 192

#define PUNISH_TYPE_KICK 1
#define PUNISH_TYPE_BAN 1

public Plugin myinfo = {
    name = "Anti fast respawn",
    author = "Dron-elektron",
    description = "Prevents the player from fast respawn after death when the player has changed his class",
    version = "0.4.1",
    url = ""
}

static ConVar g_pluginEnable = null;
static ConVar g_maxWarnings = null;
static ConVar g_punishType = null;
static ConVar g_freezeTime = null;
static ConVar g_banTime = null;

enum struct PlayerState {
    Handle punishTimer;
    int warnings;
}

static PlayerState g_playerStates[MAXPLAYERS + 1];

public void OnPluginStart() {
    LoadTranslations("common.phrases");
    LoadTranslations("anti-fast-respawn.phrases");
    HookEvent(EVENT_PLAYER_CHANGE_CLASS, Event_PlayerChangeClass);

    g_pluginEnable = CreateConVar("sm_afr_enable", "1", "Enable (1) or disable (0) plugin");
    g_maxWarnings = CreateConVar("sm_afr_max_warnings", "3", "Maximum warnings about fast respawn");
    g_punishType = CreateConVar("sm_afr_punish_type", "1", "Punish type for fast respawn (0 - freeze, 1 - kick, 2 - ban)");
    g_freezeTime = CreateConVar("sm_afr_freeze_time", "3", "Freeze time (in seconds) due fast respawn");
    g_banTime = CreateConVar("sm_afr_ban_time", "5", "Ban time (in minutes) due fast respawn");

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

    char targetName[MAX_NAME_LENGTH];
    int playerWarnings = g_playerStates[target].warnings;
    int maxWarnings = GetMaxWarnings();

    GetClientName(target, targetName, sizeof(targetName));
    ReplyToCommand(client, "%s%t", PLUGIN_PREFIX, "Warnings for player", targetName, playerWarnings, maxWarnings);
    LogAction(client, target, "%L: %t", client, "Warnings for player", targetName, playerWarnings, maxWarnings);

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

    char targetName[MAX_NAME_LENGTH];

    GetClientName(target, targetName, sizeof(targetName));
    ShowActivity2(client, PLUGIN_PREFIX, "%t", "Warnings for the player are reset to zero", targetName);
    LogAction(client, target, "%L: %t", client, "Warnings for the player are reset to zero", targetName);

    g_playerStates[target].warnings = 0;

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
        PunishPlayerByType(client);
    } else {
        char nickname[MAX_NAME_LENGTH];

        GetClientName(client, nickname, sizeof(nickname));
        PrintToChatAll("%s%t", PLUGIN_PREFIX, "Fast respawn detected", nickname, playerWarnings, maxWarnings);
        LogAction(-1, -1, "%t", "Fast respawn detected", nickname, playerWarnings, maxWarnings);
        FreezePlayer(client);
    }
}

void PunishPlayerByType(int client) {
    int punishType = GetPunishType();
    char reason[MAX_TEXT_LENGHT];

    Format(reason, sizeof(reason), "%s%t", PLUGIN_PREFIX, "Fast respawn forbidden");

    if (punishType == PUNISH_TYPE_KICK) {
        KickClient(client, reason);
    } else if (punishType == PUNISH_TYPE_BAN) {
        int banTime = GetBanTime();

        BanClient(client, banTime, BANFLAG_AUTHID, reason, reason);
    } else {
        char playerName[MAX_NAME_LENGTH];
        int playerWarnings = g_playerStates[client].warnings;

        GetClientName(client, playerName, sizeof(playerName));
        PrintToChatAll("%s%t", PLUGIN_PREFIX, "Player is abusing fast respawn", playerName, playerWarnings);
        LogAction(-1, -1, "%t", "Player is abusing fast respawn", playerName, playerWarnings);
        FreezePlayer(client);
    }
}

void FreezePlayer(int client) {
    int userId = GetClientUserId(client);
    int freezeTime = GetFreezeTime();

    ServerCommand(COMMAND_FREEZE_FORMAT, userId, freezeTime);
}

bool IsPluginEnabled() {
    return g_pluginEnable.IntValue == 1;
}

int GetMaxWarnings() {
    return g_maxWarnings.IntValue;
}

int GetPunishType() {
    return g_punishType.IntValue;
}

int GetFreezeTime() {
    return g_freezeTime.IntValue;
}

int GetBanTime() {
    return g_banTime.IntValue;
}
