#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <afr>
#include <afr-punishment>

#define SOUND_DAMAGE_MESSAGE "buttons/button8.wav"

public Plugin myinfo = {
    name = "Anti fast respawn (attack blocker)",
    author = PLUGIN_AUTHOR,
    description = "Blocks attack when a player is punished",
    version = PLUGIN_VERSION,
    url = ""
}

static const float DAMAGE_MESSAGE_TIMER_DELAY = 1.0

static ConVar g_blockAttack = null;
static Handle g_damageMessageTimer[MAXPLAYERS + 1] = {null, ...};

public void OnPluginStart() {
    LoadTranslations("afr-attack-blocker.phrases");

    g_blockAttack = CreateConVar("sm_afr_block_attack", "1", "Enable (1) or disable (0) attack blocking when a player is punished");

    AutoExecConfig(true, "afr-attack-blocker");
}

public void OnMapStart() {
    PrecacheSound(SOUND_DAMAGE_MESSAGE, true);
}

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int client) {
    SDKUnhook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
}

public Action Timer_DamageMessage(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    g_damageMessageTimer[client] = null;

    return Plugin_Handled;
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
    if (!IsBlockDamage()) {
        return Plugin_Continue;
    }

    if (!IsClientIndexValid(attacker)) {
        return Plugin_Continue;
    }

    if (!Afr_IsPlayerPunished(attacker)) {
        return Plugin_Continue;
    }

    if (g_damageMessageTimer[attacker] == null) {
        int userId = GetClientUserId(attacker);

        g_damageMessageTimer[attacker] = CreateTimer(DAMAGE_MESSAGE_TIMER_DELAY, Timer_DamageMessage, userId);

        CPrintToChat(attacker, "%s%t", PREFIX_COLORED, "You cannot attack");
        EmitSoundToClient(attacker, SOUND_DAMAGE_MESSAGE);
    }

    return Plugin_Handled;
}

static bool IsClientIndexValid(int client) {
    return client >= 1 && client <= MAXPLAYERS;
}

static bool IsBlockDamage() {
    return g_blockAttack.IntValue == 1;
}
