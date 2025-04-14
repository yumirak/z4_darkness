#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <xs>
#include <reapi>
#include <ZombieDarkness>

#define PLUGIN "Zombie Darkness"
#define VERSION "2.0"
#define AUTHOR "Dias Pendragon"

#define GAME_FOLDER "ZombieDarkness"
#define SETTING_FILE "ZombieDarkness.ini"
#define CLASSSETTING_FILE "ZombieDarkness_Classes.ini"
#define CONFIG_FILE "ZombieDarkness.cfg"
#define LANG_FILE "ZombieDarkness.txt"

#define LANG LANG_SERVER
#define GAMENAME "Zombie Darkness 2"

// OffSet
#define PDATA_SAFE 2
#define OFFSET_LINUX 5
#define OFFSET_CSTEAMS 114
const OFFSET_CSDEATHS = 444
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

// Task
#define TASK_COUNTDOWN 1401
#define TASK_CHANGECLASS 1402
#define TASK_REVIVE 1645
#define TASK_REVIVE_EFFECT 1404
#define TASK_TIMECHECK 1840
#define TASK_GAMENOTICE 1841
#define TASK_NIGHTMARE 1842
#define TASK_STUN 1843
#define TASK_SLOWDOWN 1844

#define TEAMCHANGE_DELAY 0.1
#define TASK_TEAMMSG 200
#define ID_TEAMMSG (taskid - TASK_TEAMMSG)

#define CLASS_ATTRIBUTES 14



// Loaded Configs
new g_MinPlayer, g_CountDown_Time
new g_HumanHealth, g_HumanArmor, Float:g_HumanGravity, Array:HumanModel
new Float:g_HE_DmgMulti, g_FB_OnImpact, Float:g_FB_KnockRange, g_FB_KnockPower, g_FB_ExpSound[64], g_SG_DmgPerSec, Float:g_SG_DmgRange
new g_ZombieRandomClass, g_ZombieClassSelectTime, g_ZombieInfectRewardMoney, g_NightHealthIncPer, g_Zombie_FirstMaxHealth, g_Zombie_FirstMinHealth,
g_ZombieMaxHealth, g_ZombieMinHealth, g_Zombie_MinArmor, g_Zombie_MaxArmor, Float:g_ZombieSlowdownTime
new Float:g_StunTime, g_StunEfSpr[64], g_StunClawAnim, g_StunClawAfterAnim, g_StunPlayerAnim
new g_NVG_Alpha, g_NVG_HumanColor[3], g_NVG_ZombieColor[3]
new g_ZombieRespawnTime, g_ZombieRespawnSpr[64], g_ZombieRespawnSprID
new Float:g_CFDmgMulti, g_CFAvaiPer, g_CFDecPer01S, g_CFSound[64], g_CFEfSpr[64], g_CFEfSprId
new g_KB_Damage, g_KB_WeaponPower, g_KB_ZombieClass, g_KB_ZVEL, Float:g_KB_Ducking, Float:g_KB_Distance
new S_GameCount[64], S_GameStart[64], S_Nightmare[64], S_Daylight[64], S_PlaneDrop[64], Array:S_WinHuman, Array:S_WinZombie, 
Array:S_Infection, S_MessageHuman[64], S_MessageZombie[64], S_SkillAvailable[64], Array:S_ZombieComing,
Array:S_ZombieComeBack, Array:S_ClawSwing, Array:S_ClawHit, Array:S_ClawWall,
Array:S_KickMiss, Array:S_KickHit, Array:S_KickWall, Array:GameSky

// SpawnPoint System
new Float:g_PlayerSpawn_Point[64][3], g_PlayerSpawn_Count

// Main Vars
new g_Connected, g_IsAlive, g_Countdown
new g_GameStarted, g_InfectionStart, g_GameEnded, g_CurrentGameLight, g_CountTime, g_ZombieClass_Count
new g_Joined, g_IsZombie, g_PermanentDeath, g_CanChooseClass, g_Has_NightVision, g_UsingNVG, g_ClawA
new g_MaxHealth[33], g_MaxArmor[33], g_TeamScore[4], g_HumanModel[33], g_ZombieClass[33], g_OldZombieClass[33]
new Array:ZombieName, Array:ZombieDesc, Array:ZombieGravity, Array:ZombieSpeed, Array:ZombieKnockback, Array:ZombieDefense, Array:ZombieHealthRegen,
Array:ZombieModel, Array:ZombieClawModel, Array:ZombieDeathSound, Array:ZombiePainSound1, Array:ZombiePainSound2, Array:ZombieStunSound, Array:ZombieCost
new g_MaxPlayers, g_MsgSayText, g_MsgScoreInfo, g_MsgDeathMsg, g_MsgScreenFade, g_MsgScoreAttrib, g_CvarPointer_RoundTime,
g_fwResult, Float:SoundDelay_Notice, m_iBlood[2], g_Round, g_UsingCF, g_Respawning, g_RespawnTime[33], g_RespawnFromDeath
new g_Forward_Infected, g_Forward_Spawned, g_Forward_Died, g_Forward_NVG, g_Forward_ClassUnActive, g_Forward_ClassActive, g_Forward_Stun, g_Forward_Slowdown,
g_Forward_RoundNew, g_Forward_RoundStart, g_Forward_GameStart, g_Forward_RoundEnd, g_Forward_RoundDamage
new g_AdrenalinePower[33], Float:g_AdrenalineIncreaseTime[33], Float:g_AdrenalineIncreaseTime2[33], g_DayTime, g_HudFastUpdate
new g_HealthStatus[33], g_SpeedStatus[33], g_StrengthStatus[33], g_RoundStat[33][3], Float:HealthRegenTime[33], 
g_AddHealth[33], g_Stunning, g_TempingAttack, g_MyEntity[33], g_ShockWave_SprID, g_Slowdown, g_FastAllow, 
g_Forward_Nightmare, g_Forward_PreInfect, g_UnlockedClass[33][16]
#if defined REGISTER_BOT
new g_BotHamRegister
#endif
/*
// NightStakler
new g_HiddenName[32], g_HiddenDesc[32], Float:g_HiddenGravity, Float:g_HiddenSpeed, Float:g_HiddenKnockback, Float:g_HiddenDefense, g_HiddenHealthRegen,
g_HiddenModel[64], g_HiddenClawModel[64], g_HiddenDeathSound[64], g_HiddenPainSound1[64], g_HiddenPainSound2[64], g_HiddenStunSound[64]
new g_IsNightStalker, g_Forward_NightStalker*/

// HUD
#define HUD_WIN_X -1.0
#define HUD_WIN_Y 0.20
#define HUD_NOTICE_X -1.0
#define HUD_NOTICE_Y 0.25
#define HUD_NOTICE2_X -1.0
#define HUD_NOTICE2_Y 0.70
#define HUD_SCORE_X -1.0 
#define HUD_SCORE_Y 0.0
#define HUD_ADRENALINE_X -1.0
#define HUD_ADRENALINE_Y 0.85
#define HUD_HELPERA_X 0.01
#define HUD_HELPERA_Y 0.40
#define HUD_SD_X 0.87
#define HUD_SD_Y 0.80

new g_Hud_SD, g_Hud_Adrenaline, g_Hud_Adv, g_Hud_DisAdv

// Block Round Event
new g_BlockedObj_Forward
new g_BlockedObj[15][32] =
{
        "func_bomb_target",
        "info_bomb_target",
        "info_vip_start",
        "func_vip_safetyzone",
        "func_escapezone",
        "hostage_entity",
        "monster_scientist",
        "func_hostage_rescue",
        "info_hostage_rescue",
        "env_fog",
        "env_rain",
        "env_snow",
        "item_longjump",
        "func_vehicle",
        "func_buyzone"
}

new const CS_TEAM_NAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }

// Knockback
new Float:kb_weapon_power[] = 
{
	-1.0,	// ---
	2.4,	// P228
	-1.0,	// ---
	6.5,	// SCOUT
	-1.0,	// ---
	8.0,	// XM1014
	-1.0,	// ---
	2.3,	// MAC10
	5.0,	// AUG
	-1.0,	// ---
	2.4,	// ELITE
	2.0,	// FIVESEVEN
	2.4,	// UMP45
	5.3,	// SG550
	5.5,	// GALIL
	5.5,	// FAMAS
	2.2,	// USP
	2.0,	// GLOCK18
	10.0,	// AWP
	2.5,	// MP5NAVY
	5.2,	// M249
	8.0,	// M3
	5.0,	// M4A1
	2.4,	// TMP
	6.5,	// G3SG1
	-1.0,	// ---
	5.3,	// DEAGLE
	5.0,	// SG552
	6.0,	// AK47
	-1.0,	// ---
	2.0		// P90
}

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

#define HEADSPR_CLASSNAME "headspr"

