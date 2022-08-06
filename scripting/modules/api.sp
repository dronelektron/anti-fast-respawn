static GlobalForward g_onFastRespawnPunish = null;

void Api_Create() {
    g_onFastRespawnPunish = new GlobalForward("OnFastRespawnPunish", ET_Ignore, Param_Cell);
}

void Api_Destroy() {
    delete g_onFastRespawnPunish;
}

void Api_OnFastRespawnPunish(int client) {
    Call_StartForward(g_onFastRespawnPunish);
    Call_PushCell(client);
    Call_Finish();
}
