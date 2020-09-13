#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define PLUGIN_PREFIX "[AFR] "
#define PLUGIN_PREFIX_COLORED "{cyan}[AFR] "

#define USAGE_PREFIX_COLORED "{cyan}[AFR] {default}Usage"

#define USAGE_COMMAND_WARNINGS "sm_afr_warnings <#userid|name>"
#define USAGE_COMMAND_RESET_WARNINGS "sm_afr_reset_warnings <#userid|name>"

#define PLAYER_OPTION_RESET_WARNINGS "0"
#define PLAYER_OPTION_REMOVE_WARNING "1"

#define TEAM_SPECTATOR 1
#define TEAM_ALLIES 2
#define TEAM_AXIS 3

#define RESPAWN_THRESHOLD_MSEC 0.1
#define MAX_TEXT_LENGHT 192
#define COMMAND_FREEZE_FORMAT "sm_freeze #%d %d"

#define PUNISH_TYPE_KICK 1
#define PUNISH_TYPE_BAN 2

public Plugin myinfo = {
    name = "Anti fast respawn",
    author = "Dron-elektron",
    description = "Prevents a player from fast respawn if player changed his class near respawn",
    version = "0.9.0",
    url = ""
}

static ConVar g_pluginEnable = null;
static ConVar g_maxWarnings = null;
static ConVar g_punishType = null;
static ConVar g_freezeTime = null;
static ConVar g_banTime = null;
static ConVar g_minSpectatorTime = null;
static ConVar g_minActivePlayers = null;

enum struct PlayerState {
    Handle punishTimer;
    Handle spectatorTimer;
    int warnings;
    bool isKilled;
    int lastTeam;
    int targetId;

    void CleanUp() {
        delete this.punishTimer;
        delete this.spectatorTimer;

        this.warnings = 0;
        this.isKilled = false;
        this.lastTeam = 0;
        this.targetId = 0;
    }
}

static PlayerState g_playerStates[MAXPLAYERS + 1];
static bool g_isRoundEnd = false;

public void OnPluginStart() {
    LoadTranslations("anti-fast-respawn.phrases");

    HookEvent("player_changeclass", Event_PlayerChangeClass);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("dod_round_start", Event_RoundStart);
    HookEvent("dod_round_win", Event_RoundWin);

    g_pluginEnable = CreateConVar("sm_afr_enable", "1", "Enable (1) or disable (0) plugin");
    g_maxWarnings = CreateConVar("sm_afr_max_warnings", "3", "Maximum warnings about fast respawn");
    g_punishType = CreateConVar("sm_afr_punish_type", "1", "Punish type for fast respawn (0 - freeze, 1 - kick, 2 - ban)");
    g_freezeTime = CreateConVar("sm_afr_freeze_time", "1", "Freeze time (in seconds) due fast respawn");
    g_banTime = CreateConVar("sm_afr_ban_time", "5", "Ban time (in minutes) due fast respawn");
    g_minSpectatorTime = CreateConVar("sm_afr_min_spectator_time", "5", "Minimum time (in seconds) in spectator team to not be punished for fast respawn");
    g_minActivePlayers = CreateConVar("sm_afr_min_active_players", "4", "Minimum amount of active players to enable protection");

    RegAdminCmd("sm_afr", Command_Menu, ADMFLAG_GENERIC);
    RegAdminCmd("sm_afr_warnings", Command_Warnings, ADMFLAG_GENERIC, USAGE_COMMAND_WARNINGS);
    RegAdminCmd("sm_afr_reset_warnings", Command_ResetWarnings, ADMFLAG_GENERIC, USAGE_COMMAND_RESET_WARNINGS);

    AutoExecConfig(true, "anti-fast-respawn");
}

