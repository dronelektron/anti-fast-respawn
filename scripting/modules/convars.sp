static ConVar g_pluginEnabled = null;
static ConVar g_minActivePlayers = null;

static ConVar g_blockAttackerDamage = null;
static ConVar g_blockVictimDamage = null;

static ConVar g_enableWarningsSave = null;

static ConVar g_maxWarnings = null;
static ConVar g_punishType = null;
static ConVar g_freezeTime = null;
static ConVar g_banTime = null;
static ConVar g_minSpectatorTime = null;
static ConVar g_showPunishmentTimer = null;

void CreateConVars() {
    g_pluginEnabled = CreateConVar("sm_afr_enable", "1", "Enable (1) or disable (0) detection of fast respawn");
    g_minActivePlayers = CreateConVar("sm_afr_min_active_players", "1", "Minimum amount of active players to enable protection");

    g_blockAttackerDamage = CreateConVar("sm_afr_block_attacker_damage", "1", "Enable (1) or disable (0) damage from attacker when he is punished");
    g_blockVictimDamage = CreateConVar("sm_afr_block_victim_damage", "1", "Enable (1) or disable (0) damage on victim when he is punished");

    g_enableWarningsSave = CreateConVar("sm_afr_enable_warnings_save", "1", "Enable (1) or disable (0) warnings save");

    g_maxWarnings = CreateConVar("sm_afr_max_warnings", "3", "Maximum warnings about fast respawn");
    g_punishType = CreateConVar("sm_afr_punish_type", "1", "Punish type for fast respawn (0 - freeze, 1 - kick, 2 - ban)");
    g_freezeTime = CreateConVar("sm_afr_freeze_time", "5", "Freeze time (in seconds) due fast respawn");
    g_banTime = CreateConVar("sm_afr_ban_time", "15", "Ban time (in minutes) due fast respawn");
    g_minSpectatorTime = CreateConVar("sm_afr_min_spectator_time", "5", "Minimum time (in seconds) in spectator team to not be punished for fast respawn");
    g_showPunishmentTimer = CreateConVar("sm_afr_show_punishment_timer", "1", "Show punishment timer");
}

bool IsPluginEnabled() {
    return g_pluginEnabled.IntValue == 1;
}

int GetMinActivePlayers() {
    return g_minActivePlayers.IntValue;
}

bool IsBlockAttackerDamage() {
    return g_blockAttackerDamage.IntValue == 1;
}

bool IsBlockVictimDamage() {
    return g_blockVictimDamage.IntValue == 1;
}

bool IsWarningsSaveEnabled() {
    return g_enableWarningsSave.IntValue == 1;
}

int GetMaxWarnings() {
    return g_maxWarnings.IntValue;
}

int GetPunishType() {
    return g_punishType.IntValue;
}

int GetFreezeTime() {
    return g_freezeTime.IntValue;
}

int GetBanTime() {
    return g_banTime.IntValue;
}

float GetMinSpectatorTime() {
    return g_minSpectatorTime.FloatValue;
}

bool IsShowPunishmentTimer() {
    return g_showPunishmentTimer.IntValue == 1;
}