// Hardcode Config
new const GameLight[7][2] = { "b", "c", "d", "e", "f", "g", "h" }
new const SoundNVG[2][32] = { "items/nvg_off.wav", "items/nvg_on.wav"}
// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }
			
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	
	// Event
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_event("TextMsg", "Event_GameRestart", "a", "2=#Game_will_restart_in")	
	//register_event("DeathMsg", "Event_Death", "a")
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	register_logevent("Event_RoundEnd", 2, "1=Round_End")	
	
	// Fakemeta
	unregister_forward(FM_Spawn, g_BlockedObj_Forward)
	register_forward(FM_GetGameDescription, "fw_GetGameDesc")
	register_forward(FM_EmitSound, "fw_EmitSound")	
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")	
	register_forward(FM_SetModel, "fw_SetModel")
	register_think(HEADSPR_CLASSNAME, "fw_Entity_Think")
	
	// Ham
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_PlayerTraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_PlayerTraceAttack_Post", 1)
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	RegisterHam(Ham_Think, "grenade", "fw_GrenadeThink")
	RegisterHam(Ham_Touch, "grenade", "fw_GrenadeTouch")
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	
	// Message
	register_message(get_user_msgid("DeathMsg") , "Message_DeathMsg")
	register_message(get_user_msgid("StatusIcon"), "Message_StatusIcon")
	register_message(get_user_msgid("TeamScore"), "Message_TeamScore")
	register_message(get_user_msgid("Health"), "Message_Health")
	register_message(get_user_msgid("ClCorpse"), "Message_ClCorpse")

	// Team Mananger
	register_clcmd("chooseteam", "CMD_JoinTeam")
	register_clcmd("jointeam", "CMD_JoinTeam")
	register_clcmd("joinclass", "CMD_JoinTeam")	
	
	// Collect Spawns Point
	collect_spawns_ent("info_player_start")
	collect_spawns_ent("info_player_deathmatch")
	
	// Create Forwards
	g_Forward_PreInfect = CreateMultiForward("zd_user_preinfect", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forward_Infected = CreateMultiForward("zd_user_infected", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forward_Spawned = CreateMultiForward("zd_user_spawned", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward_Died = CreateMultiForward("zd_user_died", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forward_NVG = CreateMultiForward("zd_user_nvg", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forward_ClassUnActive = CreateMultiForward("zd_zombieclass_unactive", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward_ClassActive = CreateMultiForward("zd_zombieclass_active", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward_RoundNew = CreateMultiForward("zd_round_new", ET_IGNORE)
	g_Forward_RoundStart = CreateMultiForward("zd_round_start", ET_IGNORE)
	g_Forward_GameStart = CreateMultiForward("zd_game_start", ET_IGNORE)
	g_Forward_RoundEnd = CreateMultiForward("zd_round_end", ET_IGNORE, FP_CELL)
	g_Forward_RoundDamage = CreateMultiForward("zd_round_damage", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward_Stun = CreateMultiForward("zd_zombie_stun", ET_IGNORE, FP_CELL)
	g_Forward_Slowdown = CreateMultiForward("zd_zombie_slowdown", ET_IGNORE, FP_CELL)
	//g_Forward_NightStalker = CreateMultiForward("zd_user_nightstalker", ET_IGNORE, FP_CELL)
	g_Forward_Nightmare = CreateMultiForward("zd_nightmare", ET_IGNORE, FP_CELL)
	
	// Vars
	g_MaxPlayers = get_maxplayers()
	g_CvarPointer_RoundTime = get_cvar_pointer("mp_roundtime")
	
	g_MsgScoreInfo = get_user_msgid("ScoreInfo")
	g_MsgDeathMsg = get_user_msgid("DeathMsg")	
	g_MsgSayText = get_user_msgid("SayText")
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	g_MsgScoreAttrib = get_user_msgid("ScoreAttrib")
	
	// Hud
	g_Hud_SD = CreateHudSyncObj(2)
	g_Hud_Adrenaline = CreateHudSyncObj(3)
	g_Hud_Adv = CreateHudSyncObj(4)
	g_Hud_DisAdv = CreateHudSyncObj(5)
	
	// CMD
	register_clcmd("nightvision", "CMD_NightVision")
	register_impulse(201, "CMD_Spray")
	
	// First Setting
	Round_Setting()
	set_task(1.0, "GM_Time", _, _, _, "b")
	// Patch Round Infinity
	// GM_EndRound_Block(true)
}

public plugin_precache()
{
	// Create Array
	HumanModel = ArrayCreate(32, 1)
	S_WinHuman = ArrayCreate(64, 1)
	S_WinZombie = ArrayCreate(64, 1)
	S_Infection = ArrayCreate(64, 1)
	S_ZombieComing = ArrayCreate(64, 1)
	S_ZombieComeBack = ArrayCreate(64, 1)
	S_ClawSwing = ArrayCreate(64, 1)
	S_ClawHit = ArrayCreate(64, 1)
	S_ClawWall = ArrayCreate(64, 1)
	S_KickMiss = ArrayCreate(64, 1)
	S_KickHit = ArrayCreate(64, 1)
	S_KickWall = ArrayCreate(64, 1)
	
	// Zombies
	ZombieName = ArrayCreate(32, 1)
	ZombieDesc = ArrayCreate(32, 1)
	ZombieGravity = ArrayCreate(1, 1)
	ZombieSpeed = ArrayCreate(1, 1)
	ZombieKnockback = ArrayCreate(1, 1)
	ZombieDefense = ArrayCreate(1, 1)
	ZombieHealthRegen = ArrayCreate(1, 1)
	ZombieModel = ArrayCreate(64, 1)
	ZombieClawModel = ArrayCreate(64, 1)
	ZombieDeathSound = ArrayCreate(64, 1)
	ZombiePainSound1 = ArrayCreate(64, 1)
	ZombiePainSound2 = ArrayCreate(64, 1)
	ZombieStunSound = ArrayCreate(64, 1)
	ZombieCost = ArrayCreate(1, 1)
	
	// Evenironment
	GameSky = ArrayCreate(16, 1)
	
	// Register Forward
	g_BlockedObj_Forward = register_forward(FM_Spawn, "fw_BlockedObj_Spawn")	
	
	// Cache
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
	g_ShockWave_SprID = precache_model("sprites/shockwave.spr")
	
	// Load Setting
	Load_GameSetting()
	//Load_Class_NightStalker()
	Precache_GameSetting()
	//Precache_Class_NightStalker()
	Environment_Setting()
}

public plugin_cfg()
{
	set_cvar_num("mp_limitteams", 0)
	set_cvar_num("mp_autoteambalance", 0)
	set_cvar_num("sv_maxspeed", 999)
	
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)	
	
	// Exec
	static FileUrl[128]
	
	get_configsdir(FileUrl, sizeof(FileUrl))
	formatex(FileUrl, sizeof(FileUrl), "%s/%s/%s", FileUrl, GAME_FOLDER, CONFIG_FILE)
	
	server_exec()
	server_cmd("exec %s", FileUrl)
	
	// Sky
	static sky[64]; ArrayGetString(GameSky, Get_RandomArray(GameSky), sky, sizeof(sky))
	set_cvar_string("sv_skyname", sky)
	
	g_Round = 1
	
	// New Round
	Event_NewRound()
}

public plugin_natives()
{
	register_native("zd_get_user_zombie", "Native_GetUserZombie", 1)
	register_native("zd_get_user_zombieclass", "Native_GetZombieClass", 1)
	register_native("zd_set_user_health", "Native_SetUserHealth", 1)
	register_native("zd_get_user_maxhealth", "Native_GetUserHealth", 1)
	
	register_native("zd_set_user_nvg", "Native_SetNVG", 1)
	register_native("zd_get_user_nvg", "Native_GetNVG", 1)
	
	register_native("zd_get_round_damage", "Native_GetRoundDamage", 1)
	register_native("zd_get_round_score", "Native_GetRoundScore", 1)
	
	register_native("zd_set_user_power", "Native_SetPower", 1)
	register_native("zd_get_user_power", "Native_GetPower", 1)
	
	register_native("zd_set_hudfastupdate", "Native_SHudFastUpdate", 1)
	register_native("zd_get_hudfastupdate", "Native_GHudFastUpdate", 1)	
	
	register_native("zd_set_user_status", "Native_SetStatus", 1)
	register_native("zd_get_user_status", "Native_GetStatus", 1)
	register_native("zd_get_daytime", "Native_GetDayTime", 1)
	
	register_native("zd_set_fakeattack", "Native_SetFakeAttack", 1)
	register_native("zd_get_zombie_stun", "Native_GetStun", 1)
	register_native("zd_get_zombie_slowdown", "Native_GetSlowDown", 1)
	
	register_native("zd_get_user_nightstalker", "Native_Get_NightStalker", 1)
	register_native("zd_get_arrayid", "Native_GetArrayID", 1)
	
	register_native("zd_register_zombieclass", "Native_Register_ZombieClass", 1)
}

public Round_Setting()
{
	g_GameStarted = 0
	g_GameEnded = 0
	g_InfectionStart = 0
	g_CurrentGameLight = sizeof(GameLight) - 1
}

public fw_BlockedObj_Spawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED
	
	static Ent_Classname[64]
	pev(ent, pev_classname, Ent_Classname, sizeof(Ent_Classname))
	
	for(new i = 0; i < sizeof g_BlockedObj; i++)
	{
		if (equal(Ent_Classname, g_BlockedObj[i]))
		{
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public Environment_Setting()
{
	new BufferA[64], BufferB[128]
	
	// Weather & Sky
	if(Setting_Load_Int(SETTING_FILE, "Environment", "ENV_RAIN")) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	if(Setting_Load_Int(SETTING_FILE, "Environment", "ENV_SNOW")) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))	
	if(Setting_Load_Int(SETTING_FILE, "Environment", "ENV_FOG"))
	{
		remove_entity_name("env_fog")
		
		new D_FogDensity[8], D_FogColor[8]
		Setting_Load_String(SETTING_FILE, "Environment", "ENV_FOG_DENSITY", D_FogDensity, sizeof(D_FogDensity))
		Setting_Load_String(SETTING_FILE, "Environment", "ENV_FOG_COLOR", D_FogColor, sizeof(D_FogColor))
		
		new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		if (pev_valid(ent))
		{
			fm_set_kvd(ent, "density", D_FogDensity, "env_fog")
			fm_set_kvd(ent, "rendercolor", D_FogColor, "env_fog")
		}
	}	
	
	// Sky
	Setting_Load_StringArray(SETTING_FILE, "Environment", "ENV_SKY", GameSky)
	
	for(new i = 0; i < ArraySize(GameSky); i++)
	{
		ArrayGetString(GameSky, i, BufferA, charsmax(BufferA)); 
		
		// Preache custom sky files
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sbk.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sdn.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sft.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%slf.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%srt.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sup.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)		
	}		
}

// =================== CORE FORWARD ======================
// =======================================================
public client_connect(id)
{
	UnSet_BitVar(g_Joined, id)
	Reset_PlayerStart(id)
}

public client_putinserver(id)
{
	Set_BitVar(g_Connected, id)
	UnSet_BitVar(g_IsAlive, id)

#if defined REGISTER_BOT
	if(!g_BotHamRegister && is_user_bot(id))
	{
		g_BotHamRegister = 1
		set_task(0.1, "Bot_RegisterHam", id)
	}
#endif

	g_HumanModel[id] = Get_RandomArray(HumanModel)
}

public client_disconnect(id)
{
	UnSet_BitVar(g_Connected, id)
	UnSet_BitVar(g_IsAlive, id)
	UnSet_BitVar(g_Joined, id)
	
	Reset_PlayerStart(id)
}

#if defined REGISTER_BOT
public Bot_RegisterHam(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_PlayerTakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_PlayerTraceAttack")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_PlayerTraceAttack_Post", 1)
}
#endif

public GM_Time()
{
	if(g_GameStarted && (Get_TotalInPlayer(GetPlayersFlags:GetPlayers_None) < g_MinPlayer))
	{
		g_GameStarted = 0
		g_GameEnded = 0
		g_InfectionStart = 0
	}
	
	if(!g_GameStarted && (Get_TotalInPlayer(GetPlayersFlags:GetPlayers_None) >= g_MinPlayer)) // START GAME NOW :D
	{
		g_GameStarted = 1
		g_InfectionStart = 0
		End_Round(5.0, 1, CS_TEAM_UNASSIGNED)
	}
	
	// Show HUD
	//Show_ScoreHud()
	Show_PlayerHUD()
	
	// Check Gameplay
	Check_Gameplay()
}

public Reset_PlayerStart(id)
{
	UnSet_BitVar(g_IsZombie, id)
	//UnSet_BitVar(g_IsNightStalker, id)
	UnSet_BitVar(g_PermanentDeath, id)
	UnSet_BitVar(g_CanChooseClass, id)
	UnSet_BitVar(g_Has_NightVision, id)
	UnSet_BitVar(g_UsingNVG, id)
	UnSet_BitVar(g_ClawA, id)
	UnSet_BitVar(g_UsingCF, id)
	UnSet_BitVar(g_Respawning, id)
	UnSet_BitVar(g_RespawnFromDeath, id)
	UnSet_BitVar(g_Stunning, id)
	UnSet_BitVar(g_TempingAttack, id)
	
	g_ZombieClass[id] = 0
	g_OldZombieClass[id] = 0
	g_AdrenalinePower[id] = 0
	g_HealthStatus[id] = 0
	g_SpeedStatus[id] = 0
	g_StrengthStatus[id] = 0
	g_RoundStat[id][STAT_SCORE] = 0
	g_RoundStat[id][STAT_DMG] = 0
	
	remove_task(id+TASK_REVIVE)
	remove_task(id+TASK_CHANGECLASS)
	remove_task(id+TASK_REVIVE_EFFECT)
	remove_task(id+TASK_SLOWDOWN)
	
	for(new i = 0; i < 16; i++)
		g_UnlockedClass[id][i] = 0
}

public Show_ScoreHud()
{
	static ScoreHud[80]
	
	formatex(ScoreHud, sizeof(ScoreHud), "%L", LANG, "HUD_DAY", g_Round)
	set_dhudmessage(250, 250, 250, HUD_SCORE_X, HUD_SCORE_Y, 0, 1.0, 1.0)
	show_dhudmessage(0, ScoreHud)
}

public Check_Gameplay()
{
	if(!g_GameStarted || g_GameEnded || !g_InfectionStart)
		return
		
	if(Get_PlayerCount(GetPlayersFlags:GetPlayers_ExcludeDead, 2) <= 0) End_Round(5.0, 0, CS_TEAM_T)
	else if(Get_ZombieAlive2() <= 0) End_Round(5.0, 0, CS_TEAM_CT)
}

// ======================== EVENT ========================
// =======================================================
public Event_NewRound()
{
	// Reset Light
	g_CurrentGameLight = sizeof(GameLight) - 1
	//set_lights(GameLight[g_CurrentGameLight])
	
	remove_task(1840)
	remove_task(TASK_NIGHTMARE)
	
	g_GameEnded = 0
	g_InfectionStart = 0
	g_Countdown = 0
	g_DayTime = DAY_LIGHT
	
	StopSound(0)
	
	// Gameplay Handle
	Check_GameStart()
	
	ExecuteForward(g_Forward_RoundNew, g_fwResult)
}

public Event_RoundStart()
{
	if(!g_GameStarted || g_GameEnded)
		return
	if(g_ZombieClass_Count <= 0)
	{
		client_printc(0, "!g[%s]!n %L", GAMENAME, LANG, "ERROR_NOCLASS")
		return
	}
	
	g_Countdown = 1

	set_task(get_pcvar_float(g_CvarPointer_RoundTime) * 60.0, "Event_TimeUp", 1840)
	ExecuteForward(g_Forward_RoundStart, g_fwResult)
}

public Check_GameStart()
{
	if(!g_GameStarted || g_GameEnded)
		return
	if(g_ZombieClass_Count <= 0)
		return 
		
	PlaySound(0, S_GameStart)
	Start_Countdown()
}

public Event_TimeUp()
{
	if(!g_GameStarted || g_GameEnded)
		return
		
	End_Round(5.0, 0, CS_TEAM_CT)
}

public Event_RoundEnd()
{
	g_GameEnded = 1
	
	remove_task(1840)
	remove_task(TASK_GAMENOTICE)
	remove_task(TASK_NIGHTMARE)
	
	for(new i = 0; i < g_MaxPlayers; i++) UnSet_BitVar(g_RespawnFromDeath, i)
	
	ExecuteForward(g_Forward_RoundEnd, g_fwResult, CS_TEAM_UNASSIGNED)
}

public Event_GameRestart()
{
	g_GameEnded = 1
	
	remove_task(1840)
	remove_task(TASK_GAMENOTICE)
	remove_task(TASK_NIGHTMARE)
	
	for(new i = 0; i < g_MaxPlayers; i++) UnSet_BitVar(g_RespawnFromDeath, i)
	
	ExecuteForward(g_Forward_RoundEnd, g_fwResult, CS_TEAM_UNASSIGNED)
}

public Event_Death()
{
	static Attacker, Victim
	
	Attacker = read_data(1); 
	Victim = read_data(2)
	
	UnSet_BitVar(g_IsAlive, Victim)
	
	if(g_DayTime == DAY_LIGHT || g_DayTime == DAY_AFTER) // Daylight
	{
		if(!Get_BitVar(g_UsingCF, Attacker)) 
		{
			UnSet_BitVar(g_PermanentDeath, Victim)
			Set_BitVar(g_Respawning, Victim)
			
			UpdateFrags(Attacker, Victim, -1, -1, 1)
		} else {
			Set_BitVar(g_PermanentDeath, Victim)
			UnSet_BitVar(g_Respawning, Victim)
			
			UpdateFrags(Attacker, Victim, 3, 3, 1)
			g_RoundStat[Attacker][STAT_SCORE] += 3
		}
	} else { // Night
		UnSet_BitVar(g_PermanentDeath, Victim)
		Set_BitVar(g_Respawning, Victim)
			
		UpdateFrags(Attacker, Victim, -1, -1, 1)
	}

	set_task(0.5, "Check_ZombieDeath", Victim+TASK_REVIVE)
	
	// Exec
	ExecuteForward(g_Forward_Died, g_fwResult, Victim, Attacker, Get_BitVar(g_PermanentDeath, Victim))
	
	// Check Gameplay
	Check_Gameplay()
}

public Start_Countdown()
{
	g_CountTime = g_CountDown_Time
	
	remove_task(TASK_COUNTDOWN)
	CountingDown()
}

public CountingDown()
{
	if(!g_GameStarted || g_GameEnded)
		return

	if(g_CountTime  <= 0)
	{
		Start_Game_Now()
		return
	}
	
	client_print(0, print_center, "%L", LANG, "MESSAGE_GAME_COUNTING", g_CountTime)
		
	if(g_CountTime == 14)
	{
		PlaySound(0, S_MessageHuman)
		
		set_dhudmessage(0, 48, 255, HUD_NOTICE_X, HUD_NOTICE_Y, 0, 6.0, 6.0, 0.5, 1.0)
	
		static RandomNum; RandomNum = random_num(1, 3)
		if(RandomNum == 1) show_dhudmessage(0, "%L", LANG, "NOTICE_ROUNDSTART1")
		else if(RandomNum == 2) show_dhudmessage(0, "%L", LANG, "NOTICE_ROUNDSTART2")
		else if(RandomNum == 3) show_dhudmessage(0, "%L", LANG, "NOTICE_ROUNDSTART3")
		
		// Give Grenade
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!Get_BitVar(g_IsAlive, i))
				continue
			
			// Give Grenade
			give_item(i, "weapon_hegrenade")
			give_item(i, "weapon_flashbang")
			give_item(i, "weapon_smokegrenade")
		}
	}
	
	if(g_CountTime <= 10)
	{
		static Sound[64]; format(Sound, charsmax(Sound), S_GameCount, g_CountTime)
		PlaySound(0, Sound)
	} 
	
	if(g_Countdown) g_CountTime--
	set_task(1.0, "CountingDown", TASK_COUNTDOWN)
}

public Start_Game_Now()
{
	static TotalPlayer; TotalPlayer = Get_TotalInPlayer(GetPlayersFlags:GetPlayers_ExcludeDead)
	static ZombieNumber; ZombieNumber = clamp(floatround(float(TotalPlayer) / 10.0, floatround_ceil), 1, 3)
	
	static PlayerList[32], PlayerNum; PlayerNum = 0
	for(new i = 0; i < ZombieNumber; i++)
	{
		get_players(PlayerList, PlayerNum, "a")
		Set_Player_Zombie(PlayerList[random(PlayerNum)], -1, 1, 0, 0)
	}
	
	g_InfectionStart = 1
	
	// Check Team & Show Message: Survival Time
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!Get_BitVar(g_IsAlive, i))
			continue
		if(Get_BitVar(g_IsZombie, i))
			continue
			
		// Show Message
		set_dhudmessage(85, 255, 85, HUD_NOTICE2_X, HUD_NOTICE2_Y, 2, 0.1, 3.0, 0.01, 0.5)
		show_dhudmessage(i, "%L", LANG, "MESSAGE_ALIVETIME")

		if(cs_get_user_team(i) == CS_TEAM_CT)
			continue
			
		// Set Team
		set_team(i, TEAM_HUMAN)
	}	
	
	// Set Time
	set_task(random_float(30.0, 60.0), "Starting_Nightmare", TASK_NIGHTMARE)
	set_task(3.0, "Show_GameNotice", TASK_GAMENOTICE)
	
	// Play Ambience Sound
	PlaySound(0, S_Daylight)
	
	// Exec Forward
	ExecuteForward(g_Forward_GameStart, g_fwResult)
	ExecuteForward(g_Forward_Nightmare, g_fwResult, DAY_LIGHT)
}

public Show_GameNotice()
{
	set_dhudmessage(0, 48, 255, HUD_NOTICE_X, HUD_NOTICE_Y, 0, 6.0, 6.0, 0.5, 1.0)
	
	new RandomNum, NoticeA[80], NoticeB[80]; RandomNum = random_num(1, 3)
	if(RandomNum == 1) 
	{
		formatex(NoticeA, sizeof(NoticeA), "%L", LANG, "NOTICE_GAMESTART1")
		formatex(NoticeB, sizeof(NoticeB), "%L", LANG, "NOTICE_ZM_FIRSTZOMBIE1")
	} else if(RandomNum == 2) {
		formatex(NoticeA, sizeof(NoticeA), "%L", LANG, "NOTICE_GAMESTART2")
		formatex(NoticeB, sizeof(NoticeB), "%L", LANG, "NOTICE_ZM_FIRSTZOMBIE2")
	} else if(RandomNum == 3) {
		formatex(NoticeA, sizeof(NoticeA), "%L", LANG, "NOTICE_GAMESTART3")
		formatex(NoticeB, sizeof(NoticeB), "%L", LANG, "NOTICE_ZM_FIRSTZOMBIE3")
	}
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!Get_BitVar(g_IsAlive, i))
			continue
		if(!Get_BitVar(g_IsZombie, i))
		{
			PlaySound(i, S_MessageHuman)
			show_dhudmessage(i, NoticeA)
		} else {
			PlaySound(i, S_MessageZombie)
			show_dhudmessage(i, NoticeB)
		}
	}
}

public Check_ZombieDeath(id)
{
	id -= TASK_REVIVE
	
	if(!g_GameStarted || g_GameEnded || !g_InfectionStart)
		return
	if(!Get_BitVar(g_Connected, id) || Get_BitVar(g_IsAlive, id))
		return
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
	{
		if(pev(id, pev_deadflag) != 2)
		{
			set_task(0.5, "Check_ZombieDeath", id+TASK_REVIVE)
			return
		}
	
		// Do Handle Respawn
		set_user_nightvision(id, 0, 0, 1)
		
		if(Get_BitVar(g_PermanentDeath, id))
		{
			UnSet_BitVar(g_Respawning, id)
			client_print(id, print_center, "%L", LANG, "MESSAGE_CANT_REVIVE")	
		} else {
			Set_BitVar(g_Respawning, id)
			g_RespawnTime[id] = g_ZombieRespawnTime
	
			// Make Effect
			static Float:fOrigin[3]
			pev(id, pev_origin, fOrigin)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_SPRITE)
			engfunc(EngFunc_WriteCoord, fOrigin[0])
			engfunc(EngFunc_WriteCoord, fOrigin[1])
			engfunc(EngFunc_WriteCoord, fOrigin[2] + 16.0)
			write_short(g_ZombieRespawnSprID)
			write_byte(10)
			write_byte(255)
			message_end()
			
			set_task(2.0, "Revive_Effect", id+TASK_REVIVE_EFFECT)
			
			// Check Respawn
			Start_Revive(id+TASK_REVIVE)
			
			return
		}
	}
}

public Revive_Effect(id)
{
	id -= TASK_REVIVE_EFFECT
	
	if(!g_GameStarted || g_GameEnded || !g_InfectionStart)
		return
	if(!Get_BitVar(g_Connected, id) || Get_BitVar(g_IsAlive, id))
		return
	
	// Make Effect
	static Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2] + 16.0)
	write_short(g_ZombieRespawnSprID)
	write_byte(10)
	write_byte(255)
	message_end()
	
	set_task(2.0, "Revive_Effect", id+TASK_REVIVE_EFFECT)	
}

public Start_Revive(id)
{
	id -= TASK_REVIVE
	
	if(!g_GameStarted || g_GameEnded || !g_InfectionStart)
		return
	if(!Get_BitVar(g_Connected, id) || Get_BitVar(g_IsAlive, id))
		return
	if(!Get_BitVar(g_Respawning, id))
		return
	if(g_RespawnTime[id] <= 0.0)
	{
		Revive_Now(id+TASK_REVIVE)
		return
	}
		
	client_print(id, print_center, "%L", LANG, "MESSAGE_REVIVING", g_RespawnTime[id])
	
	g_RespawnTime[id]--
	set_task(1.0, "Start_Revive", id+TASK_REVIVE)
}

public Revive_Now(id)
{
	id -= TASK_REVIVE
	
	if(!g_GameStarted || g_GameEnded || !g_InfectionStart)
		return
	if(!Get_BitVar(g_Connected, id) || Get_BitVar(g_IsAlive, id))
		return
	if(!Get_BitVar(g_Respawning, id))
		return
		
	// Remove Task
	remove_task(id+TASK_REVIVE_EFFECT)
	UnSet_BitVar(g_Respawning, id)
	
	Set_BitVar(g_RespawnFromDeath, id)
	
	set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public Starting_Nightmare()
{
	PlaySound(0, S_Nightmare)
	
	g_FastAllow = 0
	Starting_Nightmare2()
}

public Starting_Nightmare2()
{
	if(g_CurrentGameLight == 1)
	{
		Nightmare_TruelyStart()
		return
	} else if(g_CurrentGameLight > 1) {
		g_CurrentGameLight--
		//set_lights(GameLight[g_CurrentGameLight])
		
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!Get_BitVar(g_Connected, i))
				continue
			if(Get_BitVar(g_UsingNVG, i))
				continue
				
			SetPlayerLight(i, GameLight[g_CurrentGameLight])
		}
	}
	
	set_task(3.0, "Starting_Nightmare2", TASK_NIGHTMARE)
}

