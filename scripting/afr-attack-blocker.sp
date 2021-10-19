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

static const float DAMAGE_MESSAGE_TIMER_DELAY = 1.0;

static Handle g_damageMessageTimer[MAXPLAYERS + 1] = {null, ...};

static ConVar g_blockAttackerDamage = null;
static ConVar g_blockVictimDamage = null;

public void OnPluginStart() {
    LoadTranslations("anti-fast-respawn.phrases");

    g_blockAttackerDamage = CreateConVar("sm_afr_block_attacker_damage", "1", "Enable (1) or disable (0) damage from attacker when he is punished");
    g_blockVictimDamage = CreateConVar("sm_afr_block_victim_damage", "1", "Enable (1) or disable (0) damage on victim when he is punished");

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
    if (!IsClientIndexValid(victim) || !IsClientIndexValid(attacker)) {
        return Plugin_Continue;
    }

    if (Afr_IsPlayerPunished(attacker) && IsBlockAttackerDamage()) {
        CreateDamageMessageTimerForAttacker(attacker);

        return Plugin_Handled;
    }

    if (Afr_IsPlayerPunished(victim) && IsBlockVictimDamage()) {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

static void CreateDamageMessageTimerForAttacker(int attacker) {
    if (g_damageMessageTimer[attacker] == null) {
        int userId = GetClientUserId(attacker);

        g_damageMessageTimer[attacker] = CreateTimer(DAMAGE_MESSAGE_TIMER_DELAY, Timer_DamageMessage, userId);

        CPrintToChat(attacker, "%s%t", PREFIX_COLORED, "You cannot attack");
        EmitSoundToClient(attacker, SOUND_DAMAGE_MESSAGE);
    }
}

static bool IsClientIndexValid(int client) {
    return client >= 1 && client <= MaxClients;
}

static bool IsBlockAttackerDamage() {
    return g_blockAttackerDamage.IntValue == 1;
}

static bool IsBlockVictimDamage() {
    return g_blockVictimDamage.IntValue == 1;
}
