static Handle g_damageMessageTimer[MAXPLAYERS + 1] = {null, ...};

void PrecacheDamageMessageSound() {
    PrecacheSound(SOUND_DAMAGE_MESSAGE, true);
}

void HookTakeDamage(int client) {
    SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
}

void UnhookTakeDamage(int client) {
    SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
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

    if (IsPlayerPunished(attacker) && IsBlockAttackerDamage()) {
        CreateDamageMessageTimerForAttacker(attacker);

        return Plugin_Handled;
    }

    if (IsPlayerPunished(victim) && IsBlockVictimDamage()) {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

void CreateDamageMessageTimerForAttacker(int attacker) {
    if (g_damageMessageTimer[attacker] == null) {
        int userId = GetClientUserId(attacker);

        g_damageMessageTimer[attacker] = CreateTimer(DAMAGE_MESSAGE_TIMER_DELAY, Timer_DamageMessage, userId);

        CPrintToChat(attacker, "%s%t", PREFIX_COLORED, "You cannot attack");
        EmitSoundToClient(attacker, SOUND_DAMAGE_MESSAGE);
    }
}

bool IsClientIndexValid(int client) {
    return client >= 1 && client <= MaxClients;
}