public Nightmare_TruelyStart()
{
	g_DayTime = DAY_NIGHT
	
	// Notice
	new RandomNum, Notice[80], Notice2[80]; RandomNum = random_num(1, 3)
	if(RandomNum == 1) 
	{	
		formatex(Notice, sizeof(Notice), "%L", LANG, "NOTICE_HM_NIGHTSTART1")
		formatex(Notice2, sizeof(Notice2), "%L", LANG, "NOTICE_ZM_NIGHTSTART1")
	} else if(RandomNum == 2) {
		formatex(Notice, sizeof(Notice), "%L", LANG, "NOTICE_HM_NIGHTSTART2")
		formatex(Notice2, sizeof(Notice2), "%L", LANG, "NOTICE_ZM_NIGHTSTART2")
	} else if(RandomNum == 3) {
		formatex(Notice, sizeof(Notice), "%L", LANG, "NOTICE_HM_NIGHTSTART3")
		formatex(Notice2, sizeof(Notice2), "%L", LANG, "NOTICE_ZM_NIGHTSTART3")
	}

	//Select_NightStalker()
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!Get_BitVar(g_IsAlive, i))
			continue
		if(Get_BitVar(g_IsZombie, i)/* && !Get_BitVar(g_IsNightStalker, i)*/) // Only Zombie
		{
			set_dhudmessage(200, 0, 0, HUD_NOTICE_X, HUD_NOTICE_Y, 1, 6.0, 6.0, 0.25, 1.0)
			show_dhudmessage(i, Notice2)
			
			PlaySound(i, S_MessageZombie)
			
			// Increase Health Amount
			g_HealthStatus[i] = HEALTH_HEALING
			
			static AddHealth; AddHealth = floatround(float(g_MaxHealth[i]) * (float(g_NightHealthIncPer) / 100.0))
			
			g_MaxHealth[i] += AddHealth
			g_AddHealth[i] = AddHealth
			set_pev(i, pev_max_health, float(g_MaxHealth[i]))

			SetPlayerHealth(i, get_user_health(i) + AddHealth, 0)
		} else if(!Get_BitVar(g_IsZombie, i)/* && !Get_BitVar(g_IsNightStalker, i)*/) { // Human
			set_dhudmessage(0, 48, 255, HUD_NOTICE_X, HUD_NOTICE_Y, 1, 6.0, 6.0, 0.25, 1.0)
			show_dhudmessage(i, Notice)
			
			PlaySound(i, S_MessageHuman)
		}
	}

	remove_task(TASK_NIGHTMARE)
	
	set_task(6.0, "Set_AllowUpdate", TASK_NIGHTMARE)
	set_task(45.0, "Nightmare_MidNight", TASK_NIGHTMARE)
	
	ExecuteForward(g_Forward_Nightmare, g_fwResult, DAY_NIGHT)
}

/*public Select_NightStalker()
{
	static TotalHuman; TotalHuman = Get_PlayerCount(1, 2)
	static HiddenNumber; HiddenNumber = clamp(floatround(float(TotalHuman) / 10.0, floatround_ceil), 1, 3)
	
	new PlayerList[32], PlayerNum; 
	new NightStalker[3], NightStalkerNum
	
	
	// Select Night Stalker
	for(new i = 0; i < HiddenNumber; i++)
	{
		PlayerNum = 0

		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!Get_BitVar(g_IsAlive, i))
				continue
			if(!Get_BitVar(g_IsZombie, i))
				continue
			//if(Get_BitVar(g_IsNightStalker, i))
			//	continue
				
			PlayerList[PlayerNum] = i
			PlayerNum++
		}
		
		if(PlayerNum > 0) 
		{
			static Id; Id = PlayerList[random(PlayerNum)]
			Set_Player_NightStalker(Id, 0, 0)
			
			NightStalker[NightStalkerNum] = Id
			NightStalkerNum++
		}
	}
	
	if(Become) 
	{
		Set_Player_NightStalker(1, 0, 0)
		
		NightStalker[0] = 1
	}
	
	// Notice 
	new String[64], Name[32]
	if(NightStalkerNum == 1)
	{
		get_user_name(NightStalker[0], Name, sizeof(Name))
		formatex(String, sizeof(String), "%s", Name)
		
		client_print(0, print_center, "%L", LANG, "MESSAGE_NIGHTSTALKER_CHOSEN2A", String)
	} else if(NightStalkerNum == 2) {
		get_user_name(NightStalker[0], Name, sizeof(Name))
		formatex(String, sizeof(String), "%s", Name)
		
		get_user_name(NightStalker[1], Name, sizeof(Name))
		formatex(String, sizeof(String), "%s, %s", String, Name)
		
		client_print(0, print_center, "%L", LANG, "MESSAGE_NIGHTSTALKER_CHOSEN2B", String)
	} else if(NightStalkerNum == 3) {
		get_user_name(NightStalker[0], Name, sizeof(Name))
		formatex(String, sizeof(String), "%s", Name)
		
		get_user_name(NightStalker[1], Name, sizeof(Name))
		formatex(String, sizeof(String), "%s, %s", String, Name)
		
		get_user_name(NightStalker[2], Name, sizeof(Name))
		formatex(String, sizeof(String), "%s, %s", String, Name)
		
		client_print(0, print_center, "%L", LANG, "MESSAGE_NIGHTSTALKER_CHOSEN2B", String)
	}
}*/

/*
public Set_Player_NightStalker(id, Respawn, Stun)
{
	if(!Get_BitVar(g_IsAlive, id))
		return
		
	Reset_Player(id)
	
	// Set NightStalkre
	Set_BitVar(g_IsNightStalker, id)
	UnSet_BitVar(g_IsZombie, id)
	UnSet_BitVar(g_CanChooseClass, id)
	
	// UnActive Zombie Classes
	ExecuteForward(g_Forward_ClassUnActive, g_fwResult, id, g_ZombieClass[id])
	g_ZombieClass[id] = -1
	
	// Set Classic Info
	GM_Set_PlayerTeam(id, CS_TEAM_T)
	GM_Set_PlayerSpeed(id, g_HiddenSpeed, 1)
	
	static StartHealth, StartArmor; 
	StartHealth = g_MaxHealth[id]
	StartArmor = 0
	
	// Health Setting
	static TotalPlayer; TotalPlayer = Get_TotalInPlayer(1)
	static ZombieNumber; ZombieNumber = clamp(floatround(float(TotalPlayer) / 10.0, floatround_ceil), 1, 3)
	
	if(!Respawn && !Stun)
	{
		g_AdrenalinePower[id] = 100
		
		StartHealth = clamp((TotalPlayer / ZombieNumber) * 1000, g_Zombie_FirstMinHealth * 3, g_Zombie_FirstMaxHealth)
		StartArmor = clamp((TotalPlayer * 10), g_Zombie_MinArmor, g_Zombie_MaxArmor)
		
		//Increase Health Amount
		g_HealthStatus[id] = HEALTH_HEALING
	
		static AddHealth; 
		AddHealth = floatround(float(g_MaxHealth[id]) * (float(g_NightHealthIncPer) / 100.0))
	
		StartHealth += AddHealth
		g_AddHealth[id] = AddHealth
		
		// Play Sound
		PlaySound(id, g_HiddenDeathSound)
		
		// Nightstakler is chosen!
		PlaySound(id, S_MessageZombie)

		set_dhudmessage(200, 0, 0, HUD_NOTICE_X, HUD_NOTICE_Y, 1, 3.0, 3.0, 0.25, 1.0)
		show_dhudmessage(id, "%L", LANG, "MESSAGE_NIGHTSTALKER_CHOSEN1")
	} else {
		g_AdrenalinePower[id] = 50
	}
	
	g_MaxHealth[id] = StartHealth
	SetPlayerHealth(id, StartHealth, 1)
	cs_set_user_armor(id, StartArmor, CS_ARMOR_KEVLAR)
	
	set_pev(id, pev_gravity, g_HiddenGravity)
	
	// Set Model
	GM_Set_PlayerModel(id, g_HiddenModel)
	
	// Bug Fix
	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
	fm_set_user_rendering(id)
	
	if(!Stun)
	{
		// Strip zombies from guns and give them a knife
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")	
		
		// Play Draw Animation
		Set_WeaponAnim(id, 3)
		Set_Player_NextAttack(id, 0.75)
	}
	
	// Set NVG
	Set_Zombie_NVG(id, 1, 1, 0, 1)
	
	// Turn Off the FlashLight
	if (pev(id, pev_effects) & EF_DIMLIGHT) set_pev(id, pev_impulse, 100)
	else set_pev(id, pev_impulse, 0)	
	
	// Exec
	ExecuteForward(g_Forward_NightStalker, g_fwResult, id)
}*/

public Set_AllowUpdate()
{
	g_FastAllow = 1
}

public Nightmare_MidNight()
{
	g_CurrentGameLight = 0

	//set_lights(GameLight[g_CurrentGameLight])
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!Get_BitVar(g_Connected, i))
			continue
		if(Get_BitVar(g_UsingNVG, i))
			continue
			
		SetPlayerLight(i, GameLight[g_CurrentGameLight])
	}
	
	set_task(3.0, "Ending_Nightmare", TASK_NIGHTMARE)
}

public Ending_Nightmare()
{
	if(g_CurrentGameLight == (sizeof(GameLight) - 1))
	{
		Nightmare_TruelyEnd()
		return
	} else if(g_CurrentGameLight < (sizeof(GameLight) - 1)) {
		g_CurrentGameLight++
		//set_lights(GameLight[g_CurrentGameLight])
		
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!Get_BitVar(g_Connected, i))
				continue
			if(Get_BitVar(g_UsingNVG, i))
				continue
				
			SetPlayerLight(i, GameLight[g_CurrentGameLight])
		}
	}
	
	set_task(2.0, "Ending_Nightmare", TASK_NIGHTMARE)
}

public Nightmare_TruelyEnd()
{
	g_DayTime = DAY_AFTER
	g_FastAllow = 0
	
	AfterNight_Effect()
	remove_task(TASK_NIGHTMARE)
	
	PlaySound(0, S_PlaneDrop)
	
	ExecuteForward(g_Forward_Nightmare, g_fwResult, DAY_AFTER)
}

public AfterNight_Effect()
{
	// Notice
	new RandomNum, Notice[80], Notice2[80]; RandomNum = random_num(1, 3)
	if(RandomNum == 1) 
	{	
		formatex(Notice, sizeof(Notice), "%L", LANG, "NOTICE_HM_NIGHTEND1")
		formatex(Notice2, sizeof(Notice2), "%L", LANG, "NOTICE_ZM_NIGHTEND1")
	} else if(RandomNum == 2) {
		formatex(Notice, sizeof(Notice), "%L", LANG, "NOTICE_HM_NIGHTEND2")
		formatex(Notice2, sizeof(Notice2), "%L", LANG, "NOTICE_ZM_NIGHTEND2")
	} else if(RandomNum == 3) {
		formatex(Notice, sizeof(Notice), "%L", LANG, "NOTICE_HM_NIGHTEND3")
		formatex(Notice2, sizeof(Notice2), "%L", LANG, "NOTICE_ZM_NIGHTEND3")
	}
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!Get_BitVar(g_IsAlive, i))
			continue
		if(Get_BitVar(g_IsZombie, i)/* || Get_BitVar(g_IsNightStalker, i)*/) 
		{
			set_dhudmessage(200, 0, 0, HUD_NOTICE_X, HUD_NOTICE_Y, 0, 6.0, 6.0, 0.5, 1.0)
			
			PlaySound(i, S_MessageZombie)
			show_dhudmessage(i, Notice2)
			
			// Decrease Health Amount
			g_HealthStatus[i] = HEALTH_NONE
			
			g_MaxHealth[i] -= g_AddHealth[i]
			set_pev(i, pev_max_health, float(g_MaxHealth[i]))
			
			if(get_user_health(i) - g_AddHealth[i] > 0) 
				SetPlayerHealth(i, get_user_health(i) - g_AddHealth[i], 0)
				
			// Slowdown Zombies
			Set_BitVar(g_Slowdown, i)
			
			static Float:Speed, Float:Gravity; 
			if(Get_BitVar(g_IsZombie, i)) 
			{
				Speed = ArrayGetCell(ZombieSpeed, g_ZombieClass[i])
				Gravity = ArrayGetCell(ZombieGravity, g_ZombieClass[i])
			}/* else if(Get_BitVar(g_IsNightStalker, i)) {
				Speed = g_HiddenSpeed
				Gravity = g_HiddenGravity
			}*/
			
			set_maxspeed(i, Speed / 2.0)
			set_pev(i, pev_gravity, Gravity * 2.0)
			
			ExecuteForward(g_Forward_Slowdown, g_fwResult, i)
			set_task(g_ZombieSlowdownTime, "Reset_Slowdown", i+TASK_SLOWDOWN)
		} else {
			set_dhudmessage(0, 48, 255, HUD_NOTICE_X, HUD_NOTICE_Y, 0, 6.0, 6.0, 0.5, 1.0)
			
			PlaySound(i, S_MessageHuman)
			show_dhudmessage(i, Notice)
		}
	}
}

public Reset_Slowdown(id)
{
	id -= TASK_SLOWDOWN
	
	if(!Get_BitVar(g_IsAlive, id))
		return
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
	{	
		static Float:Speed, Float:Gravity; 
		if(Get_BitVar(g_IsZombie, id)) 
		{
			Speed = ArrayGetCell(ZombieSpeed, g_ZombieClass[id])
			Gravity = ArrayGetCell(ZombieGravity, g_ZombieClass[id])
		} /*else if(Get_BitVar(g_IsNightStalker, id)) {
			Speed = g_HiddenSpeed
			Gravity = g_HiddenGravity
		}*/
		
		set_maxspeed(id, Speed)
		set_pev(id, pev_gravity, Gravity)	
		
		UnSet_BitVar(g_Slowdown, id)
	}
}

// ======================= ENGINE ========================
// =======================================================
public client_PostThink(id)
{
	if(!Get_BitVar(g_Joined, id))
	{
		if(cs_get_user_team(id) == CS_TEAM_T) set_team(id, TEAM_HUMAN)
		return
	}
	if(!Get_BitVar(g_IsAlive, id))
		return
	if((Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/) && Get_BitVar(g_Stunning, id))
	{
		if(!(pev(id, pev_flags) & FL_DUCKING)) client_cmd(id, "+duck")
		
		return
	}
		
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/) Zombie_HealthRegen(id)
	else Human_CF(id)
	
	// Adrenaline Power
	if(g_AdrenalinePower[id] >= 100)
		return
	
	switch(g_DayTime)
	{
		case DAY_LIGHT:
		{
			if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
			{
				if(get_gametime() - 1.0 > g_AdrenalineIncreaseTime[id])
				{
					g_AdrenalinePower[id]++
					Show_AdrenalinePower2(id, 1.0)
					Check_AdrenalinePower(id, g_AdrenalinePower[id])
					
					g_AdrenalineIncreaseTime[id] = get_gametime()
				}
			} else {
				if(!Get_BitVar(g_HudFastUpdate, id))
				{
					if(get_gametime() - 1.0 > g_AdrenalineIncreaseTime[id])
					{
						g_AdrenalinePower[id]++
						Show_AdrenalinePower2(id, 1.0)
						Check_AdrenalinePower(id, g_AdrenalinePower[id])
						
						g_AdrenalineIncreaseTime[id] = get_gametime()
					}
				} else {
					if(get_gametime() - 0.1 > g_AdrenalineIncreaseTime[id])
					{
						Show_AdrenalinePower2(id, 0.1)
						Check_AdrenalinePower(id, g_AdrenalinePower[id])
						
						g_AdrenalineIncreaseTime[id] = get_gametime()
					}
				}
			}
		}
		case DAY_NIGHT:
		{
			if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
			{
				if(g_FastAllow)
				{
					if(get_gametime() - 0.25 > g_AdrenalineIncreaseTime[id])
					{
						g_AdrenalinePower[id]++
						Show_AdrenalinePower2(id, 0.25)
						Check_AdrenalinePower(id, g_AdrenalinePower[id])
						
						g_AdrenalineIncreaseTime[id] = get_gametime()
					}
				} else {
					if(get_gametime() - 0.25 > g_AdrenalineIncreaseTime[id])
					{
						g_AdrenalinePower[id]++
						Check_AdrenalinePower(id, g_AdrenalinePower[id])
						
						g_AdrenalineIncreaseTime[id] = get_gametime()
					}
					
					if(get_gametime() - 1.0 > g_AdrenalineIncreaseTime2[id])
					{
						Show_AdrenalinePower2(id, 1.0)
						g_AdrenalineIncreaseTime2[id] = get_gametime()
					}
				}
			} else {
				if(!Get_BitVar(g_HudFastUpdate, id))
				{
					if(get_gametime() - 1.0 > g_AdrenalineIncreaseTime[id])
					{
						g_AdrenalinePower[id]++
						Show_AdrenalinePower2(id, 1.0)
						Check_AdrenalinePower(id, g_AdrenalinePower[id])
						
						g_AdrenalineIncreaseTime[id] = get_gametime()
					}
				} else {
					if(get_gametime() - 0.1 > g_AdrenalineIncreaseTime[id])
					{
						Show_AdrenalinePower2(id, 0.1)
						Check_AdrenalinePower(id, g_AdrenalinePower[id])
						
						g_AdrenalineIncreaseTime[id] = get_gametime()
					}
				}
			}
		}
		case DAY_AFTER:
		{
			if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
			{
				if(get_gametime() - 1.0 > g_AdrenalineIncreaseTime[id])
				{
					g_AdrenalinePower[id]++
					Show_AdrenalinePower2(id, 1.0)
					Check_AdrenalinePower(id, g_AdrenalinePower[id])
					
					g_AdrenalineIncreaseTime[id] = get_gametime()
				}
			} else {
				if(!Get_BitVar(g_HudFastUpdate, id))
				{
					if(get_gametime() - 1.0 > g_AdrenalineIncreaseTime[id])
					{
						g_AdrenalinePower[id]++
						Show_AdrenalinePower2(id, 1.0)
						Check_AdrenalinePower(id, g_AdrenalinePower[id])
						
						g_AdrenalineIncreaseTime[id] = get_gametime()
					}
				} else {
					if(get_gametime() - 0.1 > g_AdrenalineIncreaseTime[id])
					{
						Show_AdrenalinePower2(id, 0.1)
						Check_AdrenalinePower(id, g_AdrenalinePower[id])
						
						g_AdrenalineIncreaseTime[id] = get_gametime()
					}
				}
			}
		}
	}
}

