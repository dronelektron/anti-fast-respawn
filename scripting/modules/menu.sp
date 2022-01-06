static int g_menuTargetId[MAXPLAYERS + 1] = {0, ...};

public int MenuHandler_Players(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char userIdStr[MAX_TEXT_BUFFER_LENGTH];

            menu.GetItem(param2, userIdStr, sizeof(userIdStr));

            int targetId = StringToInt(userIdStr);

            CreatePlayerOptionMenu(param1, targetId);
        }

        case MenuAction_End: {
            delete menu;
        }
    }
}

public int MenuHandler_PlayerOption(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char option[MAX_TEXT_BUFFER_LENGTH];

            menu.GetItem(param2, option, sizeof(option));

            int targetId = g_menuTargetId[param1];
            int target = GetClientOfUserId(targetId);

            if (target == 0) {
                CPrintToChat(param1, "%s%t", PREFIX_COLORED, "Player no longer available");
            } else {
                if (StrEqual(option, PLAYER_OPTION_RESET_WARNINGS)) {
                    ResetWarnings(param1, target);
                } else if (StrEqual(option, PLAYER_OPTION_REMOVE_WARNING)) {
                    RemoveWarning(param1, target);
                }
            }
        }

        case MenuAction_Cancel: {
            if (param2 == MenuCancel_ExitBack) {
                CreatePlayersMenu(param1);
            }
        }

        case MenuAction_End: {
            delete menu;
        }
    }
}

void CreatePlayersMenu(int client) {
    Menu menu = new Menu(MenuHandler_Players);

    menu.SetTitle("%s%T", PREFIX, "Menu", client);

    AddPlayersToMenu(menu);

    menu.Display(client, MENU_TIME_FOREVER);
}

void CreatePlayerOptionMenu(int client, int targetId) {
    int target = GetClientOfUserId(targetId);

    if (target == 0) {
        CPrintToChat(client, "%s%t", PREFIX_COLORED, "Player no longer available");

        return;
    }

    g_menuTargetId[client] = targetId;

    Menu menu = new Menu(MenuHandler_PlayerOption);
    int style;

    menu.SetTitle("%N", target);

    if (GetWarnings(target) > 0) {
        style = ITEMDRAW_DEFAULT;
    } else {
        style = ITEMDRAW_DISABLED;
    }

    AddFormattedMenuItem(menu, style, PLAYER_OPTION_RESET_WARNINGS, "%T", "Reset warnings", client);
    AddFormattedMenuItem(menu, style, PLAYER_OPTION_REMOVE_WARNING, "%T", "Remove warning", client);

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void AddPlayersToMenu(Menu menu) {
    for (int client = 1; client <= MaxClients; client++) {
        if (!IsClientConnected(client) || IsFakeClient(client)) {
            continue;
        }

        int userId = GetClientUserId(client);
        char userIdStr[MAX_NAME_LENGTH];
        int playerWarnings = GetWarnings(client);

        IntToString(userId, userIdStr, sizeof(userIdStr));
        AddFormattedMenuItem(menu, ITEMDRAW_DEFAULT, userIdStr, "%T", "Player name with warnings amount", client, client, playerWarnings);
    }
}

void AddFormattedMenuItem(Menu menu, int style, const char[] option, const char[] format, any ...) {
    char text[MAX_TEXT_BUFFER_LENGTH];

    VFormat(text, sizeof(text), format, 5);
    menu.AddItem(option, text, style);
}
