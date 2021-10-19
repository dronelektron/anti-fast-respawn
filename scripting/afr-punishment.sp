#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <afr>
#include <afr-punishment>

#define SOUND_BLOCK "physics/glass/glass_impact_bullet4.wav"
#define SOUND_UNBLOCK "physics/glass/glass_bottle_break2.wav"

#define COLOR_BLOCK 0x0080FFFF // 0 128 255 255
#define COLOR_UNBLOCK 0xFFFFFFFF // 255 255 255 255

public Plugin myinfo = {
    name = "Anti fast respawn (punishment)",
    author = PLUGIN_AUTHOR,
    description = "Punishes the player for fast respawn",
    version = PLUGIN_VERSION,
    url = ""
}

enum PunishType {
    PunishType_Freeze,
    PunishType_Kick,
    PunishType_Ban
}

static const float PUNISH_TIMER_INTERVAL = 1.0;

static int g_warnings[MAXPLAYERS + 1] = {0, ...};
static int g_punishmentSeconds[MAXPLAYERS + 1] = {0, ...};
static int g_lastTeam[MAXPLAYERS + 1] = {0, ...};
static Handle g_punishmentTimer[MAXPLAYERS + 1] = {null, ...};
static Handle g_spectatorTimer[MAXPLAYERS + 1] = {null, ...};

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int errMax) {
    CreateNative("Afr_GetMaxWarnings", Native_GetMaxWarnings);
    CreateNative("Afr_GetWarnings", Native_GetWarnings);
    CreateNative("Afr_SetWarnings", Native_SetWarnings);
    CreateNative("Afr_IsPlayerPunished", Native_IsPlayerPunished);
    CreateNative("Afr_PrintWarnings", Native_PrintWarnings);
    CreateNative("Afr_ResetWarnings", Native_ResetWarnings);
    CreateNative("Afr_RemoveWarning", Native_RemoveWarning);

    return APLRes_Success;
}

public void OnPluginStart() {
    LoadTranslations("anti-fast-respawn.phrases");

    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_team", Event_PlayerTeam);
}

public void OnMapStart() {
    PrecacheSound(SOUND_BLOCK, true);
    PrecacheSound(SOUND_UNBLOCK, true);
}

public void OnClientConnected(int client) {
    g_warnings[client] = 0;
    g_punishmentSeconds[client] = 0;
    g_punishmentTimer[client] = null;
}

public void OnPlayerFastRespawned(int client) {
    PunishPlayer(client);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    if (Afr_IsPlayerPunished(client)) {
        BlockPlayer(client);
    }
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int newTeam = event.GetInt("team");
    int client = GetClientOfUserId(userId);

    if (newTeam == TEAM_SPECTATOR) {
        if (Afr_IsPlayerKilled(client)) {
            CreateSpectatorTimer(client);
        }
    } else {
        delete g_spectatorTimer[client];

        int oldTeam = g_lastTeam[client];
        bool alliesToAxis = oldTeam == TEAM_ALLIES && newTeam == TEAM_AXIS;
        bool axisToAllies = oldTeam == TEAM_AXIS && newTeam == TEAM_ALLIES;

        if (alliesToAxis || axisToAllies) {
            Afr_SetPlayerKilled(client, false);
        }

        g_lastTeam[client] = newTeam;
    }
}

public Action Timer_Punish(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    int punishmentSeconds = g_punishmentSeconds[client];

    if (punishmentSeconds > 0) {
        PrintHintText(client, "%t", "You was punished", punishmentSeconds);

        g_punishmentSeconds[client]--;

        return Plugin_Continue;
    }

    g_punishmentTimer[client] = null;

    UnblockPlayer(client);
    PrintHintText(client, "%t", "You are free now");

    return Plugin_Stop;
}

public Action Timer_Spectator(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    if (!IsPlayerAlive(client)) {
        Afr_SetPlayerKilled(client, false);
    }

    g_spectatorTimer[client] = null;

    return Plugin_Continue;
}

static void CreateSpectatorTimer(int client) {
    if (!Afr_IsProtectionEnabled()) {
        return;
    }

    if (Afr_IsPlayerPunished(client)) {
        return;
    }

    if (g_spectatorTimer[client] == null) {
        int userId = GetClientUserId(client);
        float minSpectatorTime = GetMinSpectatorTime();

        g_spectatorTimer[client] = CreateTimer(minSpectatorTime, Timer_Spectator, userId);
    }
}

static void PunishPlayer(int client) {
    if (Afr_IsPlayerPunished(client)) {
        return;
    }

    g_warnings[client]++;

    int playerWarnings = g_warnings[client];
    int maxWarnings = GetMaxWarnings();

    if (playerWarnings > maxWarnings) {
        PunishPlayerByType(client);
    } else {
        CPrintToChatAll("%s%t", PREFIX_COLORED, "Fast respawn detected", client, playerWarnings, maxWarnings);
        CPrintToChat(client, "%s%t", PREFIX_COLORED, "Anti fast respawn advice");
        LogAction(-1, -1, "\"%L\" fast respawned (%d/%d)", client, playerWarnings, maxWarnings);
        BlockPlayer(client);
    }
}