public Zombie_HealthRegen(id)
{
	if(g_DayTime == DAY_AFTER)
		return
		
	if(get_gametime() - 0.5 > HealthRegenTime[id])
	{
		if(get_user_health(id) < g_MaxHealth[id])
		{
			g_HealthStatus[id] = HEALTH_HEALING
			
			static NewHealth, RegenHealth;
			if(Get_BitVar(g_IsZombie, id)) RegenHealth = ArrayGetCell(ZombieHealthRegen, g_ZombieClass[id])
			//else RegenHealth = g_HiddenHealthRegen
			
			if(g_DayTime == DAY_LIGHT) NewHealth = get_user_health(id) + RegenHealth
			else if(g_DayTime == DAY_NIGHT) NewHealth = get_user_health(id) + (RegenHealth * 3)
		
			NewHealth = min(NewHealth, g_MaxHealth[id])
			SetPlayerHealth(id, NewHealth, 0)
			
			if(NewHealth >= g_MaxHealth[id]) g_HealthStatus[id] = HEALTH_NONE
		}
		
		HealthRegenTime[id] = get_gametime()
	}
}

public Human_CF(id)
{
	if(Get_BitVar(g_UsingCF, id) && g_AdrenalinePower[id] <= 0)
	{
		UnSet_BitVar(g_UsingCF, id)
		UnSet_BitVar(g_HudFastUpdate, id)
		
		return
	}
	
	if(!Get_BitVar(g_UsingCF, id))
		return
		
	if(get_gametime() - 0.1 > HealthRegenTime[id])
	{
		if(!Get_BitVar(g_HudFastUpdate, id)) Set_BitVar(g_HudFastUpdate, id)
		
		static NewPower; NewPower = g_AdrenalinePower[id] - g_CFDecPer01S
		NewPower = clamp(NewPower, 0, 100)
		
		g_AdrenalinePower[id] = NewPower
		
		static Float:Origin[3]; pev(id, pev_origin, Origin); Origin[2] += 36.0
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPRITE)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(g_CFEfSprId)
		write_byte(1) 
		write_byte(200)
		message_end()
		
		// Set Freeze Aim
		set_pev(id, pev_punchangle, {0.0, 0.0, 0.0})
		
		HealthRegenTime[id] = get_gametime()
	}
}

public Show_PlayerHUD()
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!Get_BitVar(g_IsAlive, i))
			continue
			
		Show_HelperHud(i)
		Show_SDHud(i)
			
		if(g_AdrenalinePower[i] >= g_CFAvaiPer && !g_GameEnded) Show_CFHud(i)
		if(g_AdrenalinePower[i] >= 100) Show_AdrenalinePower2(i, 1.0)
	}
}

public Show_CFHud(id)
{
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id) */|| Get_BitVar(g_UsingCF, id))
		return

	set_hudmessage(200, 200, 200, HUD_ADRENALINE_X, HUD_ADRENALINE_Y - 0.02, 0, 1.25, 1.25, 0.0, 0.0)
	ShowSyncHudMsg(id, g_Hud_Adrenaline, "%L", LANG, "HUD_CFAVAILABLE")
}

public Check_AdrenalinePower(id, Power)
{
	if(Power >= 100) PlaySound(id, S_SkillAvailable)
}

public Show_AdrenalinePower2(id, Float:Time)
{
	new Power[42]
	for(new i = 0; i < (floatround(float(g_AdrenalinePower[id]) / 5.0, floatround_floor)); i++) formatex(Power, sizeof(Power), "%s|", Power)
	for(new i = 0; i < (20 - (floatround(float(g_AdrenalinePower[id]) / 5.0, floatround_floor))); i++) formatex(Power, sizeof(Power), "%s  ", Power)

	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
	{
		set_dhudmessage(255, 255, 50, HUD_ADRENALINE_X, HUD_ADRENALINE_Y, 0, Time, Time, 0.0, 0.0)
		show_dhudmessage(id, "%i [%s]", g_AdrenalinePower[id], Power)
	} else {
		set_dhudmessage(50, 255, 50, HUD_ADRENALINE_X, HUD_ADRENALINE_Y, 0, Time, Time, 0.0, 0.0)
		show_dhudmessage(id, "%i [%s]", g_AdrenalinePower[id], Power)
	}
}

public Show_HelperHud(id)
{
	new ADV[80], DisADV[80];
	new Float:LineDown
	
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
	{
		if(g_DayTime == DAY_NIGHT) 
		{	
			formatex(ADV, sizeof(ADV), "%L", LANG, "HUD_NIGHT");
		}
	} else {
		formatex(ADV, sizeof(ADV), "%L", LANG, "HUD_ATKINCREASE", g_AdrenalinePower[id])
		formatex(ADV, sizeof(ADV), "%s%%", ADV); LineDown += 0.02
		if(Get_BitVar(g_UsingCF, id)) 
		{
			formatex(ADV, sizeof(ADV), "%s^n%L", ADV, LANG, "HUD_CF")
			LineDown += 0.03
		}
		
		if(g_DayTime == DAY_NIGHT) formatex(DisADV, sizeof(DisADV), "%L", LANG, "HUD_NIGHT")
	}
	
	if(g_HealthStatus[id] == HEALTH_HEALING)
	{
		formatex(ADV, sizeof(ADV), "%s^n%L", ADV, LANG, "HUD_HEALTH_HEALING")
		LineDown += 0.03
	} else if(g_HealthStatus[id] == HEALTH_DRAINING) {
		formatex(DisADV, sizeof(DisADV), "%s^n%L", DisADV, LANG, "HUD_HEALTH_DRAINING")
		LineDown += 0.03
	}
	if(g_SpeedStatus[id] == SPEED_INC)
	{
		formatex(ADV, sizeof(ADV), "%s^n%L", ADV, LANG, "HUD_SPEED_INC")
		LineDown += 0.03
	} else if(g_SpeedStatus[id] == SPEED_DEC) {
		formatex(DisADV, sizeof(DisADV), "%s^n%L", DisADV, LANG, "HUD_SPEED_DEC")
		LineDown += 0.03
	}
	if(g_StrengthStatus[id] == STRENGTH_HARDENING)
	{
		formatex(ADV, sizeof(ADV), "%s^n%L", ADV, LANG, "HUD_STRENGTH_HARD")
		LineDown += 0.03
	} else if(g_StrengthStatus[id] == STRENGTH_WEAKENING) {
		formatex(DisADV, sizeof(DisADV), "%s^n%L", DisADV, LANG, "HUD_STRENGTH_WEAK")
		LineDown += 0.03
	}	
	
	if(ADV[0] != EOS)
	{
		set_hudmessage(0, 85, 255, HUD_HELPERA_X, HUD_HELPERA_Y, 0, 1.25, 1.25, 0.0, 0.0)
		ShowSyncHudMsg(id, g_Hud_Adv, ADV)
	}
	
	if(DisADV[0] != EOS)
	{
		set_hudmessage(150, 0, 0, HUD_HELPERA_X, HUD_HELPERA_Y + LineDown, 0, 1.25, 1.25, 0.0, 0.0)
		ShowSyncHudMsg(id, g_Hud_DisAdv, DisADV)
	}
}

public Show_SDHud(id)
{
	set_hudmessage(200, 200, 200, HUD_SD_X, HUD_SD_Y, 0, 0.0, 1.25, 0.0, 0.0)
	ShowSyncHudMsg(id, g_Hud_SD, "%L", LANG, "HUD_SCOREDAMAGE", g_RoundStat[id][STAT_SCORE], g_RoundStat[id][STAT_DMG])
}

// ====================== COMMAND ========================
// =======================================================
public CMD_JoinTeam(id)
{
	if(!Get_BitVar(g_Joined, id))
		return PLUGIN_CONTINUE
		
	return PLUGIN_HANDLED
}

public CMD_NightVision(id)
{
	if(!Get_BitVar(g_Has_NightVision, id))
		return PLUGIN_HANDLED

	if(!Get_BitVar(g_UsingNVG, id)) set_user_nightvision(id, 1, 1, 0)
	else set_user_nightvision(id, 0, 1, 0)
	
	return PLUGIN_HANDLED;
}

public CMD_Spray(id)
{
	if(!g_GameStarted || g_GameEnded || !g_InfectionStart)
		return PLUGIN_HANDLED
	if(!Get_BitVar(g_IsAlive, id))
		return PLUGIN_HANDLED
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
		return PLUGIN_HANDLED
	if(Get_BitVar(g_UsingCF, id))
		return PLUGIN_HANDLED
	if(g_AdrenalinePower[id] < g_CFAvaiPer)
	{
		client_print(id, print_center, "%L", LANG, "MESSAGE_NOTENOUGHPOWER")
		return PLUGIN_HANDLED
	}
	
	Activate_CF(id)
	return PLUGIN_HANDLED
}

public Set_Zombie_NVG(id, Give, On, OnSound, Ignored_HadNVG)
{
	if(Give) Set_BitVar(g_Has_NightVision, id)
	set_user_nightvision(id, On, OnSound, Ignored_HadNVG)
}

public set_user_nightvision(id, On, OnSound, Ignored_HadNVG)
{
	if(!Ignored_HadNVG)
	{
		if(!Get_BitVar(g_Has_NightVision, id))
			return
	}

	if(On) Set_BitVar(g_UsingNVG, id)
	else UnSet_BitVar(g_UsingNVG, id)
	
	if(OnSound) PlaySound(id, SoundNVG[On])
	set_user_nvision(id)
	
	static Type; 
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/) Type = 1
	else Type = 0
	
	ExecuteForward(g_Forward_NVG, g_fwResult, id, On, Type)
	
	return
}

public set_user_nvision(id)
{	
	static Alpha
	if(Get_BitVar(g_UsingNVG, id)) Alpha = g_NVG_Alpha
	else Alpha = 0
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
	{
		write_byte(g_NVG_ZombieColor[0]) // r
		write_byte(g_NVG_ZombieColor[1]) // g
		write_byte(g_NVG_ZombieColor[2]) // b
	} else {
		write_byte(g_NVG_HumanColor[0]) // r
		write_byte(g_NVG_HumanColor[1]) // g
		write_byte(g_NVG_HumanColor[2]) // b
	}
	write_byte(Alpha) // alpha
	message_end()

	if(Get_BitVar(g_UsingNVG, id)) SetPlayerLight(id, "#")
	else SetPlayerLight(id, GameLight[g_CurrentGameLight])
}

public Activate_CF(id)
{
	Set_BitVar(g_UsingCF, id)
	Set_BitVar(g_HudFastUpdate, id)
	
	EmitSound(id, CHAN_STATIC, g_CFSound)
}

// ====================== ZOMBIES ========================
// =======================================================
public Set_Player_Zombie(Id, Attacker, FirstZombie, Respawn, Stun)
{
	if(!Get_BitVar(g_IsAlive, Id))
		return
		
	Reset_Player(Id)
	
	// Set Zombie :)
	//UnSet_BitVar(g_IsNightStalker, Id)
	Set_BitVar(g_IsZombie, Id)
	
	ExecuteForward(g_Forward_PreInfect, g_fwResult, Id, Attacker, is_user_connected(Attacker) ? 1 : 0)
	
	if(!Respawn)
	{
		g_AdrenalinePower[Id] = 100
		
		if(is_user_bot(Id)) 
		{
			g_ZombieClass[Id] = random_num(0, g_ZombieClass_Count - 1)
			g_OldZombieClass[Id] = g_ZombieClass[Id]
			UnSet_BitVar(g_CanChooseClass, Id)
		} else {
			if(g_ZombieRandomClass) 
			{
				g_ZombieClass[Id] = random_num(0, g_ZombieClass_Count - 1)
				g_OldZombieClass[Id] = g_ZombieClass[Id]
				UnSet_BitVar(g_CanChooseClass, Id)
			} else {
				g_ZombieClass[Id] = 0
				Set_BitVar(g_CanChooseClass, Id)
				
				ZombieClassSelection_Menu(Id)
				client_printc(Id, "!g[%s]!n %L", GAMENAME, LANG_SERVER, "NOTICE_SELECTTIME", g_ZombieClassSelectTime)
			}
		}
	} else {
		g_ZombieClass[Id] = g_OldZombieClass[Id]
		UnSet_BitVar(g_CanChooseClass, Id)
		
		g_AdrenalinePower[Id] = 50
	}
	
	if(is_user_connected(Attacker))
	{
		// Reward frags, deaths
		SendDeathMsg(Attacker, Id)
		UpdateFrags(Attacker, Id, 1, 1, 1)
		g_RoundStat[Attacker][STAT_SCORE]++
	
		// Play Infection Sound
		static DeathSound[64];  ArrayGetString(S_Infection, Get_RandomArray(S_Infection), DeathSound, sizeof(DeathSound))
		EmitSound(Id, CHAN_STATIC, DeathSound)	

		cs_set_user_money(Attacker, cs_get_user_money(Attacker) + g_ZombieInfectRewardMoney)
	}	
	
	set_scoreboard_attrib(Id, 0)
	
	// Set Classic Info
	set_team(Id, TEAM_ZOMBIE)
	set_maxspeed(Id, ArrayGetCell(ZombieSpeed, g_ZombieClass[Id]))
	
	static StartHealth, StartArmor; 
	StartHealth = g_MaxHealth[Id]
	StartArmor = 0
	
	// Health Setting
	static TotalPlayer; TotalPlayer = Get_TotalInPlayer(GetPlayersFlags:GetPlayers_ExcludeDead)
	static ZombieNumber; ZombieNumber = clamp(floatround(float(TotalPlayer) / 10.0, floatround_ceil), 1, 3)
	
	if(FirstZombie)
	{
		StartHealth = clamp((TotalPlayer / ZombieNumber) * 1000, g_Zombie_FirstMinHealth, g_Zombie_FirstMaxHealth)
		StartArmor = clamp((TotalPlayer * 10), g_Zombie_MinArmor, g_Zombie_MaxArmor)
	} else {
		if(!Respawn)
		{
			if(is_user_connected(Attacker)) 
			{
				StartHealth =  clamp(g_MaxHealth[Attacker] / 2, g_ZombieMinHealth, g_ZombieMaxHealth)
				StartArmor = clamp(g_MaxArmor[Attacker] / 2, g_Zombie_MinArmor, g_Zombie_MaxArmor)
			} else {
				StartHealth = clamp(((TotalPlayer / ZombieNumber) * 1000), g_Zombie_FirstMinHealth, g_Zombie_FirstMaxHealth)
				StartArmor = clamp(TotalPlayer * 10, g_Zombie_MinArmor, g_Zombie_MaxArmor)
			}
		} else {
			StartHealth = clamp(g_MaxHealth[Id], g_ZombieMinHealth, g_ZombieMaxHealth)
			StartArmor = 0
		}	
	}
	
	g_MaxHealth[Id] = StartHealth
	SetPlayerHealth(Id, StartHealth, 1)
	cs_set_user_armor(Id, StartArmor, CS_ARMOR_KEVLAR)
	
	set_pev(Id, pev_gravity, ArrayGetCell(ZombieGravity, g_ZombieClass[Id]))
	
	// Call Sound
	if(get_gametime() - 0.5 > SoundDelay_Notice)
	{
		static Sound[64]
		if(!Respawn)
		{
			ArrayGetString(S_ZombieComing, Get_RandomArray(S_ZombieComing), Sound, sizeof(Sound))
			PlaySound(0, Sound)
		} else {
			if(!Stun)
			{
				ArrayGetString(S_ZombieComeBack, Get_RandomArray(S_ZombieComeBack), Sound, sizeof(Sound))
				PlaySound(0, Sound)
			}
		}
		
		SoundDelay_Notice = get_gametime()
	}
	
	// Set Model
	static Model[64]; ArrayGetString(ZombieModel, g_ZombieClass[Id], Model, sizeof(Model))
	set_playermodel(Id, Model, true)
	
	// Bug Fix
	cs_set_user_zoom(Id, CS_RESET_ZOOM, 1)
	fm_set_user_rendering(Id)
	
	if(!Stun)
	{
		// Strip zombies from guns and give them a knife
		fm_strip_user_weapons(Id)
		fm_give_item(Id, "weapon_knife")	
		
		// Play Draw Animation
		Set_WeaponAnim(Id, 3)
		Set_Player_NextAttack(Id, 0.75)
	}
	
	// Set NVG
	Set_Zombie_NVG(Id, 1, 1, 0, 1)
	
	// Make Some Blood
	if(!Respawn)
	{
		static Float:Origin[3]; pev(Id, pev_origin, Origin); Origin[2] += 16.0
		MakeBlood(Origin)
	}
	
	// Turn Off the FlashLight
	if (pev(Id, pev_effects) & EF_DIMLIGHT) set_pev(Id, pev_impulse, 100)
	else set_pev(Id, pev_impulse, 0)	
	
	Active_ZombieClass(Id, g_ZombieClass[Id], Stun)
	
	// Check Gameplay
	Check_Gameplay()
	
	// Exec
	ExecuteForward(g_Forward_Infected, g_fwResult, Id, Attacker, is_user_connected(Attacker) ? 1 : 0)
}

public ZombieClassSelection_Menu(id)
{
	static MenuTitle[32]; formatex(MenuTitle, sizeof(MenuTitle), "\y%L\w", LANG, "MENU_ZOMBIE_SELECTION")
	new MenuId; MenuId = menu_create(MenuTitle, "MenuHandle_ClassSeleciton")
	static ClassName[16], ClassDesc[32], MenuItem[64], ClassID[4], ClassCost, Money
	
	Money = cs_get_user_money(id)
	
	for(new i = 0; i < g_ZombieClass_Count; i++)
	{
		ArrayGetString(ZombieName, i, ClassName, sizeof(ClassName))
		ArrayGetString(ZombieDesc, i, ClassDesc, sizeof(ClassDesc))
		ClassCost = ArrayGetCell(ZombieCost, i)
		
		if(ClassCost > 0)
		{
			if(g_UnlockedClass[id][i] || (get_user_flags(id) & ADMIN_LEVEL_H)) formatex(MenuItem, sizeof(MenuItem), "%s (\y%s\w)", ClassName, ClassDesc)
			else {
				if(Money >= ClassCost) formatex(MenuItem, sizeof(MenuItem), "%s \r($%i)\w", ClassName, ClassCost)
				else formatex(MenuItem, sizeof(MenuItem), "\d%s \r($%i)\w", ClassName, ClassCost)
			}
		} else {
			formatex(MenuItem, sizeof(MenuItem), "%s (\y%s\w)", ClassName, ClassDesc)
		}

		num_to_str(i, ClassID, sizeof(ClassID))
		menu_additem(MenuId, MenuItem, ClassID)
	}
	
	if(pev_valid(id) == PDATA_SAFE) set_pdata_int(id, 205, 0, OFFSET_LINUX)
	menu_display(id, MenuId, 0)
	
	set_task(float(g_ZombieClassSelectTime), "Disable_ClassChange", id+TASK_CHANGECLASS)
}

