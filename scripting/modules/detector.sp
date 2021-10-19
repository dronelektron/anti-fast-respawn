static bool g_isRoundEnd = false;
static bool g_killed[MAXPLAYERS + 1] = {false, ...};
static Handle g_checkerTimer[MAXPLAYERS + 1] = {null, ...};

void SetRoundEnd(bool isRoundEnd) {
    g_isRoundEnd = isRoundEnd;
}

bool IsPlayerKilled(int client) {
    return g_killed[client];
}

void SetPlayerKilled(int client, bool isKilled) {
    g_killed[client] = isKilled;
}

void ResetPlayerCheckerTimer(int client) {
    g_checkerTimer[client] = null;
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
