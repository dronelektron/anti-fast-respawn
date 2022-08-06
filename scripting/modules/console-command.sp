void Command_Create() {
    RegAdminCmd("sm_afr", Command_Menu, ADMFLAG_GENERIC);
    RegAdminCmd("sm_afr_warnings", Command_CheckWarnings, ADMFLAG_GENERIC);
    RegAdminCmd("sm_afr_warnings_reset", Command_ResetWarnings, ADMFLAG_GENERIC);
    RegAdminCmd("sm_afr_warnings_reduce", Command_ReduceWarnings, ADMFLAG_GENERIC);
}

public Action Command_Menu(int client, int args) {
    if (client > 0) {
        Menu_Players(client);
    } else {
        PrintToServer("%s%s", PREFIX, "Menu is not supported for CONSOLE");
    }

    return Plugin_Handled;
}

public Action Command_CheckWarnings(int client, int args) {
    if (args < 1) {
        MessageReply_CheckWarningsUsage(client);

        return Plugin_Handled;
    }

    char name[MAX_NAME_LENGTH];

    GetCmdArg(1, name, sizeof(name));

    int target = FindTarget(client, name);

    if (target == CLIENT_NOT_FOUND) {
        return Plugin_Handled;
    }

    UseCase_CheckWarnings(client, target);

    return Plugin_Handled;
}

public Action Command_ResetWarnings(int client, int args) {
    if (args < 1) {
        MessageReply_ResetWarningsUsage(client);

        return Plugin_Handled;
    }

    char name[MAX_NAME_LENGTH];

    GetCmdArg(1, name, sizeof(name));

    int target = FindTarget(client, name);

    if (target == CLIENT_NOT_FOUND) {
        return Plugin_Handled;
    }

    UseCase_ResetWarnings(client, target);

    return Plugin_Handled;
}

public Action Command_ReduceWarnings(int client, int args) {
    if (args < 1) {
        MessageReply_ReduceWarningsUsage(client);

        return Plugin_Handled;
    }

    char name[MAX_NAME_LENGTH];

    GetCmdArg(1, name, sizeof(name));

    int target = FindTarget(client, name);

    if (target == CLIENT_NOT_FOUND) {
        return Plugin_Handled;
    }

    UseCase_ReduceWarnings(client, target);

    return Plugin_Handled;
}