public MenuHandle_ClassSeleciton(id, Menu, Item)
{
	if((Item == MENU_EXIT) || !Get_BitVar(g_IsAlive, id) || !Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id) */|| !Get_BitVar(g_CanChooseClass, id))
	{
		menu_destroy(Menu)
		return
	}

	static Data[6], Name[64], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)
	
	static ClassID; ClassID = str_to_num(Data)
	static ClassCost, Money, ClassName[32], ClassDesc[64], OutputInfo[128]
	
	ArrayGetString(ZombieName, ClassID, ClassName, sizeof(ClassName))
	ArrayGetString(ZombieDesc, ClassID, ClassDesc, sizeof(ClassDesc))
	
	ClassCost = ArrayGetCell(ZombieCost, ClassID)
	Money = cs_get_user_money(id)
	
	if(ClassCost > 0)
	{
		if(g_UnlockedClass[id][ClassID]) 
		{
			ExecuteForward(g_Forward_ClassUnActive, g_fwResult, id, g_ZombieClass[id])
			g_ZombieClass[id] = ClassID
			ExecuteForward(g_Forward_ClassActive, g_fwResult, id, g_ZombieClass[id])
			
			Active_ZombieClass(id, ClassID, 0)
			UnSet_BitVar(g_CanChooseClass, id)
		} else {
			if((get_user_flags(id) & ADMIN_LEVEL_H))
			{
				ExecuteForward(g_Forward_ClassUnActive, g_fwResult, id, g_ZombieClass[id])
				g_ZombieClass[id] = ClassID
				ExecuteForward(g_Forward_ClassActive, g_fwResult, id, g_ZombieClass[id])
				
				Active_ZombieClass(id, ClassID, 0)
				UnSet_BitVar(g_CanChooseClass, id)
			} else {
				if(Money >= ClassCost) // Unlock now
				{
					g_UnlockedClass[id][ClassID] = 1
					
					ExecuteForward(g_Forward_ClassUnActive, g_fwResult, id, g_ZombieClass[id])
					g_ZombieClass[id] = ClassID
					ExecuteForward(g_Forward_ClassActive, g_fwResult, id, g_ZombieClass[id])
					
					Active_ZombieClass(id, ClassID, 0)
					UnSet_BitVar(g_CanChooseClass, id)
					
					formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GAMENAME, LANG_SERVER, "MENU_ZOMBIE_UNLOCKED", ClassName, ClassCost)
					client_printc(id, OutputInfo)
					formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %s: %s", GAMENAME, ClassName, ClassDesc)
					
					cs_set_user_money(id, Money - (ClassCost / 2))
				} else { // Not Enough $
					formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GAMENAME, LANG_SERVER, "MENU_ZOMBIE_UNLOCK_MONEY", ClassCost, ClassName)
					client_printc(id, OutputInfo)
					
					ZombieClassSelection_Menu(id)
				}
			}
		}
	} else {
		ExecuteForward(g_Forward_ClassUnActive, g_fwResult, id, g_ZombieClass[id])
		g_ZombieClass[id] = ClassID
		ExecuteForward(g_Forward_ClassActive, g_fwResult, id, g_ZombieClass[id])
		
		Active_ZombieClass(id, ClassID, 0)
		UnSet_BitVar(g_CanChooseClass, id)
	}
}

public Disable_ClassChange(id)
{
	id -= TASK_CHANGECLASS
	
	if(!Get_BitVar(g_IsAlive, id))
		return
	if(!Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
		return
	if(!Get_BitVar(g_CanChooseClass, id))
		return

	UnSet_BitVar(g_CanChooseClass, id)
	menu_cancel(id)
}

public Reset_Player(id)
{
	UnSet_BitVar(g_IsZombie, id)
	UnSet_BitVar(g_PermanentDeath, id)
	UnSet_BitVar(g_CanChooseClass, id)
	UnSet_BitVar(g_Has_NightVision, id)
	UnSet_BitVar(g_UsingNVG, id)	
	UnSet_BitVar(g_ClawA, id)
	UnSet_BitVar(g_UsingCF, id)
	UnSet_BitVar(g_Respawning, id)
	UnSet_BitVar(g_RespawnFromDeath, id)
	UnSet_BitVar(g_Stunning, id)
	UnSet_BitVar(g_TempingAttack, id)
	UnSet_BitVar(g_HudFastUpdate, id)
	UnSet_BitVar(g_Slowdown, id)
	//UnSet_BitVar(g_IsNightStalker, id)
	
	g_AdrenalinePower[id] = 0
	g_HealthStatus[id] = 0
	g_SpeedStatus[id] = 0
	g_StrengthStatus[id] = 0
	if(pev_valid(g_MyEntity[id])) remove_entity(g_MyEntity[id])
	else g_MyEntity[id] = 0
	
	remove_task(id+TASK_REVIVE)
	remove_task(id+TASK_CHANGECLASS)
	remove_task(id+TASK_REVIVE_EFFECT)
	remove_task(id+TASK_SLOWDOWN)
	
	client_cmd(id, "-duck")
}

public Active_ZombieClass(Id, ClassID, Stun)
{
	g_ZombieClass[Id] = ClassID
	g_OldZombieClass[Id] = ClassID
	
	set_maxspeed(Id, ArrayGetCell(ZombieSpeed, g_ZombieClass[Id]))
	set_pev(Id, pev_gravity, ArrayGetCell(ZombieGravity, g_ZombieClass[Id]))
	
	// Set Model
	static Model[64]; ArrayGetString(ZombieModel, g_ZombieClass[Id], Model, sizeof(Model))
	set_playermodel(Id, Model, true)
	
	static Ent; Ent = fm_get_user_weapon_entity(Id, get_user_weapon(Id))
	if(pev_valid(Ent)) fw_Item_Deploy_Post(Ent)
	
	if(!Stun)
	{
		// Play Draw Animation
		Set_WeaponAnim(Id, 3)
		Set_Player_NextAttack(Id, 0.75)
	}
	
	ExecuteForward(g_Forward_ClassActive, g_fwResult, Id, g_ZombieClass[Id])
}

public SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, g_MsgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("knife") // killer's weapon
	message_end()
}

public UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	if(is_user_connected(attacker) && is_user_connected(victim) && cs_get_user_team(attacker) != cs_get_user_team(victim))
	{
		if((pev(attacker, pev_frags) + frags) < 0)
			return
	}
	
	if(is_user_connected(attacker))
	{
		// Set attacker frags
		set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) + frags))
		
		// Update scoreboard with attacker and victim info
		if(scoreboard)
		{
			message_begin(MSG_BROADCAST, g_MsgScoreInfo)
			write_byte(attacker) // id
			write_short(pev(attacker, pev_frags)) // frags
			write_short(cs_get_user_deaths(attacker)) // deaths
			write_short(0) // class?
			write_short(fm_cs_get_user_team(attacker)) // team
			message_end()
		}
	}
	
	if(is_user_connected(victim))
	{
		// Set victim deaths
		fm_cs_set_user_deaths(victim, cs_get_user_deaths(victim) + deaths)
		
		// Update scoreboard with attacker and victim info
		if(scoreboard)
		{
			message_begin(MSG_BROADCAST, g_MsgScoreInfo)
			write_byte(victim) // id
			write_short(pev(victim, pev_frags)) // frags
			write_short(cs_get_user_deaths(victim)) // deaths
			write_short(0) // class?
			write_short(fm_cs_get_user_team(victim)) // team
			message_end()
		}
	}
}

// ====================== MESSAGE ========================
// =======================================================
public Message_DeathMsg(msd_id, msg_dest, msg_entity)
{
	static Attacker; Attacker = get_msg_arg_int(1)
	if(!Get_BitVar(g_IsAlive, Attacker))
		return
	if(Get_BitVar(g_UsingCF, Attacker)) set_msg_arg_int(3, get_msg_argtype(3), 1)
}

