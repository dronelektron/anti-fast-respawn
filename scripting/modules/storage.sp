static StringMap g_warnings = null;
static char g_steam[MAXPLAYERS + 1][MAX_AUTHID_LENGTH];

void Storage_Create() {
    g_warnings = new StringMap();
}

void Storage_Destroy() {
    delete g_warnings;
}

void Storage_Clear() {
    g_warnings.Clear();
}

int Storage_GetWarnings(int client) {
    int warnings = 0;

    g_warnings.GetValue(g_steam[client], warnings);

    return warnings;
}

void Storage_SetWarnings(int client, int warnings) {
    g_warnings.SetValue(g_steam[client], warnings);
}

void Storage_SaveSteam(int client) {
    GetClientAuthId(client, AuthId_Steam3, g_steam[client], sizeof(g_steam[]));
}
