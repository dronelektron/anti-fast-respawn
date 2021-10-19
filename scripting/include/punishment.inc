#if defined _punishment_
    #endinput
#endif
#define _punishment_

#define SOUND_BLOCK "physics/glass/glass_impact_bullet4.wav"
#define SOUND_UNBLOCK "physics/glass/glass_bottle_break2.wav"

#define COLOR_BLOCK 0x0080FFFF // 0 128 255 255
#define COLOR_UNBLOCK 0xFFFFFFFF // 255 255 255 255

#define PUNISH_TIMER_INTERVAL 1.0

enum PunishType {
    PunishType_Freeze,
    PunishType_Kick,
    PunishType_Ban
}