public Message_StatusIcon(msg_id, msg_dest, msg_entity)
{
	static szMsg[8];
	get_msg_arg_string(2, szMsg ,7)
	
	if(equal(szMsg, "buyzone") && get_msg_arg_int(1))
	{
		if(pev_valid(msg_entity) != PDATA_SAFE)
			return  PLUGIN_CONTINUE;
	
		set_pdata_int(msg_entity, 235, get_pdata_int(msg_entity, 235) & ~(1<<0))
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public Message_TeamScore()
{
	static Team[2]
	get_msg_arg_string(1, Team, charsmax(Team))
	
	switch(Team[0])
	{
		case 'C': set_msg_arg_int(2, get_msg_argtype(2), g_TeamScore[TEAM_HUMAN])
		case 'T': set_msg_arg_int(2, get_msg_argtype(2), g_TeamScore[TEAM_ZOMBIE])
	}
}

public Message_Health(msg_id, msg_dest, id)
{
	// Get player's health
	static health
	health = get_user_health(id)
	
	// Don't bother
	if(health < 1) 
		return
	
	static Float:NewHealth, RealHealth, Health
	
	NewHealth = (float(health) / float(g_MaxHealth[id])) * 100.0; 
	RealHealth = floatround(NewHealth)
	Health = clamp(RealHealth, 1, 255)
	
	set_msg_arg_int(1, get_msg_argtype(1), Health)
}

public Message_ClCorpse()
{
	static id
	id = get_msg_arg_int(12)
	
	if((Get_BitVar(g_IsZombie, id) /*|| Get_BitVar(g_IsNightStalker, id)*/) && !Get_BitVar(g_PermanentDeath, id))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

// ===================== FAKEMETA ========================
// =======================================================
public fw_GetGameDesc()
{
	forward_return(FMV_STRING, GAMENAME)
	return FMRES_SUPERCEDE
}

// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;
	if(Get_BitVar(g_IsZombie, id))
	{
		if(Get_BitVar(g_TempingAttack, id))
		{
			if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
			{
				if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
					return FMRES_SUPERCEDE
				if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
				{
					if (sample[17] == 'w')  return FMRES_SUPERCEDE
					else  return FMRES_SUPERCEDE
				}
				if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
					return FMRES_SUPERCEDE;
			}
		}
		
		static sound[64]
		// Zombie being hit
		if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
		{
			ArrayGetString(random_num(0, 1) ? ZombiePainSound1 : ZombiePainSound2, g_ZombieClass[id], sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
	
			return FMRES_SUPERCEDE;
		}
		
		// Zombie attacks with knife
		if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
			{
				ArrayGetString(S_ClawSwing, Get_RandomArray(S_ClawSwing), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				
				if(!Get_BitVar(g_ClawA, id))
				{
					Set_WeaponAnim(id, 1)
					Set_BitVar(g_ClawA, id)
				} else {
					Set_WeaponAnim(id, 2)
					UnSet_BitVar(g_ClawA, id)
				}
				
				return FMRES_SUPERCEDE;
			}
			if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if (sample[17] == 'w') // wall
				{
					ArrayGetString(S_ClawWall, Get_RandomArray(S_ClawWall), sound, charsmax(sound))
					emit_sound(id, channel, sound, volume, attn, flags, pitch)
					
					if(!Get_BitVar(g_ClawA, id))
					{
						Set_WeaponAnim(id, 1)
						Set_BitVar(g_ClawA, id)
					} else {
						Set_WeaponAnim(id, 2)
						UnSet_BitVar(g_ClawA, id)
					}
					
					return FMRES_SUPERCEDE;
				} else {
					ArrayGetString(S_ClawHit, Get_RandomArray(S_ClawHit), sound, charsmax(sound))
					emit_sound(id, channel, sound, volume, attn, flags, pitch)
					
					if(!Get_BitVar(g_ClawA, id))
					{
						Set_WeaponAnim(id, 1)
						Set_BitVar(g_ClawA, id)
					} else {
						Set_WeaponAnim(id, 2)
						UnSet_BitVar(g_ClawA, id)
					}
					
					return FMRES_SUPERCEDE;
				}
			}
			if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
			{
				ArrayGetString(S_ClawHit, Get_RandomArray(S_ClawHit), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
		
				
		// Zombie dies
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			ArrayGetString(ZombieDeathSound, g_ZombieClass[id], sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}/* else if(Get_BitVar(g_IsNightStalker, id)) {
		if(Get_BitVar(g_TempingAttack, id))
		{
			if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
			{
				if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
					return FMRES_SUPERCEDE
				if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
				{
					if (sample[17] == 'w')  return FMRES_SUPERCEDE
					else  return FMRES_SUPERCEDE
				}
				if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
					return FMRES_SUPERCEDE;
			}
		}
		
		static sound[64]
		// Zombie being hit
		if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
		{
			sound = random_num(0, 1) == 1 ? g_HiddenPainSound1 : g_HiddenPainSound2
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
	
			return FMRES_SUPERCEDE;
		}
		
		// Zombie attacks with knife
		if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
			{
				ArrayGetString(S_ClawSwing, Get_RandomArray(S_ClawSwing), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				
				if(!Get_BitVar(g_ClawA, id))
				{
					Set_WeaponAnim(id, 1)
					Set_BitVar(g_ClawA, id)
				} else {
					Set_WeaponAnim(id, 2)
					UnSet_BitVar(g_ClawA, id)
				}
				
				return FMRES_SUPERCEDE;
			}
			if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if (sample[17] == 'w') // wall
				{
					ArrayGetString(S_ClawWall, Get_RandomArray(S_ClawWall), sound, charsmax(sound))
					emit_sound(id, channel, sound, volume, attn, flags, pitch)
					
					if(!Get_BitVar(g_ClawA, id))
					{
						Set_WeaponAnim(id, 1)
						Set_BitVar(g_ClawA, id)
					} else {
						Set_WeaponAnim(id, 2)
						UnSet_BitVar(g_ClawA, id)
					}
					
					return FMRES_SUPERCEDE;
				} else {
					ArrayGetString(S_ClawHit, Get_RandomArray(S_ClawHit), sound, charsmax(sound))
					emit_sound(id, channel, sound, volume, attn, flags, pitch)
					
					if(!Get_BitVar(g_ClawA, id))
					{
						Set_WeaponAnim(id, 1)
						Set_BitVar(g_ClawA, id)
					} else {
						Set_WeaponAnim(id, 2)
						UnSet_BitVar(g_ClawA, id)
					}
					
					return FMRES_SUPERCEDE;
				}
			}
			if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
			{
				ArrayGetString(S_ClawHit, Get_RandomArray(S_ClawHit), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
				
		// Zombie dies
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			sound = g_HiddenDeathSound
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}*/

	return FMRES_IGNORED;
}


public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if(!Get_BitVar(g_IsAlive, id))
		return FMRES_IGNORED	
	if(!Get_BitVar(g_TempingAttack, id))
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if(!Get_BitVar(g_IsAlive, id))
		return FMRES_IGNORED	
	if(!Get_BitVar(g_TempingAttack, id))
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_SetModel(Ent, const Model[])
{
	if(!pev_valid(Ent))
		return FMRES_IGNORED
	
	new Float:DmgTime
	pev(Ent, pev_dmgtime, DmgTime)
	
	if(DmgTime == 0.0) 
		return FMRES_IGNORED
	
	if(Model[7] == 'w' && Model[8] == '_')
	{
		switch(Model[9])
		{
			case 'h': set_pev(Ent, pev_team, GRENADE_HE)
			case 'f': set_pev(Ent, pev_team, GRENADE_FB)
			case 's': set_pev(Ent, pev_team, GRENADE_SG)
		}
	}

	return FMRES_IGNORED
}

public fw_Entity_Think(Ent)
{
	if(!pev_valid(Ent))
		return
		
	if(get_gametime() >= pev(Ent, pev_fuser1)) 
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return
	}
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
}
// ======================== HAM ==========================
// =======================================================
public fw_PlayerSpawn_Post(id)
{
	if(!Get_BitVar(g_Connected, id)) return
	
	Set_BitVar(g_Joined, id)
	Set_BitVar(g_IsAlive, id)

	if(Get_BitVar(g_IsZombie, id) && Get_BitVar(g_RespawnFromDeath, id))
	{
		if(!g_InfectionStart)
			return
			
		// Respawn
		Do_Random_Spawn(id)
		Set_Player_Zombie(id, -1, 0, 1, 0)
		
		// Exec
		ExecuteForward(g_Forward_Spawned, g_fwResult, id, 1)

		return
	}/* else if(Get_BitVar(g_IsNightStalker, id) && Get_BitVar(g_RespawnFromDeath, id)) {
		if(!g_InfectionStart)
			return
			
		// Respawn
		Do_Random_Spawn(id)
		Set_Player_NightStalker(id, 1, 0)
		
		// Exec
		ExecuteForward(g_Forward_Spawned, g_fwResult, id, 1)

		return
	}*/
	
	Reset_Player(id)
	
	g_RoundStat[id][STAT_SCORE] = 0
	g_RoundStat[id][STAT_DMG] = 0
	
	// Set Human
	Do_Random_Spawn(id)
	
	Set_Zombie_NVG(id, 0, 0, 0, 1)
	set_task(0.01, "Set_LightStart", id)
	fm_set_user_rendering(id)
	
	set_team(id, TEAM_HUMAN)
	SetPlayerHealth(id, g_HumanHealth, 1)
	set_pev(id, pev_gravity, g_HumanGravity)
	cs_set_user_armor(id, g_HumanArmor, CS_ARMOR_KEVLAR)
	rg_reset_maxspeed(id)
	
	// Start Weapon
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	fm_give_item(id, "weapon_usp")
	give_ammo(id, 1, CSW_USP)
	give_ammo(id, 1, CSW_USP)

	static PlayerModel[32]
	ArrayGetString(HumanModel, g_HumanModel[id], PlayerModel, sizeof(PlayerModel))
	set_playermodel(id, PlayerModel, false)
	
	// Fade Out
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, {0,0,0}, id)
	write_short(FixedUnsigned16(2.5, 1<<12))
	write_short(FixedUnsigned16(2.5, 1<<12))
	write_short((0x0000))
	write_byte(0)
	write_byte(0)
	write_byte(0)
	write_byte(255)
	message_end()
	
	// Fix Bug
	client_cmd(id, "-duck")
	
	// Show Info
	static String[64]; formatex(String, sizeof(String), "!g[%s (%s)]!n is made by !t%s!n", GAMENAME, VERSION, AUTHOR)
	client_printc(id, String)
	
	// Exec
	ExecuteForward(g_Forward_Spawned, g_fwResult, id, 0)
}

public fw_PlayerKilled_Post(Victim, Attacker)
{
	UnSet_BitVar(g_IsAlive, Victim)
	
	if(g_DayTime == DAY_LIGHT || g_DayTime == DAY_AFTER) // Daylight
	{
		if(!Get_BitVar(g_UsingCF, Attacker)) 
		{
			UnSet_BitVar(g_PermanentDeath, Victim)
			Set_BitVar(g_Respawning, Victim)
			
			UpdateFrags(Attacker, Victim, -1, -1, 1)
		} else {
			Set_BitVar(g_PermanentDeath, Victim)
			UnSet_BitVar(g_Respawning, Victim)
			
			UpdateFrags(Attacker, Victim, 3, 3, 1)
			g_RoundStat[Attacker][STAT_SCORE] += 3
		}
	} else { // Night
		UnSet_BitVar(g_PermanentDeath, Victim)
		Set_BitVar(g_Respawning, Victim)
			
		UpdateFrags(Attacker, Victim, -1, -1, 1)
	}

	set_task(0.5, "Check_ZombieDeath", Victim+TASK_REVIVE)
	
	// Exec
	ExecuteForward(g_Forward_Died, g_fwResult, Victim, Attacker, Get_BitVar(g_PermanentDeath, Victim))
	
	// Check Gameplay
	Check_Gameplay()
}

public Set_LightStart(id) SetPlayerLight(id, GameLight[g_CurrentGameLight])
public fw_PlayerTakeDamage(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	if(!g_GameStarted || g_GameEnded || !g_InfectionStart)
		return HAM_SUPERCEDE
	if(Victim == Attacker || !Get_BitVar(g_Connected, Attacker))
		return HAM_SUPERCEDE
	if(Get_BitVar(g_Stunning, Victim))
		return HAM_SUPERCEDE
		
	static Float:CurrentDamage; CurrentDamage = Damage
	static Float:ZombieDefenses; 
	if(Get_BitVar(g_IsZombie, Victim)) ZombieDefenses = ArrayGetCell(ZombieDefense, g_ZombieClass[Victim])
	//else if(Get_BitVar(g_IsNightStalker, Victim)) ZombieDefenses = g_HiddenDefense
	
	if((Get_BitVar(g_IsZombie, Victim) /*|| Get_BitVar(g_IsNightStalker, Victim)*/) && !Get_BitVar(g_IsZombie, Attacker)) // Human -> Zombie
	{
		if(DamageBits & (1<<24)) CurrentDamage *= g_HE_DmgMulti
		CurrentDamage /= ZombieDefenses

		cs_set_user_money(Attacker, cs_get_user_money(Attacker) + floatround(CurrentDamage / 2))
		
		if(((float(g_AdrenalinePower[Attacker]) / 100.0) + 1.0) > 1.0)
			CurrentDamage *= ((float(g_AdrenalinePower[Attacker]) / 100.0) + 1.0)
		
		static Body, Target; get_user_aiming(Attacker, Target, Body, 99999)
		if(!Get_BitVar(g_UsingCF, Attacker))
		{
			if(Target == Victim && Body == HIT_HEAD) 
				CurrentDamage * 4.0
		} else CurrentDamage *= g_CFDmgMulti

		g_RoundStat[Attacker][STAT_DMG] += floatround(Damage)
		ExecuteForward(g_Forward_RoundDamage, g_fwResult, Attacker, g_RoundStat[Attacker][STAT_DMG])
		
		// Stun Check
		if(g_DayTime == DAY_NIGHT)
		{
			if(pev(Victim, pev_flags) & FL_DUCKING)
			{
				SetHamParamFloat(4, CurrentDamage)
				return HAM_IGNORED
			} else {
				if(pev(Victim, pev_health) - CurrentDamage > 0)
				{
					SetHamParamFloat(4, CurrentDamage)
					return HAM_IGNORED
				} else {
					Activate_Stun(Victim)
					SetHamParamFloat(4, 0.0)
					
					return HAM_IGNORED
				}
			}
		}
		
		SetHamParamFloat(4, CurrentDamage)
	} else if((!Get_BitVar(g_IsZombie, Victim)/* && !Get_BitVar(g_IsNightStalker, Victim)*/) && (Get_BitVar(g_IsZombie, Attacker)/* || Get_BitVar(g_IsNightStalker, Attacker)*/)) { // Zombie -> Human
		if(DamageBits & (1<<24)) return HAM_SUPERCEDE
		if(Damage <= 0.0) return HAM_IGNORED
			
		// Set Zombie
		Set_Player_Zombie(Victim, Attacker, 0, 0, 0)
		
		return HAM_SUPERCEDE
	}	
		
	return HAM_IGNORED
}

public fw_PlayerTraceAttack(Victim, Attacker, Float:Damage, Float:direction[3], tracehandle, damage_type)
{
	if(Victim == Attacker || !Get_BitVar(g_Connected, Attacker))
		return HAM_IGNORED
		
	static HitGroup; HitGroup = get_tr2(tracehandle, TR_iHitgroup)
	if(HitGroup == HIT_HEAD) set_tr2(tracehandle, TR_iHitgroup, HIT_CHEST)
	
	return HAM_IGNORED
}

public fw_PlayerTraceAttack_Post(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker || !Get_BitVar(g_IsAlive, attacker))
		return;
	if (Get_BitVar(g_IsZombie, attacker)/* || Get_BitVar(g_IsNightStalker, attacker)*/)
		return;
	if (!(damage_type & DMG_BULLET))
		return;
	if (damage <= 0.0 || GetHamReturnStatus() == HAM_SUPERCEDE || get_tr2(tracehandle, TR_pHit) != victim)
		return;
	
	if(Get_BitVar(g_IsZombie, victim) /*|| Get_BitVar(g_IsNightStalker, victim)*/)
	{
		new ducking = pev(victim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
		if (ducking && g_KB_Ducking == 0.0)
			return;
	
		static origin1[3], origin2[3]
		get_user_origin(victim, origin1)
		get_user_origin(attacker, origin2)
	
		if(get_distance(origin1, origin2) > g_KB_Distance)
			return ;
		
		static Float:velocity[3]
		pev(victim, pev_velocity, velocity)
		
		if(g_KB_Damage) xs_vec_mul_scalar(direction, damage, direction)
		
		new attacker_weapon = get_user_weapon(attacker)
		
		if(g_KB_WeaponPower && kb_weapon_power[attacker_weapon] > 0.0)
			xs_vec_mul_scalar(direction, kb_weapon_power[attacker_weapon], direction)
		
		if(ducking) xs_vec_mul_scalar(direction, g_KB_Ducking, direction)
		if(g_KB_ZombieClass) 
		{
			if(Get_BitVar(g_IsZombie, victim)) xs_vec_mul_scalar(direction, ArrayGetCell(ZombieKnockback, g_ZombieClass[victim]), direction)
			//else if(Get_BitVar(g_IsNightStalker, victim)) xs_vec_mul_scalar(direction, g_HiddenKnockback, direction)
		}
		
		xs_vec_add(velocity, direction, direction)
		if (!g_KB_ZVEL) direction[2] = velocity[2]
	
		set_pev(victim, pev_velocity, direction)
	}
}

public fw_UseStationary(entity, caller, activator, use_type)
{
	if (use_type == 2 && Get_BitVar(g_Connected, caller) && (Get_BitVar(g_IsZombie, caller) /*|| Get_BitVar(g_IsNightStalker, caller)*/))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if(use_type == 0 && Get_BitVar(g_Connected, caller) && (Get_BitVar(g_IsZombie, caller) /*|| Get_BitVar(g_IsNightStalker, caller)*/))
	{
		// Reset Claws
		static Claw[64], Claw2[64];
		
		if(Get_BitVar(g_IsZombie, caller)) ArrayGetString(ZombieClawModel, g_ZombieClass[caller], Claw, sizeof(Claw))
		//else if(Get_BitVar(g_IsNightStalker, caller)) Claw = g_HiddenClawModel
		
		formatex(Claw2, sizeof(Claw2), "models/%s/%s", GAME_FOLDER, Claw)
		
		set_pev(caller, pev_viewmodel2, Claw2)
		set_pev(caller, pev_weaponmodel2, "")	
	}
}

public fw_TouchWeapon(weapon, id)
{
	if(!Get_BitVar(g_Connected, id))
		return HAM_IGNORED
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_GrenadeThink(Ent)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	new Float:DmgTime; pev(Ent, pev_dmgtime, DmgTime)
	if(DmgTime > get_gametime()) return HAM_IGNORED
	
	new StepSound = pev(Ent, pev_team)
	switch(StepSound)
	{
		case GRENADE_HE: {/* No Need This */}
		case GRENADE_FB: { FB_CheckKnockback(Ent); return HAM_SUPERCEDE; }
		case GRENADE_SG: { SG_CheckRadiusDamage(Ent); }
	}
	
	return HAM_IGNORED
}

public fw_GrenadeTouch(Ent, World)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	new StepSound = pev(Ent, pev_team)
	switch(StepSound)
	{
		case GRENADE_HE: { /* No Need This */ }
		case GRENADE_FB: { if(g_FB_OnImpact) set_pev(Ent, pev_dmgtime, 0.0); }
		case GRENADE_SG: { /* No Need This */ }
	}
	
	return HAM_IGNORED
}

public fw_Item_Deploy_Post(weapon_ent)
{
	new owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	if (!Get_BitVar(g_IsAlive, owner))
		return;
	
	new CSWID; CSWID = cs_get_weapon_id(weapon_ent)
	if(Get_BitVar(g_IsZombie, owner)/* || Get_BitVar(g_IsNightStalker, owner)*/)
	{
		if(CSWID == CSW_KNIFE)
		{
			static ClawModelA[64], ClawModelB[64]; 
			
			if(Get_BitVar(g_IsZombie, owner)) ArrayGetString(ZombieClawModel, g_ZombieClass[owner], ClawModelA, sizeof(ClawModelA))
			//else if(Get_BitVar(g_IsNightStalker, owner)) ClawModelA = g_HiddenClawModel
			
			formatex(ClawModelB, sizeof(ClawModelB), "models/%s/%s", GAME_FOLDER, ClawModelA)
			
			set_pev(owner, pev_viewmodel2, ClawModelB)
			set_pev(owner, pev_weaponmodel2, "")
		} else {
			strip_user_weapons(owner)
			give_item(owner, "weapon_knife")
			
			engclient_cmd(owner, "weapon_knife")
		}
	}
}

public Do_Random_Spawn(id)
{
	if (!g_PlayerSpawn_Count)
		return;	
	
	static hull, sp_index, i
	
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	sp_index = random_num(0, g_PlayerSpawn_Count - 1)
	
	for (i = sp_index + 1; /*no condition*/; i++)
	{
		if(i >= g_PlayerSpawn_Count) i = 0
		
		if(is_hull_vacant(g_PlayerSpawn_Point[i], hull))
		{
			engfunc(EngFunc_SetOrigin, id, g_PlayerSpawn_Point[i])
			break
		}

		if (i == sp_index) break
	}
}

public SetPlayerHealth(id, Health, FullHealth)
{
	fm_set_user_health(id, Health)
	if(FullHealth) 
	{
		g_MaxHealth[id] = Health
		set_pev(id, pev_max_health, float(Health))
	}
}

public End_Round(Float:EndTime, RoundDraw, CsTeams:Team)
// RoundDraw: Draw or Team Win
// Team: 1 - T | 2 - CT
{
	if(g_GameEnded) return
	if(RoundDraw) 
	{
		// GM_TerminateRound(EndTime, WINSTATUS_DRAW)
		rg_round_end(EndTime, WINSTATUS_DRAW, /*ScenarioEventEndRound:event*/ ROUND_NONE)
		ExecuteForward(g_Forward_RoundEnd, g_fwResult, CS_TEAM_UNASSIGNED)
		
		client_print(0, print_center, "%L", LANG, "MESSAGE_GAME_START")
	} else {
		new Sound[64];
		if(Team == CS_TEAM_T) 
		{
			g_Round++
			g_TeamScore[TEAM_ZOMBIE]++
			
			// GM_TerminateRound(6.0, WINSTATUS_TERRORIST)
			rg_round_end(6.0, WINSTATUS_TERRORISTS, /*ScenarioEventEndRound:event*/ ROUND_NONE)
			ExecuteForward(g_Forward_RoundEnd, g_fwResult, CS_TEAM_T)
			
			ArrayGetString(S_WinZombie, Get_RandomArray(S_WinZombie), Sound, sizeof(Sound))
			PlaySound(0, Sound)
			
			set_dhudmessage(200, 0, 0, HUD_WIN_X, HUD_WIN_Y, 0, 6.0, 6.0, 0.0, 1.5)
			show_dhudmessage(0, "%L", LANG, "WIN_ZOMBIE")
		} else if(Team == CS_TEAM_CT) {
			g_Round++
			g_TeamScore[TEAM_HUMAN]++
			
			// GM_TerminateRound(6.0, WINSTATUS_CT)
			rg_round_end(6.0, WINSTATUS_CTS, /*ScenarioEventEndRound:event*/ ROUND_NONE)
			ExecuteForward(g_Forward_RoundEnd, g_fwResult, CS_TEAM_CT)
			
			ArrayGetString(S_WinHuman, Get_RandomArray(S_WinHuman), Sound, sizeof(Sound))
			PlaySound(0, Sound)
			
			set_dhudmessage(0, 200, 0, HUD_WIN_X, HUD_WIN_Y, 0, 6.0, 6.0, 0.0, 1.5)
			show_dhudmessage(0, "%L", LANG, "WIN_HUMAN")
		}
	}
	
	remove_task(1840)
	remove_task(TASK_GAMENOTICE)
	remove_task(TASK_NIGHTMARE)
	
	for(new i = 0; i < g_MaxPlayers; i++) UnSet_BitVar(g_RespawnFromDeath, i)
	
	Reward_Team()
	
	g_GameEnded = 1
}

public Reward_Team()
{
	// Update Score
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!Get_BitVar(g_Connected, i))
			continue
		if(!Get_BitVar(g_IsAlive, i))
			continue
			
		if(Get_BitVar(g_IsZombie, i)/* || Get_BitVar(g_IsNightStalker, i)*/) UpdateFrags(i, 0, 1, 0, 1)
		else UpdateFrags(i, 0, 2, 0, 1)
	}
}

public give_ammo(id, silent, CSWID)
{
	static Amount, Name[32]
		
	switch(CSWID)
	{
		case CSW_P228: {Amount = 13; formatex(Name, sizeof(Name), "357sig");}
		case CSW_SCOUT: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_XM1014: {Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
		case CSW_MAC10: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_AUG: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_ELITE: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_FIVESEVEN: {Amount = 50; formatex(Name, sizeof(Name), "57mm");}
		case CSW_UMP45: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_SG550: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_GALIL: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_FAMAS: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_USP: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_GLOCK18: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_AWP: {Amount = 10; formatex(Name, sizeof(Name), "338magnum");}
		case CSW_MP5NAVY: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_M249: {Amount = 30; formatex(Name, sizeof(Name), "556natobox");}
		case CSW_M3: {Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
		case CSW_M4A1: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_TMP: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_G3SG1: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_DEAGLE: {Amount = 7; formatex(Name, sizeof(Name), "50ae");}
		case CSW_SG552: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_AK47: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_P90: {Amount = 50; formatex(Name, sizeof(Name), "57mm");}
	}
	
	if(!silent) emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	ExecuteHamB(Ham_GiveAmmo, id, Amount, Name, 254)
}

public Activate_Stun(id)
{
	Set_BitVar(g_Stunning, id)
	
	SetPlayerHealth(id, 1, 0)
	set_maxspeed(id, 0.1)
	Set_PlayerStopTime(id, g_StunTime)
	set_pev(id, pev_gravity, 999.0)
	
	Set_WeaponAnim(id, g_StunClawAnim)
	set_pev(id, pev_sequence, g_StunPlayerAnim)
	
	static Sound[64]; 
	if(Get_BitVar(g_IsZombie, id)) ArrayGetString(ZombieStunSound, g_ZombieClass[id], Sound, sizeof(Sound))
	//else if(Get_BitVar(g_IsNightStalker, id)) Sound = g_HiddenStunSound
	EmitSound(id, CHAN_BODY, Sound)
	
	// Set Light
	UnSet_BitVar(g_Has_NightVision, id)
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	write_byte(255) // r
	write_byte(0) // g
	write_byte(0) // b
	write_byte(100) // alpha
	message_end()
	
	SetPlayerLight(id, GameLight[g_CurrentGameLight])
	
	// Head Effect
	g_MyEntity[id] = CreateEntity(id, g_StunEfSpr, 0.5, 5.0, 16.0, 5.0)
	
	// Reset Time
	Set_BitVar(g_Respawning, id)
	g_RespawnTime[id] = floatround(g_StunTime)
	
	ExecuteForward(g_Forward_Stun, g_fwResult, id)
	Countdown_Stun(id+TASK_STUN)
}

public Countdown_Stun(id)
{
	id -= TASK_STUN
	
	if(!g_GameStarted || g_GameEnded || !g_InfectionStart)
		return
	if(!Get_BitVar(g_Connected, id) || !Get_BitVar(g_IsAlive, id))
		return
	if(!Get_BitVar(g_Respawning, id))
		return
	if(g_RespawnTime[id] == 2) Reset_StunClaw(id+TASK_STUN)
	if(g_RespawnTime[id] <= 0)
	{
		// Reset Stun
		Reset_Stun(id+TASK_STUN)
		
		return
	}
	
	client_print(id, print_center, "%L", LANG, "MESSAGE_REVIVING", g_RespawnTime[id])
	
	g_RespawnTime[id]--
	set_task(1.0, "Countdown_Stun", id+TASK_STUN)
}

public Reset_StunClaw(id)
{
	id -= TASK_STUN
	if(!Get_BitVar(g_IsAlive, id))
		return
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
	{
		Set_WeaponAnim(id, g_StunClawAfterAnim)
		
		message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
		write_short(FixedUnsigned16(1.0, 1<<12)) // duration
		write_short(FixedUnsigned16(1.0, 1<<12)) // hold time
		write_short(0x0000) // fade type
		write_byte(255) // r
		write_byte(0) // g
		write_byte(0) // b
		write_byte(100) // alpha
		message_end()
	}
}

public Reset_Stun(id)
{
	id -= TASK_STUN
	if(!Get_BitVar(g_IsAlive, id))
		return
	if(Get_BitVar(g_IsZombie, id)/* || Get_BitVar(g_IsNightStalker, id)*/)
	{	
		UnSet_BitVar(g_Stunning, id)
		UnSet_BitVar(g_Respawning, id)
		
		if(Get_BitVar(g_IsZombie, id)) Set_Player_Zombie(id, -1, 0, 1, 1)
		//else if(Get_BitVar(g_IsNightStalker, id)) Set_Player_NightStalker(id, 1, 1)
		
		// Head Effect
		if(pev_valid(g_MyEntity[id])) remove_entity(g_MyEntity[id])
		else g_MyEntity[id] = 0
		
		client_cmd(id, "-duck")
	}
}

public CreateEntity(id, const Sprite[], Float:Scale, Float:Frame, Float:FrameRate, Float:Time)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent))
		return
		
	g_MyEntity[id] = Ent
	
	// Set Origin
	static Float:Origin[3]; pev(id, pev_origin, Origin)
	
	engfunc(EngFunc_SetOrigin, Ent, Origin)
		
	// Set Properties
	set_pev(Ent, pev_takedamage, DAMAGE_NO)
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW)
	
	// Set Sprite
	set_pev(Ent, pev_classname, HEADSPR_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, Sprite)
	
	// Set Rendering
	set_pev(Ent, pev_renderfx, kRenderFxNone)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 200.0)
	
	// Set other
	set_pev(Ent, pev_iuser1, id)
	set_pev(Ent, pev_scale, Scale)
	set_pev(Ent, pev_fuser1, get_gametime() + Time)
	set_pev(Ent, pev_fuser2, Frame)
	
	set_pev(Ent, pev_aiment, id)
	
	// Allow animation of sprite ?
	if(Frame && FrameRate > 0.0)
	{
		set_pev(Ent, pev_animtime, get_gametime())
		set_pev(Ent, pev_framerate, FrameRate)
		
		set_pev(Ent, pev_spawnflags, SF_SPRITE_STARTON)
		dllfunc(DLLFunc_Spawn, Ent)
	}	
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
}

