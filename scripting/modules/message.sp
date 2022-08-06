void Message_ClientFastRespawned(int client, int warnings, int maxWarnings) {
    CPrintToChatAll("%s%t", PREFIX_COLORED, "Fast respawn detected", client, warnings, maxWarnings);
    CPrintToChat(client, "%s%t", PREFIX_COLORED, "Anti fast respawn advice");
    LogMessage("\"%L\" fast respawned (%d/%d)", client, warnings, maxWarnings);
}

void MessageHint_YouWasFrozen(int client, int secondsLeft) {
    PrintHintText(client, "%t", "You was frozen", secondsLeft);
}

void MessageHint_YouAreFreeNow(int client) {
    PrintHintText(client, "%t", "You are free now");
}

void MessageLog_SavedWarnings(int client, int warnings) {
    LogMessage("Saved %d warnings for \"%L\"", warnings, client);
}

void MessageLog_LoadedWarnings(int client, int warnings) {
    LogMessage("Loaded %d warnings for \"%L\"", warnings, client);
}

void Message_PlayerHasNoWarnings(int client, int target) {
    ReplyToCommand(client, "%s%t", PREFIX, "Player has no warnings", target);
}

void MessageReply_CheckWarningsUsage(int client) {
    ReplyToCommand(client, "%s%s", PREFIX, "sm_afr_warnings <#userid|name>");
}

void Message_CheckWarnings(int client, int target, int warnings, int maxWarnings) {
    ReplyToCommand(client, "%s%t", PREFIX, "Warnings for player", target, warnings, maxWarnings);
    LogMessage("\"%L\" checked warnings for \"%L\" (%d/%d)", client, target, warnings, maxWarnings);
}

void MessageReply_ResetWarningsUsage(int client) {
    ReplyToCommand(client, "%s%s", PREFIX, "sm_afr_warnings_reset <#userid|name>");
}

void Message_WarningsReset(int client, int target) {
    ShowActivity2(client, PREFIX, "%t", "Warnings reset", target);
    LogMessage("\"%L\" reset warnings for \"%L\"", client, target);
}

void MessageReply_ReduceWarningsUsage(int client) {
    ReplyToCommand(client, "%s%s", PREFIX, "sm_afr_warnings_reduce <#userid|name>");
}

void Message_WarningsReduced(int client, int target) {
    ShowActivity2(client, PREFIX, "%t", "Warnings reduced", target);
    LogMessage("\"%L\" reduced warnings for \"%L\"", client, target);
}

void MessageReply_PlayerNoLongerAvailable(int client) {
    PrintToChat(client, "%s%t", PREFIX, "Player no longer available");
}
