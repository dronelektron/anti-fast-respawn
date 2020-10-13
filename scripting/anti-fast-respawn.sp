#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <sdkhooks>

#define PLUGIN_PREFIX "[AFR] "
#define PLUGIN_PREFIX_COLORED "{cyan}[AFR] "

#define USAGE_PREFIX_COLORED "{cyan}[AFR] {default}Usage: "

#define LOG_PREFIX_WARNINGS_SAVE "Warnings not saved: "
#define LOG_PREFIX_WARNINGS_LOAD "Warnings not loaded: "

#define USAGE_COMMAND_WARNINGS "sm_afr_warnings <#userid|name>"
#define USAGE_COMMAND_RESET_WARNINGS "sm_afr_reset_warnings <#userid|name>"
#define USAGE_COMMAND_REMOVE_WARNING "sm_afr_remove_warning <#userid|name>"

#define PLAYER_OPTION_RESET_WARNINGS "0"
#define PLAYER_OPTION_REMOVE_WARNING "1"

#define TEAM_SPECTATOR 1
#define TEAM_ALLIES 2
#define TEAM_AXIS 3

#define RESPAWN_THRESHOLD_SECONDS 0.1
#define PUNISH_TIMER_INTERVAL_SECONDS 1.0
#define DAMAGE_MESSAGE_DELAY_SECONDS 1.0
#define MAX_TEXT_LENGHT 192
#define MAX_AUTH_ID_LENGHT 65

#define PUNISH_TYPE_KICK 1
#define PUNISH_TYPE_BAN 2

#define SOUND_BLOCK "physics/glass/glass_impact_bullet4.wav"
#define SOUND_UNBLOCK "physics/glass/glass_bottle_break2.wav"
#define SOUND_DAMAGE_MESSAGE "buttons/button8.wav"

#define COLOR_BLOCK 0x0080FFFF // 0 128 255 255
#define COLOR_UNBLOCK 0xFFFFFFFF // 255 255 255 255

public Plugin myinfo = {
    name = "Anti fast respawn",
    author = "Dron-elektron",
    description = "Prevents fast respawn if a player has changed his class after death near respawn zone",
    version = "0.13.0",
    url = ""
}

static ConVar g_enablePlugin = null;
static ConVar g_maxWarnings = null;
static ConVar g_punishType = null;
static ConVar g_freezeTime = null;
static ConVar g_banTime = null;
static ConVar g_minSpectatorTime = null;
static ConVar g_minActivePlayers = null;
static ConVar g_enableWarningsSave = null;
static ConVar g_blockDamage = null;

enum struct PlayerState {
    Handle checkerTimer;
    Handle spectatorTimer;
    Handle punishTimer;
    Handle damageMessageTimer;
    int warnings;
    bool isKilled;
    int lastTeam;
    int punishmentSeconds;
    int targetId;

    void CleanUp() {
        delete this.checkerTimer;
        delete this.spectatorTimer;
        delete this.punishTimer;
        delete this.damageMessageTimer;

        this.warnings = 0;
        this.isKilled = false;
        this.lastTeam = 0;
        this.punishmentSeconds = 0;
        this.targetId = 0;
    }
}

static PlayerState g_playerStates[MAXPLAYERS + 1];
static bool g_isRoundEnd = false;
static StringMap g_savedWarnings = null;

public void OnPluginStart() {
    LoadTranslations("anti-fast-respawn.phrases");

    HookEvent("player_changeclass", Event_PlayerChangeClass);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("dod_round_start", Event_RoundStart);
    HookEvent("dod_round_win", Event_RoundWin);

    g_enablePlugin = CreateConVar("sm_afr_enable", "1", "Enable (1) or disable (0) plugin");
    g_maxWarnings = CreateConVar("sm_afr_max_warnings", "3", "Maximum warnings about fast respawn");
    g_punishType = CreateConVar("sm_afr_punish_type", "1", "Punish type for fast respawn (0 - freeze, 1 - kick, 2 - ban)");
    g_freezeTime = CreateConVar("sm_afr_freeze_time", "1", "Freeze time (in seconds) due fast respawn");
    g_banTime = CreateConVar("sm_afr_ban_time", "5", "Ban time (in minutes) due fast respawn");
    g_minSpectatorTime = CreateConVar("sm_afr_min_spectator_time", "5", "Minimum time (in seconds) in spectator team to not be punished for fast respawn");
    g_minActivePlayers = CreateConVar("sm_afr_min_active_players", "4", "Minimum amount of active players to enable protection");
    g_enableWarningsSave = CreateConVar("sm_afr_enable_warnings_save", "1", "Enable (1) or disable (0) warnings save");
    g_blockDamage = CreateConVar("sm_afr_block_damage", "1", "Enable (1) or disable (0) damage blocking when player is punished");
    g_savedWarnings = CreateTrie();

    RegAdminCmd("sm_afr", Command_Menu, ADMFLAG_GENERIC);
    RegAdminCmd("sm_afr_warnings", Command_Warnings, ADMFLAG_GENERIC, USAGE_COMMAND_WARNINGS);
    RegAdminCmd("sm_afr_reset_warnings", Command_ResetWarnings, ADMFLAG_GENERIC, USAGE_COMMAND_RESET_WARNINGS);
    RegAdminCmd("sm_afr_remove_warning", Command_RemoveWarning, ADMFLAG_GENERIC, USAGE_COMMAND_REMOVE_WARNING);

    AutoExecConfig(true, "anti-fast-respawn");
}