public FB_CheckKnockback(Ent)
{
	if(!pev_valid(Ent))
		return
		
	EmitSound(Ent, CHAN_BODY, g_FB_ExpSound)
	static Float:Origin[3]; pev(Ent, pev_origin, Origin)
		
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Origin)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + floatround(g_FB_KnockRange))
	write_short(g_ShockWave_SprID)
	write_byte(0) // Start Frame
	write_byte(20) // Framerate
	write_byte(4) // Live Time
	write_byte(25) // Width
	write_byte(10) // Noise
	write_byte(0) // R
	write_byte(255) // G
	write_byte(255) // B
	write_byte(255) // Bright
	write_byte(9) // Speed
	message_end()	
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Origin)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + floatround(g_FB_KnockRange))
	write_short(g_ShockWave_SprID)
	write_byte(0) // Start Frame
	write_byte(10) // Framerate
	write_byte(4) // Live Time
	write_byte(20) // Width
	write_byte(20) // Noise
	write_byte(0) // R
	write_byte(255) // G
	write_byte(0) // B
	write_byte(150) // Bright
	write_byte(9) // Speed
	message_end()		
	
	Check_KnockbackRadius(Origin)
		
	engfunc(EngFunc_RemoveEntity, Ent)
}

public Check_KnockbackRadius(Float:Origin[3])
{
	static Float:Velocity[3], Float:PlayerOrigin[3]
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!Get_BitVar(g_IsAlive, i))
			continue
		if(Get_BitVar(g_IsZombie, i)/* || Get_BitVar(g_IsNightStalker, i)*/)
		{	
			pev(i, pev_origin, PlayerOrigin)
			Get_SpeedVector(Origin, PlayerOrigin, float(g_FB_KnockPower), Velocity)
		
			set_pev(i, pev_velocity, Velocity)
		}
	}
}

public SG_CheckRadiusDamage(Ent)
{
	if(!g_GameStarted || g_GameEnded || !g_InfectionStart)
		return
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!Get_BitVar(g_IsAlive, i))
			continue
		if(entity_range(Ent, i) > g_SG_DmgRange)
			continue
		if(Get_BitVar(g_IsZombie, i)/* || Get_BitVar(g_IsNightStalker, i)*/)
		{		
			static Health; Health = get_user_health(i)
			if(Health <= 1) continue
			
			static NewHealth; NewHealth = Health - g_SG_DmgPerSec
			if(NewHealth > 0) SetPlayerHealth(i, NewHealth, 0)
			else SetPlayerHealth(i, 1, 0)
		}
	}
}

// ======================= NATIVE ========================
// =======================================================
public Native_GetUserZombie(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
	
	return Get_BitVar(g_IsZombie, id)
}

public Native_GetZombieClass(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	return g_ZombieClass[id]
}

public Native_SetUserHealth(id, Health, Full)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	SetPlayerHealth(id, Health, Full)
	return 1
}

public Native_GetUserHealth(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	return g_MaxHealth[id]
}

public Native_SetNVG(id, Give, On, Sound, IgnoreHadNVG)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	if(Give) Set_BitVar(g_Has_NightVision, id)
	set_user_nightvision(id, On, Sound, IgnoreHadNVG)
	
	return 1
}

public Native_GetNVG(id, Have, On)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
	
	if(Have && !On)
	{
		if(Get_BitVar(g_Has_NightVision, id) && !Get_BitVar(g_UsingNVG, id))
			return 1
	} else if(!Have && On) {
		if(!Get_BitVar(g_Has_NightVision, id) && Get_BitVar(g_UsingNVG, id))
			return 1
	} else if(Have && On) {
		if(Get_BitVar(g_Has_NightVision, id) && Get_BitVar(g_UsingNVG, id))
			return 1
	} else if(!Have && !On) {
		if(!Get_BitVar(g_Has_NightVision, id) && !Get_BitVar(g_UsingNVG, id))
			return 1
	}
	
	return 0	
}

public Native_GetRoundDamage(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	return g_RoundStat[id][STAT_DMG]
}

public Native_GetRoundScore(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	return g_RoundStat[id][STAT_SCORE]
}

public Native_SetPower(id, Power)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	g_AdrenalinePower[id] = Power
		
	return 1
}

public Native_GetPower(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	return g_AdrenalinePower[id]
}

public Native_SHudFastUpdate(id, Fast)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
	
	if(Fast) Set_BitVar(g_HudFastUpdate, id)
	else UnSet_BitVar(g_HudFastUpdate, id)
	
	return 1
}

public Native_GHudFastUpdate(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0

	return Get_BitVar(g_HudFastUpdate, id)
}

public Native_SetStatus(id, Status, Value)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	switch(Status)
	{
		case STATUS_HEALTH: g_HealthStatus[id] = Value
		case STATUS_SPEED: g_SpeedStatus[id] = Value
		case STATUS_STRENGTH: g_StrengthStatus[id] = Value 
	}
	
	return 1
}

public Native_GetStatus(id, Status)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	switch(Status)
	{
		case STATUS_HEALTH: return g_HealthStatus[id]
		case STATUS_SPEED: return g_SpeedStatus[id]
		case STATUS_STRENGTH: return g_StrengthStatus[id]
	}
	
	return 0
}

public Native_GetDayTime()
{
	return g_DayTime
}

public Native_SetFakeAttack(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	static Ent; Ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
	if(!pev_valid(Ent)) return 0
	
	static Float:NextAttack, Anim; NextAttack = get_pdata_float(id, 83, 5); Anim = pev(id, pev_weaponanim)
	Set_BitVar(g_TempingAttack, id)
	ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)	
	UnSet_BitVar(g_TempingAttack, id)
	set_pdata_float(id, 83, NextAttack, 5)
	if(pev(id, pev_weaponanim) != Anim) Set_WeaponAnim(id, Anim)
	
	return 1
}

public Native_GetStun(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	return Get_BitVar(g_Stunning, id)
}

public Native_GetSlowDown(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	return Get_BitVar(g_Slowdown, id)
}

public Native_Get_NightStalker(id)
{
	if(!Get_BitVar(g_Connected, id))
		return 0
		
	return 0 // Get_BitVar(g_IsNightStalker, id)
}

public Array:Native_GetArrayID(Attribute)
{
	static Array:SelectedArray

	switch(Attribute)
	{
		case class_name: SelectedArray = ZombieName
		case class_desc: SelectedArray = ZombieDesc
		case class_speed: SelectedArray = ZombieSpeed
		case class_gravity: SelectedArray = ZombieGravity
		case class_knockback: SelectedArray = ZombieKnockback
		case class_defense: SelectedArray = ZombieDefense
		case class_healthregen: SelectedArray = ZombieHealthRegen
		case class_model: SelectedArray = ZombieModel
		case class_clawmodel: SelectedArray = ZombieClawModel
		case class_deathsound: SelectedArray = ZombieDeathSound
		case class_painsound1: SelectedArray = ZombiePainSound1
		case class_painsound2: SelectedArray = ZombiePainSound2
		case class_stunsound: SelectedArray = ZombieStunSound
		case class_cost: SelectedArray = ZombieCost
	}
	
	return SelectedArray
}

public Native_Register_ZombieClass(const Name[], const Desc[], Float:Speed, Float:Gravity, Float:Knockback, Float:Defense, HealthRegen, const Model[], const ClawModel[], const DeathSound[], const PainSound1[], const PainSound2[], const StunSound[], Cost)
{
	param_convert(1)
	param_convert(2)
	param_convert(8)
	param_convert(9)
	param_convert(10)
	param_convert(11)
	param_convert(12)
	param_convert(13)
	
	ArrayPushString(ZombieName, Name)
	ArrayPushString(ZombieDesc, Desc)
	
	ArrayPushCell(ZombieSpeed, Speed)
	ArrayPushCell(ZombieGravity, Gravity)
	ArrayPushCell(ZombieKnockback, Knockback)
	ArrayPushCell(ZombieDefense, Defense)
	ArrayPushCell(ZombieHealthRegen, HealthRegen)
	
	ArrayPushString(ZombieModel, Model)
	ArrayPushString(ZombieClawModel, ClawModel)
	ArrayPushString(ZombieDeathSound, DeathSound)
	ArrayPushString(ZombiePainSound1, PainSound1)
	ArrayPushString(ZombiePainSound2, PainSound2)
	ArrayPushString(ZombieStunSound, StunSound)
	
	ArrayPushCell(ZombieCost, Cost)
	
	// Precache those shits... of course :)
	new BufferA[64]
	formatex(BufferA, sizeof(BufferA), "models/player/%s/%s.mdl", Model, Model)
	engfunc(EngFunc_PrecacheModel, BufferA); 
	
	formatex(BufferA, sizeof(BufferA), "models/%s/%s", GAME_FOLDER, ClawModel)
	engfunc(EngFunc_PrecacheModel, BufferA); 
	
	engfunc(EngFunc_PrecacheSound, DeathSound)
	engfunc(EngFunc_PrecacheSound, PainSound1)
	engfunc(EngFunc_PrecacheSound, PainSound2)
	engfunc(EngFunc_PrecacheSound, StunSound)
	
	g_ZombieClass_Count++
	return g_ZombieClass_Count - 1
}

// ======================== STOCK ========================
// =======================================================
stock Get_PlayerCount( GetPlayersFlags:Flag, Team)
// Alive: 0 - Dead | 1 - Alive | 2 - Both
// Team: 1 - T | 2 - CT
{
	new szTeamName[12]
	new Players[32], PlayerNum
	
	Flag |= GetPlayers_MatchTeam | GetPlayers_ExcludeHLTV

	if(Team == 1) 
	{
		formatex(szTeamName, sizeof(szTeamName), "TERRORIST")
	} else if(Team == 2) 
	{
		formatex(szTeamName, sizeof(szTeamName), "CT")
	}
	
	get_players_ex(Players, PlayerNum, Flag, szTeamName)
	
	return PlayerNum
}

stock Get_ZombieAlive2()
{
	new Count
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!Get_BitVar(g_Connected, i))
			continue
		if(Get_BitVar(g_IsZombie, i)/* || Get_BitVar(g_IsNightStalker, i)*/)
		{
			if(Get_BitVar(g_PermanentDeath, i))
				continue
				
			Count++
		}
	}
	
	return Count
}

stock Get_TotalInPlayer(GetPlayersFlags:Alive)
{
	return Get_PlayerCount(Alive, 1) + Get_PlayerCount(Alive, 2)
}

