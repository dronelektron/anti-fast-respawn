static int g_targetId[MAXPLAYERS + 1];

void Menu_Players(int client) {
    Menu menu = new Menu(MenuHandler_Players);

    menu.SetTitle(ANTI_FAST_RESPAWN);

    Menu_AddPlayers(menu, client);

    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Players(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        char info[INFO_MAX_SIZE];

        menu.GetItem(param2, info, sizeof(info));

        int targetId = StringToInt(info);

        Menu_PlayerOptions(param1, targetId);
    } else if (action == MenuAction_End) {
        delete menu;
    }

    return 0;
}

void Menu_PlayerOptions(int client, int targetId) {
    int target = GetClientOfUserId(targetId);

    if (target == INVALID_CLIENT) {
        MessageReply_PlayerNoLongerAvailable(client);

        return;
    }

    g_targetId[client] = targetId;

    Menu menu = new Menu(MenuHandler_PlayerOptions);

    int warnings = Client_GetWarnings(target);
    int maxWarnings = Variable_MaxWarnings();

    menu.SetTitle("%T", ITEM_PLAYER_NAME_AND_WARNINGS, client, target, warnings, maxWarnings);

    Menu_AddItem(menu, ITEM_WARNINGS_RESET, "%T", ITEM_WARNINGS_RESET, client);
    Menu_AddItem(menu, ITEM_WARNINGS_REDUCE, "%T", ITEM_WARNINGS_REDUCE, client);

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_PlayerOptions(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        char info[INFO_MAX_SIZE];

        menu.GetItem(param2, info, sizeof(info));

        int targetId = g_targetId[param1];
        int target = GetClientOfUserId(targetId);

        if (target == INVALID_CLIENT) {
            MessageReply_PlayerNoLongerAvailable(param1);

            return 0;
        }

        if (StrEqual(info, ITEM_WARNINGS_RESET)) {
            UseCase_ResetWarnings(param1, target);
        } else if (StrEqual(info, ITEM_WARNINGS_REDUCE)) {
            UseCase_ReduceWarnings(param1, target);
        }
    } else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) {
        Menu_Players(param1);
    } else if (action == MenuAction_End) {
        delete menu;
    }

    return 0;
}

void Menu_AddPlayers(Menu menu, int client) {
    int players[MAXPLAYERS + 1];
    int playersAmount = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            players[playersAmount++] = i;
        }
    }

    SortCustom1D(players, playersAmount, MenuSortFunc_ByWarnings);

    for (int i = 0; i < playersAmount; i++) {
        int player = players[i];
        int userId = GetClientUserId(player);
        int warnings = Client_GetWarnings(player);
        int maxWarnings = Variable_MaxWarnings();
        char info[INFO_MAX_SIZE];

        IntToString(userId, info, sizeof(info));
        Menu_AddItem(menu, info, "%T", ITEM_PLAYER_NAME_AND_WARNINGS, client, player, warnings, maxWarnings);
    }
}

int MenuSortFunc_ByWarnings(int elem1, int elem2, const int[] array, Handle hndl) {
    int warnings1 = Client_GetWarnings(elem1);
    int warnings2 = Client_GetWarnings(elem2);

    return warnings2 - warnings1;
}

void Menu_AddItem(Menu menu, const char[] info, const char[] phrase, any ...) {
    char item[ITEM_MAX_SIZE];

    VFormat(item, sizeof(item), phrase, 4);

    menu.AddItem(info, item);
}