public void OnPluginEnd() {
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

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int team = event.GetInt("team");
    int client = GetClientOfUserId(userId);

    if (team == TEAM_SPECTATOR) {
        if (g_playerStates[client].isKilled) {
            CreateSpectatorTimer(client);
        }
    } else {
        delete g_playerStates[client].spectatorTimer;

        int oldTeam = g_playerStates[client].lastTeam;
        bool alliesToAxis = oldTeam == TEAM_ALLIES && team == TEAM_AXIS;
        bool axisToAllies = oldTeam == TEAM_AXIS && team == TEAM_ALLIES;

        if (alliesToAxis || axisToAllies) {
            g_playerStates[client].isKilled = false;
        }

        g_playerStates[client].lastTeam = team;
    }
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

public Action Timer_Spectator(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    if (!IsPlayerAlive(client)) {
        g_playerStates[client].isKilled = false;
    }

    g_playerStates[client].spectatorTimer = null;

    return Plugin_Continue;
}

public Action Command_Menu(int client, int args) {
    if (client > 0 && args < 1) {
        CreatePlayersMenu(client);
    } else {
        PrintToServer("%s%s", PLUGIN_PREFIX, "Menu is not supported for console");
    }

    return Plugin_Handled;
}

public Action Command_Warnings(int client, int args) {
    if (args < 1) {
        CReplyToCommand(client, "%s: %s", USAGE_PREFIX_COLORED, USAGE_COMMAND_WARNINGS);

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

    CReplyToCommand(client, "%s%t", PLUGIN_PREFIX_COLORED, "Warnings for player", target, playerWarnings, maxWarnings);
    LogAction(client, target, "\"%L\" checked warnings for \"%L\" (%d/%d)", client, target, playerWarnings, maxWarnings);

    return Plugin_Handled;
}

public Action Command_ResetWarnings(int client, int args) {
    if (args < 1) {
        CReplyToCommand(client, "%s: %s", USAGE_PREFIX_COLORED, USAGE_COMMAND_RESET_WARNINGS);

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
    switch (action) {
        case MenuAction_Select: {
            char userIdStr[MAX_TEXT_LENGHT];

            menu.GetItem(param2, userIdStr, sizeof(userIdStr));

            int targetId = StringToInt(userIdStr);

            CreatePlayerOptionMenu(param1, targetId);
        }

        case MenuAction_End: {
            delete menu;
        }
    }
}

public int MenuHandler_PlayerOption(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char option[MAX_TEXT_LENGHT];

            menu.GetItem(param2, option, sizeof(option));

            int targetId = g_playerStates[param1].targetId
            int target = GetClientOfUserId(targetId);

            if (target == 0) {
                CPrintToChat(param1, "%s%t", PLUGIN_PREFIX_COLORED, "Player no longer available");
            } else {
                if (StrEqual(option, PLAYER_OPTION_RESET_WARNINGS)) {
                    ResetWarnings(param1, target);
                } else if (StrEqual(option, PLAYER_OPTION_REMOVE_WARNING)) {
                    RemoveWarning(param1, target);
                }
            }
        }

        case MenuAction_Cancel: {
            if (param2 == MenuCancel_ExitBack) {
                CreatePlayersMenu(param1);
            }
        }

        case MenuAction_End: {
            delete menu;
        }
    }
}

void CreatePlayersMenu(int client) {
    Menu menu = new Menu(MenuHandler_Players);

    menu.SetTitle("%s%T", PLUGIN_PREFIX, "Menu", client);

    AddPlayersToMenu(menu);

    menu.Display(client, MENU_TIME_FOREVER);
}

void CreatePlayerOptionMenu(int client, int targetId) {
    int target = GetClientOfUserId(targetId);

    if (target == 0) {
        CPrintToChat(client, "%s%t", PLUGIN_PREFIX_COLORED, "Player no longer available");

        return;
    }

    g_playerStates[client].targetId = targetId;

    Menu menu = new Menu(MenuHandler_PlayerOption);
    int style;

    menu.SetTitle("%N", target);

    if (g_playerStates[target].warnings > 0) {
        style = ITEMDRAW_DEFAULT;
    } else {
        style = ITEMDRAW_DISABLED;
    }

    AddFormattedMenuItem(menu, style, PLAYER_OPTION_RESET_WARNINGS, "%T", "Reset warnings", client);
    AddFormattedMenuItem(menu, style, PLAYER_OPTION_REMOVE_WARNING, "%T", "Remove warning", client);

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void AddPlayersToMenu(Menu menu) {
    for (int client = 1; client <= MaxClients; client++) {
        if (!IsClientConnected(client)) {
            continue;
        }

        int userId = GetClientUserId(client);
        char userIdStr[MAX_NAME_LENGTH];
        int playerWarnings = g_playerStates[client].warnings;

        IntToString(userId, userIdStr, sizeof(userIdStr));
        AddFormattedMenuItem(menu, ITEMDRAW_DEFAULT, userIdStr, "%N (%d)", client, playerWarnings);
    }
}

void AddFormattedMenuItem(Menu menu, int style, const char[] option, const char[] format, any ...) {
    char text[MAX_TEXT_LENGHT];

    VFormat(text, sizeof(text), format, 5);
    menu.AddItem(option, text, style);
}

void CreatePunishTimer(int client) {
    if (!IsProtectionEnabled()) {
        return;
    }

    if (g_playerStates[client].punishTimer == null) {
        int userId = GetClientUserId(client);

        g_playerStates[client].punishTimer = CreateTimer(RESPAWN_THRESHOLD_MSEC, Timer_Punish, userId);
    }
}

void CreateSpectatorTimer(int client) {
    if (!IsProtectionEnabled()) {
        return;
    }

    if (g_playerStates[client].spectatorTimer == null) {
        int userId = GetClientUserId(client);
        float minSpectatorTime = GetMinSpectatorTime();

        g_playerStates[client].spectatorTimer = CreateTimer(minSpectatorTime, Timer_Spectator, userId);
    }
}

void PunishPlayer(int client) {
    g_playerStates[client].warnings++;

    int playerWarnings = g_playerStates[client].warnings;
    int maxWarnings = GetMaxWarnings();

    if (playerWarnings > maxWarnings) {
        PunishPlayerByType(client);
    } else {
        CPrintToChatAll("%s%t", PLUGIN_PREFIX_COLORED, "Fast respawn detected", client, playerWarnings, maxWarnings);
        CPrintToChat(client, "%s%t", PLUGIN_PREFIX_COLORED, "Anti fast respawn advice");
        LogAction(-1, -1, "\"%L\" fast respawned (%d/%d)", client, playerWarnings, maxWarnings);
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
        int playerWarnings = g_playerStates[client].warnings;

        CPrintToChatAll("%s%t", PLUGIN_PREFIX_COLORED, "Player is abusing fast respawn", client, playerWarnings);
        LogAction(-1, -1, "\"%L\" is abusing fast respawn (%d times)", client, playerWarnings);
        FreezePlayer(client);
    }
}

void FreezePlayer(int client) {
    int userId = GetClientUserId(client);
    int freezeTime = GetFreezeTime();

    ServerCommand(COMMAND_FREEZE_FORMAT, userId, freezeTime);
}

void ResetWarnings(int client, int target) {
    if (g_playerStates[target].warnings == 0) {
        CReplyToCommand(client, "%s%t", PLUGIN_PREFIX_COLORED, "Player no longer has a warnings", target);
        LogAction(client, target, "\"%L\" tried to reset warnings for \"%L\"", client, target);
    } else {
        CPrintToChatAll("%s%t", PLUGIN_PREFIX_COLORED, "Warnings for the player are reset to zero", target);
        LogAction(client, target, "\"%L\" reset warnings for \"%L\"", client, target);

        g_playerStates[target].warnings = 0;
    }
}

void RemoveWarning(int client, int target) {
    if (g_playerStates[target].warnings == 0) {
        CReplyToCommand(client, "%s%t", PLUGIN_PREFIX_COLORED, "Player no longer has a warnings", target);
        LogAction(client, target, "\"%L\" tried to remove one warning for \"%L\"", client, target);
    } else {
        CPrintToChatAll("%s%t", PLUGIN_PREFIX_COLORED, "Removed warning", target);
        LogAction(client, target, "\"%L\" removed one warning for \"%L\"", client, target);

        g_playerStates[target].warnings--;
    }
}

bool IsProtectionEnabled() {
    if (!IsPluginEnabled() || g_isRoundEnd) {
        return false;
    }

    int activePlayers = GetActivePlayers();
    int minActivePlayers = GetMinActivePlayers();

    if (activePlayers < minActivePlayers) {
        return false;
    }

    return true;
}

int GetActivePlayers() {
    return GetTeamClientCount(TEAM_ALLIES) + GetTeamClientCount(TEAM_AXIS);
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

float GetMinSpectatorTime() {
    return g_minSpectatorTime.FloatValue;
}

int GetMinActivePlayers() {
    return g_minActivePlayers.IntValue;
}
