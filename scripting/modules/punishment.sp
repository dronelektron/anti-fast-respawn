static int g_warnings[MAXPLAYERS + 1] = {0, ...};
static int g_punishmentSeconds[MAXPLAYERS + 1] = {0, ...};
static int g_lastTeam[MAXPLAYERS + 1] = {0, ...};
static Handle g_punishmentTimer[MAXPLAYERS + 1] = {null, ...};
static Handle g_spectatorTimer[MAXPLAYERS + 1] = {null, ...};

void PrecachePunishmentSounds() {
    PrecacheSound(SOUND_BLOCK, true);
    PrecacheSound(SOUND_UNBLOCK, true);
}

void ClearPunishment(int client) {
    g_warnings[client] = 0;
    g_punishmentSeconds[client] = 0;
    g_punishmentTimer[client] = null;
}

void CheckFastRespawnFromSpectator(int client, int newTeam) {
    if (newTeam == TEAM_SPECTATOR) {
        if (IsPlayerKilled(client)) {
            CreateSpectatorTimer(client);
        }
    } else {
        delete g_spectatorTimer[client];

        int oldTeam = g_lastTeam[client];
        bool alliesToAxis = oldTeam == TEAM_ALLIES && newTeam == TEAM_AXIS;
        bool axisToAllies = oldTeam == TEAM_AXIS && newTeam == TEAM_ALLIES;

        if (alliesToAxis || axisToAllies) {
            SetPlayerKilled(client, false);
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
        SetPlayerKilled(client, false);
    }

    g_spectatorTimer[client] = null;

    return Plugin_Continue;
}

void CreateSpectatorTimer(int client) {
    if (!IsProtectionEnabled()) {
        return;
    }

    if (IsPlayerPunished(client)) {
        return;
    }

    if (g_spectatorTimer[client] == null) {
        int userId = GetClientUserId(client);
        float minSpectatorTime = GetMinSpectatorTime();

        g_spectatorTimer[client] = CreateTimer(minSpectatorTime, Timer_Spectator, userId);
    }
}

void PunishPlayer(int client) {
    if (IsPlayerPunished(client)) {
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

void PunishPlayerByType(int client) {
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

void BlockPlayer(int client) {
    if (!IsPlayerPunished(client)) {
        int userId = GetClientUserId(client);

        g_punishmentSeconds[client] = GetFreezeTime();
        g_punishmentTimer[client] = CreateTimer(PUNISH_TIMER_INTERVAL, Timer_Punish, userId, TIMER_REPEAT);

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

int GetWarnings(int client) {
    return g_warnings[client];
}

void SetWarnings(int client, int warnings) {
    g_warnings[client] = warnings;
}

bool IsPlayerPunished(int client) {
    return g_punishmentTimer[client] != null;
}

void PrintWarnings(int client, int target) {
    int playerWarnings = GetWarnings(target);
    int maxWarnings = GetMaxWarnings();

    CReplyToCommand(client, "%s%t", PREFIX_COLORED, "Warnings for player", target, playerWarnings, maxWarnings);
    LogAction(client, target, "\"%L\" checked warnings for \"%L\" (%d/%d)", client, target, playerWarnings, maxWarnings);
}

void ResetWarnings(int client, int target) {
    if (GetWarnings(target) == 0) {
        CReplyToCommand(client, "%s%t", PREFIX_COLORED, "Player has no warnings", target);
        LogAction(client, target, "\"%L\" tried to reset warnings for \"%L\"", client, target);
    } else {
        CPrintToChatAll("%s%t", PREFIX_COLORED, "Warnings cleared", client, target);
        LogAction(client, target, "\"%L\" reset warnings for \"%L\"", client, target);
        SetWarnings(target, 0);
    }
}

void RemoveWarning(int client, int target) {
    if (GetWarnings(target) == 0) {
        CReplyToCommand(client, "%s%t", PREFIX_COLORED, "Player has no warnings", target);
        LogAction(client, target, "\"%L\" tried to remove one warning for \"%L\"", client, target);
    } else {
        CPrintToChatAll("%s%t", PREFIX_COLORED, "Removed warning", client, target);
        LogAction(client, target, "\"%L\" removed one warning for \"%L\"", client, target);

        int currentWarnings = GetWarnings(target);

        SetWarnings(target, currentWarnings - 1);
    }
}
