void PrecacheDamageMessageSound() {
    PrecacheSound(SOUND_DAMAGE_MESSAGE, true);
}

void HookPunishedPlayer(int client) {
    SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
    SDKHook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
}

void UnhookPunishedPlayer(int client) {
    SDKUnhook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
    SDKUnhook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
}

public Action Hook_OnTakeDamageAlive(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
    return IsBlockVictimDamage() ? Plugin_Handled : Plugin_Continue;
}

public Action Hook_WeaponDrop(int client, int weapon) {
    return Plugin_Handled;
}

void BlockWeaponSlots(int client) {
    if (!IsBlockAttackerDamage()) {
        return;
    }

    float duration = GetPunishmentEndTime(client);

    for (int i = 0; i < WEAPON_SLOT_MAX_COUNT; i++) {
        BlockWeaponSlot(client, i, duration);
    }
}

void BlockWeaponSlot(int client, int slot, float next) {
    int weapon = GetPlayerWeaponSlot(client, slot);

    if (weapon != WEAPON_NOT_FOUND) {
        SetWeaponNextAttack(weapon, next);
    }
}

void SetWeaponNextAttack(int weapon, float next) {
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", next);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", next);
}
