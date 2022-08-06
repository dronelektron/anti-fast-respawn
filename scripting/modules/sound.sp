void Sound_Precache() {
    PrecacheSound(SOUND_BLOCK, SOUND_PRELOAD_YES);
    PrecacheSound(SOUND_UNBLOCK, SOUND_PRELOAD_YES);
}

void Sound_Emit(int client, const char[] sound) {
    float eyePosition[3];

    GetClientEyePosition(client, eyePosition);
    EmitAmbientSound(sound, eyePosition, client, SNDLEVEL_RAIDSIREN);
}
