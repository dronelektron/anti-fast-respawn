static GlobalForward g_onFastRespawnPunishment = null;

void Api_Create() {
    g_onFastRespawnPunishment = new GlobalForward("OnFastRespawnPunishment", ET_Ignore, Param_Cell);
}

void Api_Destroy() {
    delete g_onFastRespawnPunishment;
}

void Api_OnFastRespawnPunishment(int client) {
    Call_StartForward(g_onFastRespawnPunishment);
    Call_PushCell(client);
    Call_Finish();
}