public void OnPluginEnd() {
    for (int i = 0; i <= MAXPLAYERS; i++) {
        g_playerStates[i].CleanUp();
    }

    CloseHandle(g_savedWarnings);
}

public void OnMapStart() {
    PrecacheSound(SOUND_BLOCK, true);
    PrecacheSound(SOUND_UNBLOCK, true);
    PrecacheSound(SOUND_DAMAGE_MESSAGE, true);
}

public void OnMapEnd() {
    g_savedWarnings.Clear();

    LogMessage("All saved warnings was deleted");
}

public void OnClientAuthorized(int client, const char[] auth) {
    LoadPlayerWarnings(client);
}

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int client) {
    SDKUnhook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
    SavePlayerWarnings(client);
    g_playerStates[client].CleanUp();
}

public void Event_PlayerChangeClass(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    if (!g_playerStates[client].isKilled) {
        return;
    }

    if (g_playerStates[client].punishTimer != null) {
        return;
    }

    CreateCheckerTimer(client);
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

    if (g_playerStates[client].punishTimer != null) {
        BlockPlayer(client);
    }
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

public Action Timer_Checker(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    if (IsPlayerAlive(client)) {
        PunishPlayer(client);
    }

    g_playerStates[client].checkerTimer = null;

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

public Action Timer_Punish(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    int punishmentSeconds = g_playerStates[client].punishmentSeconds;

    if (punishmentSeconds > 0) {
        PrintHintText(client, "%t", "You was punished", punishmentSeconds);

        g_playerStates[client].punishmentSeconds--;

        return Plugin_Continue;
    }

    g_playerStates[client].punishTimer = null;

    UnblockPlayer(client);
    PrintHintText(client, "%t", "You are free now");

    return Plugin_Stop;
}

public Action Timer_DamageMessage(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    g_playerStates[client].damageMessageTimer = null;

    return Plugin_Handled;
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
    if (!IsBlockDamage()) {
        return Plugin_Continue;
    }

    if (!IsClientIndexValid(attacker)) {
        return Plugin_Continue;
    }

    if (g_playerStates[attacker].punishTimer == null) {
        return Plugin_Continue;
    }

    if (g_playerStates[attacker].damageMessageTimer == null) {
        int userId = GetClientUserId(attacker);

        g_playerStates[attacker].damageMessageTimer = CreateTimer(DAMAGE_MESSAGE_DELAY_SECONDS, Timer_DamageMessage, userId);

        CPrintToChat(attacker, "%s%t", PLUGIN_PREFIX_COLORED, "You cannot attack");
        EmitSoundToClient(attacker, SOUND_DAMAGE_MESSAGE);
    }

    return Plugin_Handled;
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
        CReplyToCommand(client, "%s%s", USAGE_PREFIX_COLORED, USAGE_COMMAND_WARNINGS);

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
        CReplyToCommand(client, "%s%s", USAGE_PREFIX_COLORED, USAGE_COMMAND_RESET_WARNINGS);

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

public Action Command_RemoveWarning(int client, int args) {
    if (args < 1) {
        CReplyToCommand(client, "%s%s", USAGE_PREFIX_COLORED, USAGE_COMMAND_REMOVE_WARNING);

        return Plugin_Handled;
    }

    char name[MAX_NAME_LENGTH];

    GetCmdArg(1, name, sizeof(name));

    int target = FindTarget(client, name);

    if (target == -1) {
        return Plugin_Handled;
    }

    RemoveWarning(client, target);

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

void CreateCheckerTimer(int client) {
    if (!IsProtectionEnabled()) {
        return;
    }

    if (g_playerStates[client].checkerTimer == null) {
        int userId = GetClientUserId(client);

        g_playerStates[client].checkerTimer = CreateTimer(RESPAWN_THRESHOLD_SECONDS, Timer_Checker, userId);
    }
}

void CreateSpectatorTimer(int client) {
    if (!IsProtectionEnabled()) {
        return;
    }

    if (g_playerStates[client].punishTimer != null) {
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
        BlockPlayer(client);
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
        BlockPlayer(client);
    }
}

void BlockPlayer(int client) {
    if (g_playerStates[client].punishTimer == null) {
        int userId = GetClientUserId(client);

        g_playerStates[client].punishmentSeconds = GetFreezeTime();
        g_playerStates[client].punishTimer = CreateTimer(PUNISH_TIMER_INTERVAL_SECONDS, Timer_Punish, userId, TIMER_REPEAT);

        EmitSoundAtEyePosition(client, SOUND_BLOCK);
    }

    SetEntityMoveType(client, MOVETYPE_NONE);
    SetEntityRenderColorHex(client, COLOR_BLOCK);
}

void UnblockPlayer(int client) {
    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityRenderColorHex(client, COLOR_UNBLOCK);
    EmitSoundAtEyePosition(client, SOUND_UNBLOCK);
}

void EmitSoundAtEyePosition(int client, const char[] sound) {
    float eyePos[3];

    GetClientEyePosition(client, eyePos);
    EmitAmbientSound(sound, eyePos, client, SNDLEVEL_RAIDSIREN);
}

void SetEntityRenderColorHex(int client, int color) {
    int red = (color >> 24) & 0xFF;
    int green = (color >> 16) & 0xFF;
    int blue = (color >> 8) & 0xFF;
    int alpha = color & 0xFF;

    SetEntityRenderColor(client, red, green, blue, alpha);
}

void ResetWarnings(int client, int target) {
    if (g_playerStates[target].warnings == 0) {
        CReplyToCommand(client, "%s%t", PLUGIN_PREFIX_COLORED, "Player has no warnings", target);
        LogAction(client, target, "\"%L\" tried to reset warnings for \"%L\"", client, target);
    } else {
        CPrintToChatAll("%s%t", PLUGIN_PREFIX_COLORED, "Warnings cleared", client, target);
        LogAction(client, target, "\"%L\" reset warnings for \"%L\"", client, target);

        g_playerStates[target].warnings = 0;
    }
}

void RemoveWarning(int client, int target) {
    if (g_playerStates[target].warnings == 0) {
        CReplyToCommand(client, "%s%t", PLUGIN_PREFIX_COLORED, "Player has no warnings", target);
        LogAction(client, target, "\"%L\" tried to remove one warning for \"%L\"", client, target);
    } else {
        CPrintToChatAll("%s%t", PLUGIN_PREFIX_COLORED, "Removed warning", client, target);
        LogAction(client, target, "\"%L\" removed one warning for \"%L\"", client, target);

        g_playerStates[target].warnings--;
    }
}

void SavePlayerWarnings(int client) {
    if (!IsClientAuthorized(client)) {
        LogMessage("%s\"%L\" is not authorized", LOG_PREFIX_WARNINGS_SAVE, client);

        return;
    }

    if (!IsWarningsSaveEnabled()) {
        LogMessage("%sFeature is disabled", LOG_PREFIX_WARNINGS_SAVE);

        return;
    }

    int maxWarnings = GetMaxWarnings();
    int playerWarnings = g_playerStates[client].warnings;

    if (playerWarnings == 0 || playerWarnings > maxWarnings) {
        LogMessage("%s\"%L\" has zero warnings or was punished", LOG_PREFIX_WARNINGS_SAVE, client);

        return;
    }

    char authId[65];

    if (!GetClientAuthId(client, AuthId_Steam3, authId, sizeof(authId), true)) {
        LogError("%sUnable to get auth ID of \"%L\"", LOG_PREFIX_WARNINGS_SAVE, client);

        return;
    }

    g_savedWarnings.SetValue(authId, playerWarnings, true);

    LogMessage("Saved %d warning(s) for \"%L\"", playerWarnings, client);
}

void LoadPlayerWarnings(int client) {
    if (!IsWarningsSaveEnabled()) {
        LogMessage("%sFeature is disabled", LOG_PREFIX_WARNINGS_LOAD);

        return;
    }

    char authId[MAX_AUTH_ID_LENGHT];

    if (!GetClientAuthId(client, AuthId_Steam3, authId, sizeof(authId), true)) {
        LogError("%sUnable to get auth ID of \"%L\"", LOG_PREFIX_WARNINGS_LOAD, client);

        return;
    }

    int savedWarnings;

    if (g_savedWarnings.GetValue(authId, savedWarnings)) {
        g_playerStates[client].warnings += savedWarnings;
        g_savedWarnings.Remove(authId);

        LogMessage("Loaded %d warning(s) for \"%L\"", savedWarnings, client);
    } else {
        LogMessage("%sSaved warnings for \"%L\" not found", LOG_PREFIX_WARNINGS_LOAD, client);
    }
}

bool IsClientIndexValid(int client) {
    return client >= 1 && client <= MAXPLAYERS;
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
    return g_enablePlugin.IntValue == 1;
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

int IsWarningsSaveEnabled() {
    return g_enableWarningsSave.IntValue == 1;
}

bool IsBlockDamage() {
    return g_blockDamage.IntValue == 1;
}
