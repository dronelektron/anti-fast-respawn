void UseCase_ClientFastRespawned(int client, float spectatorTime) {
    if (UseCase_IgnoreFastRespawn(client, spectatorTime)) {
        return;
    }

    Client_IncrementWarnings(client);

    int warnings = Client_GetWarnings(client);
    int maxWarnings = Variable_MaxWarnings();

    if (warnings <= maxWarnings) {
        UseCase_FreezeClient(client);
        Message_ClientFastRespawned(client, warnings, maxWarnings);
    } else {
        Client_SetWarnings(client, 0);
        Api_OnFastRespawnPunish(client);
    }
}

bool UseCase_IgnoreFastRespawn(int client, float spectatorTime) {
    bool result = !Variable_PluginEnabled();

    result |= GameState_IsRoundEnd();
    result |= UseCase_SpectatorTimeTooLong(spectatorTime);
    result |= UseCase_NotEnoughActivePlayers();
    result |= Client_IsFrozen(client);

    return result;
}

bool UseCase_SpectatorTimeTooLong(float spectatorTime) {
    return spectatorTime >= Variable_MinSpectatorTime();
}

bool UseCase_NotEnoughActivePlayers() {
    int alliesAmount = GetTeamClientCount(TEAM_ALLIES);
    int axisAmount = GetTeamClientCount(TEAM_AXIS);

    return alliesAmount + axisAmount < Variable_MinActivePlayers();
}

void UseCase_FreezeClient(int client) {
    if (Client_IsFrozen(client)) {
        return;
    }

    int userId = GetClientUserId(client);
    int secondsLeft = Variable_FreezeTime();

    CreateTimer(FREEZE_TIMER_INTERVAL, UseCaseTimer_Freeze, userId, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    Client_SetFreezeSeconds(client, secondsLeft);
    Client_CalculatePunishmentEndTime(client, secondsLeft);
    UseCase_BlockClient(client);
    Sound_Emit(client, SOUND_BLOCK);
    MessageHint_YouWasFrozen(client, secondsLeft);
}

public Action UseCaseTimer_Freeze(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == INVALID_CLIENT) {
        return Plugin_Stop;
    }

    Client_DecrementFreezeSeconds(client);

    if (Client_IsFrozen(client)) {
        if (Variable_ShowFreezeTimer()) {
            int secondsLeft = Client_GetFreezeSeconds(client);

            MessageHint_YouWasFrozen(client, secondsLeft);
        }

        return Plugin_Continue;
    }

    UseCase_UnblockClient(client);
    Sound_Emit(client, SOUND_UNBLOCK);
    MessageHint_YouAreFreeNow(client);

    return Plugin_Stop;
}

void UseCase_BlockPlayerAfterSpawn(int client) {
    if (Client_IsFrozen(client)) {
        UseCase_BlockClient(client);
    }
}

void UseCase_BlockClient(int client) {
    SetEntityMoveType(client, MOVETYPE_NONE);
    SetEntityRenderColor(client, 0, 127, 255, 255);
    UseCase_BlockAttack(client);
    UseCase_BlockDamage(client);
}

void UseCase_UnblockClient(int client) {
    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityRenderColor(client, 255, 255, 255, 255);
    UseCase_UnblockAttack(client);
    UseCase_UnblockDamage(client);
}

void UseCase_BlockAttack(int client) {
    if (Variable_FrozenPlayerBlockAttack()) {
        float nextAttackTime = Client_GetPunishmentEndTime(client);

        UseCase_SetWeaponsNextAttack(client, nextAttackTime);
        SDKHook(client, SDKHook_WeaponDrop, UseCaseHook_WeaponDrop);
    }
}

void UseCase_BlockDamage(int client) {
    if (Variable_FrozenPlayerBlockDamage()) {
        SDKHook(client, SDKHook_OnTakeDamageAlive, UseCaseHook_OnTakeDamageAlive);
    }
}

void UseCase_UnblockAttack(int client) {
    float nextAttackTime = GetGameTime();

    UseCase_SetWeaponsNextAttack(client, nextAttackTime);
    SDKUnhook(client, SDKHook_WeaponDrop, UseCaseHook_WeaponDrop);
}

void UseCase_UnblockDamage(int client) {
    SDKUnhook(client, SDKHook_OnTakeDamageAlive, UseCaseHook_OnTakeDamageAlive);
}

void UseCase_SetWeaponsNextAttack(int client, float nextAttackTime) {
    for (int i = 0; i < WEAPON_SLOTS_AMOUNT; i++) {
        UseCase_SetWeaponNextAttack(client, i, nextAttackTime);
    }
}

void UseCase_SetWeaponNextAttack(int client, int slot, float nextAttackTime) {
    int weapon = GetPlayerWeaponSlot(client, slot);

    if (weapon != WEAPON_NOT_FOUND) {
        SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", nextAttackTime);
        SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", nextAttackTime);
    }
}

public Action UseCaseHook_WeaponDrop(int client, int weapon) {
    return Plugin_Handled;
}

public Action UseCaseHook_OnTakeDamageAlive(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
    return Plugin_Handled;
}

void UseCase_SaveWarnings(int client) {
    if (!Variable_WarningsSaving()) {
        return;
    }

    int warnings = Client_GetWarnings(client);
    int maxWarnings = Variable_MaxWarnings();

    if (warnings == 0 || warnings > maxWarnings) {
        return;
    }

    Storage_SetWarnings(client, warnings);
    MessageLog_SavedWarnings(client, warnings);
}

void UseCase_LoadWarnings(int client) {
    Storage_SaveSteam(client);

    if (!Variable_WarningsSaving()) {
        return;
    }

    int warnings = Storage_GetWarnings(client);

    if (warnings > 0) {
        Client_SetWarnings(client, warnings);
        MessageLog_LoadedWarnings(client, warnings);
    }
}

void UseCase_CheckWarnings(int client, int target) {
    int warnings = Client_GetWarnings(target);
    int maxWarnings = Variable_MaxWarnings();

    Message_CheckWarnings(client, target, warnings, maxWarnings);
}

void UseCase_ResetWarnings(int client, int target) {
    if (Client_GetWarnings(target) == 0) {
        Message_PlayerHasNoWarnings(client, target);
    } else {
        Client_SetWarnings(target, 0);
        Message_WarningsReset(client, target);
    }
}

void UseCase_ReduceWarnings(int client, int target) {
    if (Client_GetWarnings(target) == 0) {
        Message_PlayerHasNoWarnings(client, target);
    } else {
        Client_DecrementWarnings(target);
        Message_WarningsReduced(client, target);
    }
}
