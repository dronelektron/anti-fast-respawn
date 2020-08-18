#include <sourcemod>
#include <morecolors>

#define PLUGIN_PREFIX "[AFR] "
#define PLUGIN_PREFIX_COLOR "{cyan}"

#define USAGE_PREFIX "[AFR] Usage"
#define USAGE_COMMAND_WARNINGS "sm_afr_warnings <#userid|name>"
#define USAGE_COMMAND_RESET_WARNINGS "sm_afr_reset_warnings <#userid|name>"

#define COMMAND_FREEZE_FORMAT "sm_freeze #%d %d"

#define ITEM_SLOT_RESET_WARNINGS 1

#define EVENT_PLAYER_CHANGE_CLASS "player_changeclass"
#define EVENT_PLAYER_DEATH "player_death"
#define EVENT_PLAYER_SPAWN "player_spawn"
#define EVENT_ROUND_START "dod_round_start"
#define EVENT_ROUND_WIN "dod_round_win"

#define RESPAWN_THRESHOLD_MSEC 0.1
#define MAX_TEXT_LENGHT 192

#define PUNISH_TYPE_KICK 1
#define PUNISH_TYPE_BAN 1

public Plugin myinfo = {
    name = "Anti fast respawn",
    author = "Dron-elektron",
    description = "Prevents the player from fast respawn after death when the player has changed his class",
    version = "0.5.3",
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
    bool isKilled;

    void CleanUp() {
        delete this.punishTimer;

        this.warnings = 0;
        this.isKilled = false;
    }
}

static PlayerState g_playerStates[MAXPLAYERS + 1];
static bool g_isRoundEnd = false;

public void OnPluginStart() {
    LoadTranslations("common.phrases");
    LoadTranslations("anti-fast-respawn.phrases");

    HookEvent(EVENT_PLAYER_CHANGE_CLASS, Event_PlayerChangeClass);
    HookEvent(EVENT_PLAYER_DEATH, Event_PlayerDeath);
    HookEvent(EVENT_PLAYER_SPAWN, Event_PlayerSpawn);
    HookEvent(EVENT_ROUND_START, Event_RoundStart);
    HookEvent(EVENT_ROUND_WIN, Event_RoundWin);

    g_pluginEnable = CreateConVar("sm_afr_enable", "1", "Enable (1) or disable (0) plugin");
    g_maxWarnings = CreateConVar("sm_afr_max_warnings", "3", "Maximum warnings about fast respawn");
    g_punishType = CreateConVar("sm_afr_punish_type", "1", "Punish type for fast respawn (0 - freeze, 1 - kick, 2 - ban)");
    g_freezeTime = CreateConVar("sm_afr_freeze_time", "3", "Freeze time (in seconds) due fast respawn");
    g_banTime = CreateConVar("sm_afr_ban_time", "5", "Ban time (in minutes) due fast respawn");

    RegAdminCmd("sm_afr", Command_Menu, ADMFLAG_GENERIC);
    RegAdminCmd("sm_afr_warnings", Command_Warnings, ADMFLAG_GENERIC, USAGE_COMMAND_WARNINGS);
    RegAdminCmd("sm_afr_reset_warnings", Command_ResetWarnings, ADMFLAG_GENERIC, USAGE_COMMAND_RESET_WARNINGS);

    AutoExecConfig(true, "anti-fast-respawn");
}

public void OnPluginEnd() {
    UnhookEvent(EVENT_PLAYER_CHANGE_CLASS, Event_PlayerChangeClass);
    UnhookEvent(EVENT_PLAYER_DEATH, Event_PlayerDeath);
    UnhookEvent(EVENT_PLAYER_SPAWN, Event_PlayerSpawn);
    UnhookEvent(EVENT_ROUND_START, Event_RoundStart);
    UnhookEvent(EVENT_ROUND_WIN, Event_RoundWin);

    for (int i = 0; i <= MAXPLAYERS; i++) {
        g_playerStates[i].CleanUp();
    }
}

public void OnClientDisconnect(int client) {
    g_playerStates[client].CleanUp();
}

