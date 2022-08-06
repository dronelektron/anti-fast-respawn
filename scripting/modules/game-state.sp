static bool g_isRoundEnd = ROUND_END_NO;

bool GameState_IsRoundEnd() {
    return g_isRoundEnd;
}

void GameState_SetRoundEnd(bool isRoundEnd) {
    g_isRoundEnd = isRoundEnd;
}