public Load_GameSetting()
{
	static Buffer[16], Buffer2[3][12]
	
	// Gameplay
	g_MinPlayer = Setting_Load_Int(SETTING_FILE, "Gameplay", "MIN_PLAYER")
	g_CountDown_Time = Setting_Load_Int(SETTING_FILE, "Gameplay", "COUNTDOWN_TIME")
	
	// Human
	g_HumanHealth = Setting_Load_Int(SETTING_FILE, "Human", "HUMAN_HEALTH")
	g_HumanArmor = Setting_Load_Int(SETTING_FILE, "Human", "HUMAN_ARMOR")
	Setting_Load_String(SETTING_FILE, "Human", "HUMAN_GRAVITY", Buffer, sizeof(Buffer)); g_HumanGravity = str_to_float(Buffer)
	Setting_Load_StringArray(SETTING_FILE, "Human", "HUMAN_MODEL", HumanModel)
	
	// Grenade
	Setting_Load_String(SETTING_FILE, "Grenade", "HE_DAMAGE_MULTI", Buffer, sizeof(Buffer)); g_HE_DmgMulti = str_to_float(Buffer)
	g_FB_OnImpact = Setting_Load_Int(SETTING_FILE, "Grenade", "FB_ONIMPACT")
	Setting_Load_String(SETTING_FILE, "Grenade", "FB_KNOCK_RANGE", Buffer, sizeof(Buffer)); g_FB_KnockRange = str_to_float(Buffer)
	g_FB_KnockPower = Setting_Load_Int(SETTING_FILE, "Grenade", "FB_KNOCK_POWER")
	Setting_Load_String(SETTING_FILE, "Grenade", "FB_EXP_SOUND", g_FB_ExpSound, sizeof(g_FB_ExpSound))
	g_SG_DmgPerSec = Setting_Load_Int(SETTING_FILE, "Grenade", "SG_DMGPERSEC")
	Setting_Load_String(SETTING_FILE, "Grenade", "SG_DMGRANGE", Buffer, sizeof(Buffer)); g_SG_DmgRange = str_to_float(Buffer)
	
	// Zombie
	g_ZombieRandomClass = Setting_Load_Int(SETTING_FILE, "Zombie", "ZOMBIE_RANDOMCLASS")
	g_ZombieClassSelectTime = Setting_Load_Int(SETTING_FILE, "Zombie", "ZOMBIE_TIMECLASSSELECTION")
	g_ZombieInfectRewardMoney = Setting_Load_Int(SETTING_FILE, "Zombie", "ZOMBIE_INFECTREWARDMONEY")
	g_NightHealthIncPer = Setting_Load_Int(SETTING_FILE, "Zombie", "ZOMBIE_NIGHTHEALTHINCREASEPERCENT")
	
	g_Zombie_FirstMaxHealth = Setting_Load_Int(SETTING_FILE, "Zombie", "ZOMBIE_FIRSTMAXHEALTH")
	g_Zombie_FirstMinHealth = Setting_Load_Int(SETTING_FILE, "Zombie", "ZOMBIE_FIRSTMINHEALTH")
	g_ZombieMaxHealth = Setting_Load_Int(SETTING_FILE, "Zombie", "ZOMBIE_MAXHEALTH")
	g_ZombieMinHealth = Setting_Load_Int(SETTING_FILE, "Zombie", "ZOMBIE_MINHEALTH")
	g_Zombie_MinArmor = Setting_Load_Int(SETTING_FILE, "Zombie", "ZOMBIE_MINARMOR")
	g_Zombie_MaxArmor = Setting_Load_Int(SETTING_FILE, "Zombie", "ZOMBIE_MAXARMOR")
	
	Setting_Load_String(SETTING_FILE, "Zombie", "ZOMBIE_SLOWDOWNTIME", Buffer, sizeof(Buffer)); g_ZombieSlowdownTime = str_to_float(Buffer)
	
	// Stun
	Setting_Load_String(SETTING_FILE, "Stun", "STUN_TIME", Buffer, sizeof(Buffer)); g_StunTime = str_to_float(Buffer)
	Setting_Load_String(SETTING_FILE, "Stun", "STUN_EFSPR", g_StunEfSpr, sizeof(g_StunEfSpr))
	g_StunClawAnim = Setting_Load_Int(SETTING_FILE, "Stun", "STUN_CLAWANIM")
	g_StunClawAfterAnim = Setting_Load_Int(SETTING_FILE, "Stun", "STUN_CLAWAFTERANIM")
	g_StunPlayerAnim = Setting_Load_Int(SETTING_FILE, "Stun", "STUN_PLAYERANIM")
	
	// Knockback
	g_KB_Damage = Setting_Load_Int(SETTING_FILE, "Knockback", "KB_BYDAMAGE")
	g_KB_WeaponPower = Setting_Load_Int(SETTING_FILE, "Knockback", "KB_BYWEAPONPOWER")
	g_KB_ZombieClass = Setting_Load_Int(SETTING_FILE, "Knockback", "KB_BYZOMBIECLASS")
	g_KB_ZVEL = Setting_Load_Int(SETTING_FILE, "Knockback", "KB_BYZVEL")
	Setting_Load_String(SETTING_FILE, "Knockback", "KB_DUCKING", Buffer, sizeof(Buffer)); g_KB_Ducking = str_to_float(Buffer)
	Setting_Load_String(SETTING_FILE, "Knockback", "KB_DISTANCE", Buffer, sizeof(Buffer)); g_KB_Distance = str_to_float(Buffer)

	// Respawn
	g_ZombieRespawnTime = Setting_Load_Int(SETTING_FILE, "Respawn", "ZOMBIE_RESPAWN_TIME")
	Setting_Load_String(SETTING_FILE, "Respawn", "ZOMBIE_RESPAWN_SPR", g_ZombieRespawnSpr, sizeof(g_ZombieRespawnSpr))
	
	// Concentrated Fire
	Setting_Load_String(SETTING_FILE, "Concentrated Fire", "CF_DAMAGE_MULTI", Buffer, sizeof(Buffer)); g_CFDmgMulti = str_to_float(Buffer)
	g_CFAvaiPer = Setting_Load_Int(SETTING_FILE, "Concentrated Fire", "CF_AVAILABLE_PERCENT")
	g_CFDecPer01S = Setting_Load_Int(SETTING_FILE, "Concentrated Fire", "CF_DECREASE_PER01SEC")
	Setting_Load_String(SETTING_FILE, "Concentrated Fire", "CF_ACTIVE_SOUND", g_CFSound, sizeof(g_CFSound))
	Setting_Load_String(SETTING_FILE, "Concentrated Fire", "CF_EFFECT_SPR", g_CFEfSpr, sizeof(g_CFEfSpr))
	
	// Night Vision
	g_NVG_Alpha = Setting_Load_Int(SETTING_FILE, "Night Vision", "NVG_ALPHA")
	
	Setting_Load_String(SETTING_FILE, "Night Vision", "NVG_HUMAN_COLOR", Buffer, sizeof(Buffer))
	parse(Buffer, Buffer2[0], 11, Buffer2[1], 11, Buffer2[2], 11)
	g_NVG_HumanColor[0] = str_to_num(Buffer2[0])
	g_NVG_HumanColor[1] = str_to_num(Buffer2[1])
	g_NVG_HumanColor[2] = str_to_num(Buffer2[2])
	
	Setting_Load_String(SETTING_FILE, "Night Vision", "NVG_ZOMBIE_COLOR", Buffer, sizeof(Buffer))
	parse(Buffer, Buffer2[0], 11, Buffer2[1], 11, Buffer2[2], 11)
	g_NVG_ZombieColor[0] = str_to_num(Buffer2[0])
	g_NVG_ZombieColor[1] = str_to_num(Buffer2[1])
	g_NVG_ZombieColor[2] = str_to_num(Buffer2[2])	

	// Sound
	Setting_Load_String(SETTING_FILE, "Sound", "SOUND_COUNTING", S_GameCount, sizeof(S_GameCount))
	
	Setting_Load_String(SETTING_FILE, "Sound", "SOUND_GAMESTART", S_GameStart, sizeof(S_GameStart))
	Setting_Load_String(SETTING_FILE, "Sound", "SOUND_NIGHTMARE", S_Nightmare, sizeof(S_Nightmare))
	Setting_Load_String(SETTING_FILE, "Sound", "SOUND_DAYLIGHT", S_Daylight, sizeof(S_Daylight))
	Setting_Load_String(SETTING_FILE, "Sound", "SOUND_PLANEDROP", S_PlaneDrop, sizeof(S_PlaneDrop))

	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_WIN_HUMAN", S_WinHuman)
	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_WIN_ZOMBIE", S_WinZombie)
	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_INFECTION", S_Infection)
	
	Setting_Load_String(SETTING_FILE, "Sound", "SOUND_MESSAGE_HUMAN", S_MessageHuman, sizeof(S_MessageHuman))
	Setting_Load_String(SETTING_FILE, "Sound", "SOUND_MESSAGE_ZOMBIE", S_MessageZombie, sizeof(S_MessageZombie))
	Setting_Load_String(SETTING_FILE, "Sound", "SOUND_SKILL_AVAILABLE", S_SkillAvailable, sizeof(S_SkillAvailable))
	
	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_ZOMBIE_COMING", S_ZombieComing)
	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_ZOMBIE_COMEBACK", S_ZombieComeBack)
	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_ZOMBIE_SWING", S_ClawSwing)
	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_ZOMBIE_HIT", S_ClawHit)
	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_ZOMBIE_WALL", S_ClawWall)
	
	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_KICK_MISS", S_KickMiss)
	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_KICK_HIT", S_KickHit)
	Setting_Load_StringArray(SETTING_FILE, "Sound", "SOUND_KICK_WALL", S_KickWall)
}

/*
public Load_Class_NightStalker()
{
	static Temp[32]
	
	formatex(g_HiddenName, sizeof(g_HiddenName), "%L", LANG_SERVER, "ZOMBIE_CLASS_NIGHTSTALKER_NAME")
	formatex(g_HiddenDesc, sizeof(g_HiddenDesc), "%L", LANG_SERVER, "ZOMBIE_CLASS_NIGHTSTALKER_DESC")
	
	Setting_Load_String(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_SPEED", Temp, sizeof(Temp)); g_HiddenSpeed = str_to_float(Temp)
	Setting_Load_String(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_GRAVITY", Temp, sizeof(Temp)); g_HiddenGravity = str_to_float(Temp)
	Setting_Load_String(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_KNOCKBACK", Temp, sizeof(Temp)); g_HiddenKnockback = str_to_float(Temp)
	Setting_Load_String(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_DEFENSE", Temp, sizeof(Temp)); g_HiddenDefense = str_to_float(Temp)
	g_HiddenHealthRegen = Setting_Load_Int(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_HEALTHREGEN")
	
	Setting_Load_String(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_MODEL", g_HiddenModel, sizeof(g_HiddenModel))
	Setting_Load_String(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_CLAWMODEL", g_HiddenClawModel, sizeof(g_HiddenClawModel))
	Setting_Load_String(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_DEATHSOUND", g_HiddenDeathSound, sizeof(g_HiddenDeathSound))
	Setting_Load_String(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_PAINSOUND1", g_HiddenPainSound1, sizeof(g_HiddenPainSound1))
	Setting_Load_String(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_PAINSOUND2", g_HiddenPainSound2, sizeof(g_HiddenPainSound2))
	Setting_Load_String(CLASSSETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_STUNSOUND", g_HiddenStunSound, sizeof(g_HiddenStunSound))
}*/

public Precache_GameSetting()
{
	// Load Model
	new i, BufferA[64], BufferB[64]
	for(i = 0; i < ArraySize(HumanModel); i++) 
	{
		ArrayGetString(HumanModel, i, BufferA, sizeof(BufferA)); formatex(BufferB, sizeof(BufferB), "models/player/%s/%s.mdl", BufferA, BufferA)
		engfunc(EngFunc_PrecacheModel, BufferB); 
	}
	
	// Load Sound
	for (new i = 1; i <= 10; i++) { formatex(BufferB, charsmax(BufferB), S_GameCount, i); engfunc(EngFunc_PrecacheSound, BufferB); }	
	
	engfunc(EngFunc_PrecacheSound, S_GameStart)
	engfunc(EngFunc_PrecacheSound, S_Nightmare)
	engfunc(EngFunc_PrecacheSound, S_Daylight)
	engfunc(EngFunc_PrecacheSound, S_PlaneDrop)
	
	for(i = 0; i < ArraySize(S_WinHuman); i++) { ArrayGetString(S_WinHuman, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(S_WinZombie); i++) { ArrayGetString(S_WinZombie, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(S_Infection); i++) { ArrayGetString(S_Infection, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	
	engfunc(EngFunc_PrecacheSound, S_MessageHuman)
	engfunc(EngFunc_PrecacheSound, S_MessageZombie)
	engfunc(EngFunc_PrecacheSound, S_SkillAvailable)
	engfunc(EngFunc_PrecacheSound, g_CFSound)
	engfunc(EngFunc_PrecacheSound, g_FB_ExpSound)
	
	for(i = 0; i < ArraySize(S_ZombieComing); i++) { ArrayGetString(S_ZombieComing, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(S_ZombieComeBack); i++) { ArrayGetString(S_ZombieComeBack, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(S_ClawSwing); i++) { ArrayGetString(S_ClawSwing, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(S_ClawHit); i++) { ArrayGetString(S_ClawHit, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(S_ClawWall); i++) { ArrayGetString(S_ClawWall, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	
	for(i = 0; i < ArraySize(S_KickMiss); i++) { ArrayGetString(S_KickMiss, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(S_KickHit); i++) { ArrayGetString(S_KickHit, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(S_KickWall); i++) { ArrayGetString(S_KickWall, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }

	g_ZombieRespawnSprID = engfunc(EngFunc_PrecacheModel, g_ZombieRespawnSpr)
	g_CFEfSprId = engfunc(EngFunc_PrecacheModel, g_CFEfSpr)
	engfunc(EngFunc_PrecacheModel, g_StunEfSpr)
}

/*
public Precache_Class_NightStalker()
{
	static Buffer[64]
	
	formatex(Buffer, sizeof(Buffer), "models/player/%s/%s.mdl", g_HiddenModel, g_HiddenModel); engfunc(EngFunc_PrecacheModel, Buffer)
	formatex(Buffer, sizeof(Buffer), "models/%s/%s", GAME_FOLDER, g_HiddenClawModel); engfunc(EngFunc_PrecacheModel, Buffer)
	
	engfunc(EngFunc_PrecacheSound, g_HiddenDeathSound)
	engfunc(EngFunc_PrecacheSound, g_HiddenPainSound1)
	engfunc(EngFunc_PrecacheSound, g_HiddenPainSound2)
	engfunc(EngFunc_PrecacheSound, g_HiddenStunSound)
}*/

stock Setting_Load_Int(const filename[], const setting_section[], setting_key[])
{
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZD] Can't load settings: empty filename")
		return false;
	}
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZD] Can't load settings: empty section/key")
		return false;
	}
	
	// Build customization file path
	new path[128]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s/%s", path, GAME_FOLDER, filename)
	
	// File not present
	if (!file_exists(path))
	{
		static DataA[128]; formatex(DataA, sizeof(DataA), "[ZD] Can't load: %s", path)
		set_fail_state(DataA)
		
		return false;
	}
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], current_value[32]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and value
		strtok(linedata, key, charsmax(key), current_value, charsmax(current_value), '=')
		
		// Trim spaces
		trim(key)
		trim(current_value)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			static return_value
			// Return int by reference
			return_value = str_to_num(current_value)
			
			// Values succesfully retrieved
			fclose(file)
			return return_value
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

stock Setting_Load_StringArray(const filename[], const setting_section[], setting_key[], Array:array_handle)
{
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZD] Can't load settings: empty filename")
		return false;
	}

	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZD] Can't load settings: empty section/key")
		return false;
	}
	
	if (array_handle == Invalid_Array)
	{
		log_error(AMX_ERR_NATIVE, "[ZD] Array not initialized")
		return false;
	}
	
	// Build customization file path
	new path[128]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s/%s", path, GAME_FOLDER, filename)
	
	// File not present
	if (!file_exists(path))
	{
		static DataA[128]; formatex(DataA, sizeof(DataA), "[ZD] Can't load: %s", path)
		set_fail_state(DataA)
		
		return false;
	}
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], current_value[128]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			// Parse values
			while (values[0] != 0 && strtok(values, current_value, charsmax(current_value), values, charsmax(values), ','))
			{
				// Trim spaces
				trim(current_value)
				trim(values)
				
				// Add to array
				ArrayPushString(array_handle, current_value)
			}
			
			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

stock Setting_Load_String(const filename[], const setting_section[], setting_key[], return_string[], string_size)
{
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZD] Can't load settings: empty filename")
		return false;
	}

	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZD] Can't load settings: empty section/key")
		return false;
	}
	
	// Build customization file path
	new path[128]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s/%s", path, GAME_FOLDER, filename)
	
	// File not present
	if (!file_exists(path))
	{
		static DataA[128]; formatex(DataA, sizeof(DataA), "[ZD] Can't load: %s", path)
		set_fail_state(DataA)
		
		return false;
	}
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], current_value[128]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and value
		strtok(linedata, key, charsmax(key), current_value, charsmax(current_value), '=')
		
		// Trim spaces
		trim(key)
		trim(current_value)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			formatex(return_string, string_size, "%s", current_value)
			
			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

stock is_hull_vacant(Float:Origin[3], hull)
{
	engfunc(EngFunc_TraceHull, Origin, Origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true
	
	return false
}

stock collect_spawns_ent(const classname[])
{
	static ent; ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		static Float:originF[3]
		pev(ent, pev_origin, originF)
		
		g_PlayerSpawn_Point[g_PlayerSpawn_Count][0] = originF[0]
		g_PlayerSpawn_Point[g_PlayerSpawn_Count][1] = originF[1]
		g_PlayerSpawn_Point[g_PlayerSpawn_Count][2] = originF[2]
		
		// increase spawn count
		g_PlayerSpawn_Count++
		if(g_PlayerSpawn_Count >= sizeof g_PlayerSpawn_Point) break;
	}
}

stock SetPlayerLight(id, const LightStyle[])
{
	if(id != 0)
	{
		message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, .player = id)
		write_byte(0)
		write_string(LightStyle)
		message_end()		
	} else {
		message_begin(MSG_BROADCAST, SVC_LIGHTSTYLE)
		write_byte(0)
		write_string(LightStyle)
		message_end()	
	}
}

stock Get_RandomArray(Array:ArrayName)
{
	return random_num(0, ArraySize(ArrayName) - 1)
}

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}

stock StopSound(id) client_cmd(id, "mp3 stop; stopsound")
stock EmitSound(id, Channel, const Sound[]) emit_sound(id, Channel, Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
stock client_printc(index, const text[], any:...)
{
	static szMsg[128]; vformat(szMsg, sizeof(szMsg) - 1, text, 3)

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04")
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01")
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03")

	if(!index)
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!Get_BitVar(g_Connected, i))
				continue
				
			message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, i);
			write_byte(i);
			write_string(szMsg);
			message_end();	
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 


stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock Set_Player_NextAttack(id, Float:Time)
{
	if(pev_valid(id) != PDATA_SAFE)
		return
		
	set_pdata_float(id, 83, Time, 5)
}

stock MakeBlood(const Float:Origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(5)
	message_end()
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

public set_scoreboard_attrib(id, attrib) // 0 - Nothing; 1 - Dead; 2 - VIP
{
	message_begin(MSG_BROADCAST, g_MsgScoreAttrib)
	write_byte(id) // id
	switch(attrib)
	{
		case 1: write_byte(1<<0)
		case 2: write_byte(1<<2)
		default: write_byte(0)
	}
	message_end()	
}

stock Set_PlayerStopTime(id, Float:Time)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
	if(pev_valid(Ent)) 
	{
		// Fake Attack
		Set_BitVar(g_TempingAttack, id)
		ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)	
		UnSet_BitVar(g_TempingAttack, id)
		
		set_pdata_float(Ent, 48, Time + 3.0, 4)
	}
	
	set_pdata_float(id, 83, Time, 5)
}

stock FixedUnsigned16(Float:flValue, iScale)
{
	new iOutput;

	iOutput = floatround(flValue * iScale);

	if ( iOutput < 0 )
		iOutput = 0;

	if ( iOutput > 0xFFFF )
		iOutput = 0xFFFF;

	return iOutput;
}

stock Get_SpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= (num * 2.0)
	new_velocity[1] *= (num * 2.0)
	new_velocity[2] *= (num / 2.0)
}  
public set_playermodel(id, const model[], bool:update_index )
{
	if(!is_user_alive(id))
		return false

	return rg_set_user_model(id,model,update_index);
}

public set_team(id, team)
{
	if(!is_user_connected(id))
		return

	switch(team)
	{
		case TEAM_HUMAN:  /*if(fm_cs_get_user_team(id) != TEAM_CT)*/ fm_cs_set_user_team(id, TEAM_CT, 1)
		case TEAM_ZOMBIE: /*if(fm_cs_get_user_team(id) != TEAM_TERRORIST)*/ fm_cs_set_user_team(id, TEAM_TERRORIST, 1)
	}
}
public set_maxspeed(id, Float:speed)
{
	if(!is_user_connected(id))
		return

	set_pev(id, pev_maxspeed, speed)
}
stock fm_cs_get_user_deaths(client)
{
	return get_member(client, m_iDeaths);
}
stock fm_cs_set_user_deaths(client, num)
{
	return get_member(client, m_iDeaths, num);
}
// Set a Player's Team
stock fm_cs_set_user_team(id, TeamName:team, send_message)
{
	remove_task(id+TASK_TEAMMSG)
	set_member(id, m_iTeam, team);
	// rg_set_user_team(id, TeamName:team) // bug: fakeclient can't join game
	if (send_message) set_task(TEAMCHANGE_DELAY, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG)
}

// Send User Team Message (Note: this next message can be received by other plugins)
public fm_cs_set_user_team_msg(taskid)
{
	// Tell everyone my new team
	emessage_begin(MSG_ALL, get_user_msgid("TeamInfo"))
	ewrite_byte(ID_TEAMMSG) // player
	ewrite_string(CS_TEAM_NAMES[_:fm_cs_get_user_team(ID_TEAMMSG)]) // team
	emessage_end()

	// Fix for AMXX/CZ bots which update team paramater from ScoreInfo message
	emessage_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
	ewrite_byte(ID_TEAMMSG) // id
	ewrite_short(pev(ID_TEAMMSG, pev_frags)) // frags
	ewrite_short(fm_cs_get_user_deaths(ID_TEAMMSG)) // deaths
	ewrite_short(0) // class?
	ewrite_short(_:fm_cs_get_user_team(ID_TEAMMSG)) // team
	emessage_end()
}

stock fm_cs_get_user_team(client)
{
	new team = get_member(client, m_iTeam);
	return team;
}