public void Event_PlayerChangeClass(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    if (g_playerStates[client].isKilled) {
        CreatePunishTimer(client);
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    g_playerStates[client].isKilled = true;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    g_playerStates[client].isKilled = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    g_isRoundEnd = false;
}

public void Event_RoundWin(Event event, const char[] name, bool dontBroadcast) {
    g_isRoundEnd = true;
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

public Action Command_Menu(int client, int args) {
    CreatePlayersMenu(client);

    return Plugin_Handled;
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

    ResetWarnings(client, target);

    return Plugin_Handled;
}

public int MenuHandler_Players(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        char userIdStr[MAX_TEXT_LENGHT];

        menu.GetItem(param2, userIdStr, sizeof(userIdStr));

        int userId = StringToInt(userIdStr);

        CreatePlayerInfoMenu(param1, userId);
    } else if (action == MenuAction_End) {
        delete menu;
    }
}

public int MenuHandler_PlayerInfo(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        if (param2 == ITEM_SLOT_RESET_WARNINGS) {
            char userIdStr[MAX_TEXT_LENGHT];

            menu.GetItem(param2, userIdStr, sizeof(userIdStr));

            int userId = StringToInt(userIdStr);
            int target = GetClientOfUserId(userId);

            if (target == 0) {
                PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Player no longer available");
            } else {
                ResetWarnings(param1, target);
            }
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }
}

void CreatePlayersMenu(int client) {
    Menu menu = new Menu(MenuHandler_Players);
    char title[MAX_TEXT_LENGHT];

    Format(title, sizeof(title), "%s %T", PLUGIN_PREFIX, "menu", client);

    menu.SetTitle(title);

    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientConnected(i)) {
            continue;
        }

        int userId = GetClientUserId(i);
        char userIdStr[MAX_NAME_LENGTH];
        char clientName[MAX_NAME_LENGTH];

        IntToString(userId, userIdStr, sizeof(userIdStr));
        GetClientName(i, clientName, sizeof(clientName));

        menu.AddItem(userIdStr, clientName);
    }

    menu.Display(client, MENU_TIME_FOREVER);
}

void CreatePlayerInfoMenu(int client, int userId) {
    int target = GetClientOfUserId(userId);

    if (target == 0) {
        return;
    }

    Menu menu = new Menu(MenuHandler_PlayerInfo);
    char targetName[MAX_NAME_LENGTH];

    GetClientName(target, targetName, sizeof(targetName));

    menu.SetTitle(targetName);

    char userIdStr[MAX_TEXT_LENGHT];
    char warningsItem[MAX_TEXT_LENGHT];
    char resetWarnings[MAX_TEXT_LENGHT];
    int playerWarnings = g_playerStates[target].warnings;
    int maxWarnings = GetMaxWarnings();

    Format(warningsItem, sizeof(warningsItem), "%T", "Warnings", client, playerWarnings, maxWarnings);
    Format(resetWarnings, sizeof(resetWarnings), "%T", "Reset warnings", client);
    IntToString(userId, userIdStr, sizeof(userIdStr));

    menu.AddItem("Warnings", warningsItem, ITEMDRAW_DISABLED);
    menu.AddItem(userIdStr, resetWarnings);
    menu.Display(client, MENU_TIME_FOREVER);
}

void CreatePunishTimer(int client) {
    if (!IsPluginEnabled()) {
        return;
    }

    if (g_isRoundEnd) {
        return;
    }

    if (g_playerStates[client].punishTimer == null) {
        int userId = GetClientUserId(client);

        g_playerStates[client].punishTimer = CreateTimer(RESPAWN_THRESHOLD_MSEC, Timer_Punish, userId);
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
        CPrintToChatAll("%s%s%t", PLUGIN_PREFIX_COLOR, PLUGIN_PREFIX, "Fast respawn detected", nickname, playerWarnings, maxWarnings);
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
        CPrintToChatAll("%s%s%t", PLUGIN_PREFIX_COLOR, PLUGIN_PREFIX, "Player is abusing fast respawn", playerName, playerWarnings);
        LogAction(-1, -1, "%t", "Player is abusing fast respawn", playerName, playerWarnings);
        FreezePlayer(client);
    }
}

void FreezePlayer(int client) {
    int userId = GetClientUserId(client);
    int freezeTime = GetFreezeTime();

    ServerCommand(COMMAND_FREEZE_FORMAT, userId, freezeTime);
}

void ResetWarnings(int client, int target) {
    char targetName[MAX_NAME_LENGTH];

    GetClientName(target, targetName, sizeof(targetName));
    ShowActivity2(client, PLUGIN_PREFIX, "%t", "Warnings for the player are reset to zero", targetName);
    LogAction(client, target, "%L: %t", client, "Warnings for the player are reset to zero", targetName);

    g_playerStates[target].warnings = 0;
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
