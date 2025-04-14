/* ===========================================
Name: Zombie Darkness
Type: Gameplay
Author: Dias Pendragon
============================================ */

// #define REGISTER_BOT // buggy. don't enable it

enum
{
	DAY_NONE = 0,
	DAY_LIGHT,
	DAY_NIGHT,
	DAY_AFTER
}

enum
{
	STATUS_HEALTH = 1,
	STATUS_SPEED,
	STATUS_STRENGTH
}

enum
{
	HEALTH_NONE = 0,
	HEALTH_HEALING,
	HEALTH_DRAINING
}

enum
{
	SPEED_NONE = 0,
	SPEED_INC,
	SPEED_DEC
}

enum
{
	STRENGTH_NONE = 0,
	STRENGTH_HARDENING,
	STRENGTH_WEAKENING
}

enum
{
	class_name = 0,
	class_desc,
	class_speed,
	class_gravity,
	class_knockback,
	class_defense,
	class_healthregen,
	class_model,
	class_clawmodel,
	class_deathsound,
	class_painsound1,
	class_painsound2,
	class_stunsound,
	class_cost
}

enum
{
	WEAPON_PRIMARY = 1,
	WEAPON_SECONDARY,
	WEAPON_MELEE
}


enum
{
	TEAM_ZOMBIE = 1,
	TEAM_HUMAN
}

enum
{
	DAY_NONE = 0,
	DAY_LIGHT,
	DAY_NIGHT,
	DAY_AFTER
}

enum
{
	STATUS_HEALTH = 1,
	STATUS_SPEED,
	STATUS_STRENGTH
}

enum
{
	HEALTH_NONE = 0,
	HEALTH_HEALING,
	HEALTH_DRAINING
}

enum
{
	SPEED_NONE = 0,
	SPEED_INC,
	SPEED_DEC
}

enum
{
	STRENGTH_NONE = 0,
	STRENGTH_HARDENING,
	STRENGTH_WEAKENING
}

enum
{
	STAT_SCORE = 0,
	STAT_DMG
}

enum
{
	GRENADE_HE = 2014,
	GRENADE_FB,
	GRENADE_SG
}
// Normal Natives
native zd_get_user_zombie(id); // Return if User is A Zombie
native zd_get_user_zombieclass(id); // Return id class of zombie
native zd_set_user_health(id, Health, Full);
native zd_get_user_maxhealth(id);
native zd_set_user_nvg(id, Give, On, Sound, IgnoreHadNVG);
native zd_get_user_nvg(id, Have, On);
native zd_get_round_damage(id);
native zd_get_round_score(id);
native zd_set_user_power(id, Power);
native zd_get_user_power(id);
native zd_set_hudfastupdate(id, Fast);
native zd_get_hudfastupdate(id);
native zd_set_user_status(id, Status, Value);
native zd_get_user_status(id, Status);
native zd_get_daytime();
native zd_set_fakeattack(id);
native zd_get_zombie_stun(id);
native zd_get_zombie_slowdown(id);
native zd_get_user_nightstalker(id);

native Array:zd_get_arrayid(Attribute);

// Register Natives
native zd_register_zombieclass(const Name[], const Desc[], Float:Speed, Float:Gravity, Float:Knockback, Float:Defense, HealthRegen, const Model[], const ClawModel[], const DeathSound[], const PainSound1[], const PainSound2[], const StunSound[], Cost);

// Forward
forward zd_user_preinfect(id, infector, infection);
forward zd_user_infected(id, infector, infection);
forward zd_user_spawned(id, Zombie);
forward zd_user_died(id, attacker, PermanentDeath);
forward zd_user_nvg(id, on, zombie);

forward zd_zombieclass_unactive(Id, ClassID);
forward zd_zombieclass_active(Id, ClassID);

forward zd_zombie_stun(id);
forward zd_zombie_slowdown(id);
forward zd_nightmare(DayTime);

forward zd_round_new();
forward zd_round_start();
forward zd_game_start();
forward zd_round_end(CsTeams:WinTeam);

forward zd_round_damage(id, Damage);
forward zd_user_nightstalker(id)

// Weapon
native zd_weapon_register(const Name[], Type, BasedOn, Cost);
native zd_weapon_get_cswid(id, ItemID);
forward zd_weapon_bought(id, ItemID);
forward zd_weapon_remove(id, ItemID);
forward zd_weapon_addammo(id, ItemID);