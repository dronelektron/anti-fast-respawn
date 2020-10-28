#if defined _afr_punishment_
    #endinput
#endif
#define _afr_punishment_

native int Afr_GetMaxWarnings();

native int Afr_GetWarnings(int client);

native void Afr_SetWarnings(int client, int warnings);

native bool Afr_IsPlayerPunished(int client);

native void Afr_PrintWarnings(int client, int target);

native void Afr_ResetWarnings(int client, int target);

native void Afr_RemoveWarning(int client, int target);
