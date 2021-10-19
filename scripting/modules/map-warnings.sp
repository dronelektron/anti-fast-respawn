static StringMap g_savedWarnings = null;
static char g_authId[MAXPLAYERS + 1][MAX_AUTH_ID_LENGTH];

void CreateMapWarningsTrie() {
    g_savedWarnings = CreateTrie();
}

void DestroyMapWarningsTrie() {
    CloseHandle(g_savedWarnings);
}

void ClearMapWarningsTrie() {
    g_savedWarnings.Clear();
}

void SetPlayerAuthId(int client, const char[] authId) {
    strcopy(g_authId[client], MAX_AUTH_ID_LENGTH, authId);
}

void LoadPlayerWarnings(int client) {
    if (!IsWarningsSaveEnabled()) {
        return;
    }

    char authId[MAX_AUTH_ID_LENGTH];

    if (!GetClientAuthId(client, AuthId_Steam3, authId, sizeof(authId), true)) {
        return;
    }

    int savedWarnings;

    if (g_savedWarnings.GetValue(authId, savedWarnings)) {
        int currentWarnings = GetWarnings(client);

        SetWarnings(client, currentWarnings + savedWarnings);
        g_savedWarnings.Remove(authId);
    }

    SetPlayerAuthId(client, authId);
}

void SavePlayerWarnings(int client) {
    if (StrEqual(g_authId[client], NO_AUTH_ID)) {
        return;
    }

    if (!IsWarningsSaveEnabled()) {
        return;
    }

    int maxWarnings = GetMaxWarnings();
    int playerWarnings = GetWarnings(client);

    if (playerWarnings == 0 || playerWarnings > maxWarnings) {
        return;
    }

    g_savedWarnings.SetValue(g_authId[client], playerWarnings, true);
}
