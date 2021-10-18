#if defined _afr_
    #endinput
#endif
#define _afr_

#define PLUGIN_AUTHOR "Dron-elektron"
#define PLUGIN_VERSION "0.16.0"

#define PREFIX "[AFR] "
#define PREFIX_COLORED "{cyan}[AFR] "

#define TEAM_SPECTATOR 1
#define TEAM_ALLIES 2
#define TEAM_AXIS 3

#define MAX_TEXT_BUFFER_LENGTH 1024

forward void OnPlayerFastRespawned(int client);

native bool Afr_IsProtectionEnabled();

native bool Afr_IsPlayerKilled(int client);

native void Afr_SetPlayerKilled(int client, bool isKilled);
