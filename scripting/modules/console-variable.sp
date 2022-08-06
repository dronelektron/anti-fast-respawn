static ConVar g_pluginEnabled = null;
static ConVar g_minActivePlayers = null;
static ConVar g_frozenPlayerBlockAttack = null;
static ConVar g_frozenPlayerBlockDamage = null;
static ConVar g_warningsSaving = null;
static ConVar g_maxWarnings = null;
static ConVar g_freezeTime = null;
static ConVar g_minSpectatorTime = null;
static ConVar g_showFreezeTimer = null;

void Variable_Create() {
    g_pluginEnabled = CreateConVar("sm_afr_enable", "1", "Enable (1) or disable (0) plugin");
    g_minActivePlayers = CreateConVar("sm_afr_min_active_players", "1", "Minimum amount of active players to enable protection");
    g_frozenPlayerBlockAttack = CreateConVar("sm_afr_frozen_player_block_attack", "1", "Block (1 - yes, 0 - no) attack from a frozen player");
    g_frozenPlayerBlockDamage = CreateConVar("sm_afr_frozen_player_block_damage", "1", "Block (1 - yes, 0 - no) damage to a frozen player");
    g_warningsSaving = CreateConVar("sm_afr_warnings_saving", "1", "Enable (1) or disable (0) warnings saving");
    g_maxWarnings = CreateConVar("sm_afr_max_warnings", "3", "Maximum number of warnings");
    g_freezeTime = CreateConVar("sm_afr_freeze_time", "5", "Freeze time (in seconds) due to fast respawn");
    g_minSpectatorTime = CreateConVar("sm_afr_min_spectator_time", "5", "Minimum time (in seconds) in spectator team to not be frozen for a fast respawn");
    g_showFreezeTimer = CreateConVar("sm_afr_show_freeze_timer", "1", "Show (1 - yes, 0 - no) freeze timer");
}

bool Variable_PluginEnabled() {
    return g_pluginEnabled.IntValue == 1;
}

int Variable_MinActivePlayers() {
    return g_minActivePlayers.IntValue;
}

bool Variable_FrozenPlayerBlockAttack() {
    return g_frozenPlayerBlockAttack.IntValue == 1;
}

bool Variable_FrozenPlayerBlockDamage() {
    return g_frozenPlayerBlockDamage.IntValue == 1;
}

bool Variable_WarningsSaving() {
    return g_warningsSaving.IntValue == 1;
}

int Variable_MaxWarnings() {
    return g_maxWarnings.IntValue;
}

int Variable_FreezeTime() {
    return g_freezeTime.IntValue;
}

int Variable_MinSpectatorTime() {
    return g_minSpectatorTime.IntValue;
}

bool Variable_ShowFreezeTimer() {
    return g_showFreezeTimer.IntValue == 1;
}
