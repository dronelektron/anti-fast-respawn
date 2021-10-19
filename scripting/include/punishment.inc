#if defined _punishment_included_
 #endinput
#endif
#define _punishment_included_

#define SOUND_BLOCK "physics/glass/glass_impact_bullet4.wav"
#define SOUND_UNBLOCK "physics/glass/glass_bottle_break2.wav"

// 0 128 255 255
#define COLOR_BLOCK 0x0080FFFF
// 255 255 255 255
#define COLOR_UNBLOCK 0xFFFFFFFF

#define PUNISH_TIMER_INTERVAL 1.0

enum PunishType {
    PunishType_Freeze,
    PunishType_Kick,
    PunishType_Ban
}
