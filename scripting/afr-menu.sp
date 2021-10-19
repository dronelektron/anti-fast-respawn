#include <sourcemod>
#include <morecolors>
#include <afr>
#include <afr-punishment>

#define PLAYER_OPTION_RESET_WARNINGS "0"
#define PLAYER_OPTION_REMOVE_WARNING "1"

public Plugin myinfo = {
    name = "Anti fast respawn (menu)",
    author = PLUGIN_AUTHOR,
    description = "Provides menu",
    version = PLUGIN_VERSION,
    url = ""
}

static int g_menuTargetId[MAXPLAYERS + 1] = {0, ...};

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int errMax) {
    CreateNative("Afr_CreateMenu", Native_CreateMenu);

    return APLRes_Success;
}

public void OnPluginStart() {
    LoadTranslations("anti-fast-respawn.phrases");
}

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
                    Afr_ResetWarnings(param1, target);
                } else if (StrEqual(option, PLAYER_OPTION_REMOVE_WARNING)) {
                    Afr_RemoveWarning(param1, target);
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

static void CreatePlayersMenu(int client) {
    Menu menu = new Menu(MenuHandler_Players);

    menu.SetTitle("%s%T", PREFIX, "Menu", client);

    AddPlayersToMenu(menu);

    menu.Display(client, MENU_TIME_FOREVER);
}

static void CreatePlayerOptionMenu(int client, int targetId) {
    int target = GetClientOfUserId(targetId);

    if (target == 0) {
        CPrintToChat(client, "%s%t", PREFIX_COLORED, "Player no longer available");

        return;
    }

    g_menuTargetId[client] = targetId;

    Menu menu = new Menu(MenuHandler_PlayerOption);
    int style;

    menu.SetTitle("%N", target);

    if (Afr_GetWarnings(target) > 0) {
        style = ITEMDRAW_DEFAULT;
    } else {
        style = ITEMDRAW_DISABLED;
    }

    AddFormattedMenuItem(menu, style, PLAYER_OPTION_RESET_WARNINGS, "%T", "Reset warnings", client);
    AddFormattedMenuItem(menu, style, PLAYER_OPTION_REMOVE_WARNING, "%T", "Remove warning", client);

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

static void AddPlayersToMenu(Menu menu) {
    for (int client = 1; client <= MaxClients; client++) {
        if (!IsClientConnected(client)) {
            continue;
        }

        int userId = GetClientUserId(client);
        char userIdStr[MAX_NAME_LENGTH];
        int playerWarnings = Afr_GetWarnings(client);

        IntToString(userId, userIdStr, sizeof(userIdStr));
        AddFormattedMenuItem(menu, ITEMDRAW_DEFAULT, userIdStr, "%T", "Player name with warnings amount", client, client, playerWarnings);
    }
}

static void AddFormattedMenuItem(Menu menu, int style, const char[] option, const char[] format, any ...) {
    char text[MAX_TEXT_BUFFER_LENGTH];

    VFormat(text, sizeof(text), format, 5);
    menu.AddItem(option, text, style);
}

static any Native_CreateMenu(Handle plugin, int numParams) {
    int client = GetNativeCell(1);

    CreatePlayersMenu(client);
}
