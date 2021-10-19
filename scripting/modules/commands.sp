void RegisterAdminCmds() {
    RegAdminCmd("sm_afr", Command_Menu, ADMFLAG_GENERIC);
    RegAdminCmd("sm_afr_warnings", Command_Warnings, ADMFLAG_GENERIC, USAGE_COMMAND_WARNINGS);
    RegAdminCmd("sm_afr_reset_warnings", Command_ResetWarnings, ADMFLAG_GENERIC, USAGE_COMMAND_RESET_WARNINGS);
    RegAdminCmd("sm_afr_remove_warning", Command_RemoveWarning, ADMFLAG_GENERIC, USAGE_COMMAND_REMOVE_WARNING);
}

public Action Command_Menu(int client, int args) {
    if (client > 0) {
        CreatePlayersMenu(client);
    } else {
        PrintToServer("%s%s", PREFIX, "Menu is not supported for console");
    }

    return Plugin_Handled;
}

public Action Command_Warnings(int client, int args) {
    if (args < 1) {
        CReplyToCommand(client, "%s%s", PREFIX_COLORED, USAGE_COMMAND_WARNINGS);

        return Plugin_Handled;
    }

    char name[MAX_NAME_LENGTH];

    GetCmdArg(1, name, sizeof(name));

    int target = FindTarget(client, name);

    if (target == -1) {
        return Plugin_Handled;
    }

    PrintWarnings(client, target);

    return Plugin_Handled;
}

public Action Command_ResetWarnings(int client, int args) {
    if (args < 1) {
        CReplyToCommand(client, "%s%s", PREFIX_COLORED, USAGE_COMMAND_RESET_WARNINGS);

        return Plugin_Handled;
    }

    char name[MAX_NAME_LENGTH];

    GetCmdArg(1, name, sizeof(name));

    int target = FindTarget(client, name);

    if (target == -1) {
        return Plugin_Handled;
    }

    ResetWarnings(client, target);

    return Plugin_Handled;
}

public Action Command_RemoveWarning(int client, int args) {
    if (args < 1) {
        CReplyToCommand(client, "%s%s", PREFIX_COLORED, USAGE_COMMAND_REMOVE_WARNING);

        return Plugin_Handled;
    }

    char name[MAX_NAME_LENGTH];

    GetCmdArg(1, name, sizeof(name));

    int target = FindTarget(client, name);

    if (target == -1) {
        return Plugin_Handled;
    }

    RemoveWarning(client, target);

    return Plugin_Handled;
}
