#include <sourcemod>
#include <afr>
#include <afr-punishment>

#define MAX_AUTH_ID_LENGTH 65
#define NO_AUTH_ID ""

public Plugin myinfo = {
    name = "Anti fast respawn (map warnings)",
    author = PLUGIN_AUTHOR,
    description = "Allows to save and load warnings for current map",
    version = PLUGIN_VERSION,
    url = ""
}

static StringMap g_savedWarnings = null;
static char g_authId[MAXPLAYERS + 1][MAX_AUTH_ID_LENGTH];

public void OnPluginStart() {
    g_savedWarnings = CreateTrie();
}

public void OnPluginEnd() {
    CloseHandle(g_savedWarnings);
}

public void OnMapEnd() {
    g_savedWarnings.Clear();
}

public void OnClientConnected(int client) {
    strcopy(g_authId[client], MAX_AUTH_ID_LENGTH, NO_AUTH_ID);
}

public void OnClientAuthorized(int client, const char[] auth) {
    LoadPlayerWarnings(client);
}

public void OnClientDisconnect(int client) {
    SavePlayerWarnings(client);
}

static void LoadPlayerWarnings(int client) {
    if (!IsWarningsSaveEnabled()) {
        return;
    }

    char authId[MAX_AUTH_ID_LENGTH];

    if (!GetClientAuthId(client, AuthId_Steam3, authId, sizeof(authId), true)) {
        return;
    }

    int savedWarnings;

    if (g_savedWarnings.GetValue(authId, savedWarnings)) {
        int currentWarnings = Afr_GetWarnings(client);

        Afr_SetWarnings(client, currentWarnings + savedWarnings);
        g_savedWarnings.Remove(authId);
    }

    strcopy(g_authId[client], MAX_AUTH_ID_LENGTH, authId);
}

static void SavePlayerWarnings(int client) {
    if (StrEqual(g_authId[client], NO_AUTH_ID)) {
        return;
    }

    if (!IsWarningsSaveEnabled()) {
        return;
    }

    int maxWarnings = Afr_GetMaxWarnings();
    int playerWarnings = Afr_GetWarnings(client);

    if (playerWarnings == 0 || playerWarnings > maxWarnings) {
        return;
    }

    g_savedWarnings.SetValue(g_authId[client], playerWarnings, true);
}
