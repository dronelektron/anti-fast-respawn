static int g_warnings[MAXPLAYERS + 1];
static int g_freezeSeconds[MAXPLAYERS + 1];
static float g_punishmentEndTime[MAXPLAYERS + 1];

void Client_Reset(int client) {
    g_warnings[client] = 0;
    g_freezeSeconds[client] = 0;
    g_punishmentEndTime[client] = 0.0;
}

int Client_GetWarnings(int client) {
    return g_warnings[client];
}

void Client_SetWarnings(int client, int warnings) {
    g_warnings[client] = warnings;
}

void Client_IncrementWarnings(int client) {
    g_warnings[client]++;
}

void Client_DecrementWarnings(int client) {
    g_warnings[client]--;
}

bool Client_IsFrozen(int client) {
    return g_freezeSeconds[client] > 0;
}

int Client_GetFreezeSeconds(int client) {
    return g_freezeSeconds[client];
}

void Client_SetFreezeSeconds(int client, int seconds) {
    g_freezeSeconds[client] = seconds;
}

void Client_DecrementFreezeSeconds(int client) {
    g_freezeSeconds[client]--;
}

float Client_GetPunishmentEndTime(int client) {
    return g_punishmentEndTime[client];
}

void Client_CalculatePunishmentEndTime(int client, int seconds) {
    g_punishmentEndTime[client] = GetGameTime() + seconds + 1.0;
}