static void PunishPlayerByType(int client) {
    PunishType punishType = view_as<PunishType>(GetPunishType());
    char reason[MAX_TEXT_BUFFER_LENGTH];

    Format(reason, sizeof(reason), "%s%T", PREFIX, "Fast respawn forbidden", client);

    switch (punishType) {
        case PunishType_Freeze: {
            int playerWarnings = g_warnings[client];

            CPrintToChatAll("%s%t", PREFIX_COLORED, "Player is abusing fast respawn", client, playerWarnings);
            LogAction(-1, -1, "\"%L\" is abusing fast respawn (%d times)", client, playerWarnings);
            BlockPlayer(client);
        }

        case PunishType_Kick: {
            KickClient(client, reason);
        }

        case PunishType_Ban: {
            int banTime = GetBanTime();

            BanClient(client, banTime, BANFLAG_AUTHID, reason, reason);
        }
    }
}

static void BlockPlayer(int client) {
    if (!Afr_IsPlayerPunished(client)) {
        int userId = GetClientUserId(client);

        g_punishmentSeconds[client] = GetFreezeTime();
        g_punishmentTimer[client] = CreateTimer(PUNISH_TIMER_INTERVAL, Timer_Punish, userId, TIMER_REPEAT);

        EmitSoundAtEyePosition(client, SOUND_BLOCK);
    }

    SetEntityMoveType(client, MOVETYPE_NONE);
    SetEntityRenderColorHex(client, COLOR_BLOCK);
}

static void UnblockPlayer(int client) {
    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityRenderColorHex(client, COLOR_UNBLOCK);
    EmitSoundAtEyePosition(client, SOUND_UNBLOCK);
}

static void EmitSoundAtEyePosition(int client, const char[] sound) {
    float eyePos[3];

    GetClientEyePosition(client, eyePos);
    EmitAmbientSound(sound, eyePos, client, SNDLEVEL_RAIDSIREN);
}

static void SetEntityRenderColorHex(int client, int color) {
    int red = (color >> 24) & 0xFF;
    int green = (color >> 16) & 0xFF;
    int blue = (color >> 8) & 0xFF;
    int alpha = color & 0xFF;

    SetEntityRenderColor(client, red, green, blue, alpha);
}

static any Native_GetMaxWarnings(Handle plugin, int numParams) {
    return GetMaxWarnings();
}

static any Native_GetWarnings(Handle plugin, int numParams) {
    int client = GetNativeCell(1);

    return g_warnings[client];
}

static any Native_SetWarnings(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    int warnings = GetNativeCell(2);

    g_warnings[client] = warnings;
}

static any Native_IsPlayerPunished(Handle plugin, int numParams) {
    int client = GetNativeCell(1);

    return g_punishmentTimer[client] != null;
}

static any Native_PrintWarnings(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    int target = GetNativeCell(2);
    int playerWarnings = Afr_GetWarnings(target);
    int maxWarnings = Afr_GetMaxWarnings();

    CReplyToCommand(client, "%s%t", PREFIX_COLORED, "Warnings for player", target, playerWarnings, maxWarnings);
    LogAction(client, target, "\"%L\" checked warnings for \"%L\" (%d/%d)", client, target, playerWarnings, maxWarnings);
}

static any Native_ResetWarnings(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    int target = GetNativeCell(2);

    if (Afr_GetWarnings(target) == 0) {
        CReplyToCommand(client, "%s%t", PREFIX_COLORED, "Player has no warnings", target);
        LogAction(client, target, "\"%L\" tried to reset warnings for \"%L\"", client, target);
    } else {
        CPrintToChatAll("%s%t", PREFIX_COLORED, "Warnings cleared", client, target);
        LogAction(client, target, "\"%L\" reset warnings for \"%L\"", client, target);
        Afr_SetWarnings(target, 0);
    }
}

static any Native_RemoveWarning(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    int target = GetNativeCell(2);

    if (Afr_GetWarnings(target) == 0) {
        CReplyToCommand(client, "%s%t", PREFIX_COLORED, "Player has no warnings", target);
        LogAction(client, target, "\"%L\" tried to remove one warning for \"%L\"", client, target);
    } else {
        CPrintToChatAll("%s%t", PREFIX_COLORED, "Removed warning", client, target);
        LogAction(client, target, "\"%L\" removed one warning for \"%L\"", client, target);

        int currentWarnings = Afr_GetWarnings(target);

        Afr_SetWarnings(target, currentWarnings - 1);
    }
}
