#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <ZombieDarkness>
#include <reapi>
#include <xs>

#define PLUGIN "[ZD] Zombie Class: Regular"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define SETTING_FILE "ZombieDarkness_Classes.ini"
#define LANG_FILE "ZombieDarkness.txt"

#define HUD_ADRENALINE_X -1.0
#define HUD_ADRENALINE_Y 0.83

new g_zombieclass
new zclass_name[16], zclass_desc[32]
new Float:zclass_speed, Float:zclass_gravity, Float:zclass_knockback, Float:zclass_defense, zclass_healthregen
new zclass_model[16], zclass_clawmodel[32], zclass_deathsound[64], 
zclass_painsound1[64], zclass_painsound2[64], zclass_stunsound[64],
zclass_cost

// Skill: Berserk
#define TIME_INTERVAL 0.25
#define TASK_CHECKTIME 3125365

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_IsUserAlive, g_BotHamRegister, g_IsUserBot
new g_PlayerKey[33][2], g_SprintingSkill, Float:CheckTime[33], Float:CheckTime2[33], Float:CheckTime3[33]
new g_ClimbingSkill, g_ClimbHigh, g_ClimbPowerReq, g_ClimbSound[64]
new SprintSpeed, SprintPower015S, Array:SprintHeartSound
new g_MsgScreenFade, g_GameStart, g_SkillHud, Float:SprintDefense

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("DeathMsg", "Event_Death", "a")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
		
	register_forward(FM_CmdStart, "fw_CmdStart")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
		
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	g_SkillHud = CreateHudSyncObj(3)
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)
	
	SprintHeartSound = ArrayCreate(64, 1)
	
	Load_Class_Setting()
	g_zombieclass = zd_register_zombieclass(zclass_name, zclass_desc, zclass_speed, zclass_gravity, zclass_knockback, zclass_defense, zclass_healthregen, zclass_model, zclass_clawmodel, zclass_deathsound, zclass_painsound1, zclass_painsound2, zclass_stunsound, zclass_cost)
}

public Load_Class_Setting()
{
	static Temp[128]
	
	formatex(zclass_name, sizeof(zclass_name), "%L", LANG_SERVER, "ZOMBIE_CLASS_REGULAR_NAME")
	formatex(zclass_desc, sizeof(zclass_desc), "%L", LANG_SERVER, "ZOMBIE_CLASS_REGULAR_DESC")
	
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_SPEED", Temp, sizeof(Temp)); zclass_speed = str_to_float(Temp)
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_GRAVITY", Temp, sizeof(Temp)); zclass_gravity = str_to_float(Temp)
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_KNOCKBACK", Temp, sizeof(Temp)); zclass_knockback = str_to_float(Temp)
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_DEFENSE", Temp, sizeof(Temp)); zclass_defense = str_to_float(Temp)
	zclass_healthregen = Setting_Load_Int(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_HEALTHREGEN")

	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_MODEL", zclass_model, sizeof(zclass_model))
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_CLAWMODEL", zclass_clawmodel, sizeof(zclass_clawmodel))
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_DEATHSOUND", zclass_deathsound, sizeof(zclass_deathsound))
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_PAINSOUND1", zclass_painsound1, sizeof(zclass_painsound1))
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_PAINSOUND2", zclass_painsound2, sizeof(zclass_painsound2))
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_STUNSOUND", zclass_stunsound, sizeof(zclass_stunsound))

	zclass_cost = Setting_Load_Int(SETTING_FILE, "Zombie Class", "CLASS_REGULAR_COST")
	
	// Skill
	SprintSpeed = Setting_Load_Int(SETTING_FILE, "Zombie Regular", "SPRINT_SPEED")
	SprintPower015S = Setting_Load_Int(SETTING_FILE, "Zombie Regular", "SPRINT_DECREASE_PER015SEC")
	Setting_Load_String(SETTING_FILE, "Zombie Regular", "SPRINT_DEFENSE", Temp, sizeof(Temp)); SprintDefense = str_to_float(Temp)
	Setting_Load_StringArray(SETTING_FILE, "Zombie Regular", "SPRINT_HEARTSOUND", SprintHeartSound);
	for(new i = 0; i < ArraySize(SprintHeartSound); i++)
	{
		ArrayGetString(SprintHeartSound, i, Temp, sizeof(Temp))
		engfunc(EngFunc_PrecacheSound, Temp)
	}
	
	g_ClimbHigh = Setting_Load_Int(SETTING_FILE, "Zombie Regular", "CLIMB_HIGH")
	g_ClimbPowerReq = Setting_Load_Int(SETTING_FILE, "Zombie Regular", "CLIMB_POWERREQ")
	Setting_Load_String(SETTING_FILE, "Zombie Regular", "CLIMB_SOUND", g_ClimbSound, sizeof(g_ClimbSound)); engfunc(EngFunc_PrecacheSound, g_ClimbSound)
}

public zd_game_start() g_GameStart = 1
public zd_round_end() g_GameStart = 0

public zd_user_spawned(id, Zombie) Reset_Skill(id)
public zd_user_infected(id) Reset_Skill(id)

public client_disconnect(id) UnSet_BitVar(g_IsUserAlive, id)
public client_putinserver(id)
{
	UnSet_BitVar(g_IsUserBot, id)
	if(!g_BotHamRegister && is_user_bot(id))
	{
		g_BotHamRegister = 1
		set_task(0.1, "Bot_RegisterHam", id)
	}
	
	if(is_user_bot(id)) Set_BitVar(g_IsUserBot, id)
	
	UnSet_BitVar(g_IsUserAlive, id)
}

public Bot_RegisterHam(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}

public fw_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsUserAlive, id)
}

public Event_Death()
{
	static Victim; Victim = read_data(2); UnSet_BitVar(g_IsUserAlive, Victim)
}

public zd_zombieclass_active(id, ClassID)
{
	if(ClassID != g_zombieclass)
		return
		
	Reset_Skill(id)
}

public zd_zombieclass_unactive(id, ClassID) 
{
	if(ClassID != g_zombieclass)
		return
		
	Reset_Skill(id)
}

public zd_zombie_stun(id) Reset_Skill(id)
public zd_zombie_slowdown(id) Reset_Skill(id)

public Reset_Skill(id)
{
	UnSet_BitVar(g_SprintingSkill, id)
	UnSet_BitVar(g_ClimbingSkill, id)
	
	Reset_Key(id)
}

public client_PreThink(id)
{
	if(!Get_BitVar(g_IsUserAlive, id))
		return
		
	static CurButton; CurButton = pev(id, pev_button)
	static OldButton; OldButton = pev(id, pev_oldbuttons)
	
	if((CurButton & IN_FORWARD)) 
	{
		if(!g_GameStart)
			return 
		if(!zd_get_user_zombie(id))
			return
		if(zd_get_user_zombieclass(id) != g_zombieclass)
			return
		if(zd_get_zombie_stun(id) || zd_get_zombie_slowdown(id))
			return
		if(Get_BitVar(g_SprintingSkill, id) && (get_gametime() - 0.15 > CheckTime[id]))
		{
			if(zd_get_user_power(id) <= 0)
			{
				Deactive_SprintSkill(id)
				return
			}
			if((pev(id, pev_flags) & FL_DUCKING) || pev(id, pev_bInDuck) || !(pev(id, pev_flags) & FL_ONGROUND))
			{
				Deactive_SprintSkill(id)
				return
			}
			
			// Handle Other
			if(!zd_get_hudfastupdate(id)) zd_set_hudfastupdate(id, 1)
			if(zd_get_user_status(id, STATUS_SPEED) != SPEED_INC) zd_set_user_status(id, STATUS_SPEED, SPEED_INC)
			if(zd_get_user_status(id, STATUS_STRENGTH) != STRENGTH_WEAKENING) zd_set_user_status(id, STATUS_STRENGTH, STRENGTH_WEAKENING)
			zd_set_user_power(id, zd_get_user_power(id) - SprintPower015S)
			
			CheckTime[id] = get_gametime()
		}	
			
		if(Get_BitVar(g_SprintingSkill, id) && (get_gametime() - 0.5 > CheckTime2[id]))
		{
			static String[128]; ArrayGetString(SprintHeartSound, Get_RandomArray(SprintHeartSound), String, sizeof(String))
			emit_sound(id, CHAN_VOICE, String, 1.0, ATTN_NORM, 0, PITCH_NORM)

			zd_set_fakeattack(id)
			
			set_pev(id, pev_framerate, 2.0)
			set_pev(id, pev_sequence, 111)
			
			CheckTime2[id] = get_gametime()
		}
		
		if(OldButton & IN_FORWARD)
			return
		
		if(!task_exists(id+TASK_CHECKTIME))
		{
			g_PlayerKey[id][0] = 'w'
			
			remove_task(id+TASK_CHECKTIME)
			set_task(TIME_INTERVAL, "Recheck_Key", id+TASK_CHECKTIME)
		} else {
			g_PlayerKey[id][1] = 'w'
		}
	} else {
		if(OldButton & IN_FORWARD)
		{
			Deactive_SprintSkill(id)
		}
		
		return
	}
	
	if(equali(g_PlayerKey[id], "ww"))
	{
		Reset_Key(id)
		Active_SprintSkill(id)
	}

	return
}

public fw_CmdStart(id, UCHandle, Seed)
{
	if(!Get_BitVar(g_IsUserAlive, id))
		return
	if(Get_BitVar(g_IsUserBot, id))
		return
	if(!zd_get_user_zombie(id))
		return
	if(zd_get_user_zombieclass(id) != g_zombieclass)
		return	
	
	static CurButton; CurButton = get_uc(UCHandle, UC_Buttons)
	static OldButton; OldButton = pev(id, pev_oldbuttons)
	
	if(get_gametime() - 1.0 > CheckTime3[id])
	{
		static Time; Time = zd_get_user_power(id) / g_ClimbPowerReq
		if(Time >= 1)
		{
			static SkillName[16]; formatex(SkillName, sizeof(SkillName), "%L", LANG_SERVER, "ZOMBIE_CLASS_REGULAR_SKILL")
			
			set_hudmessage(200, 200, 200, HUD_ADRENALINE_X, HUD_ADRENALINE_Y - 0.02, 0, 1.0, 1.0, 0.0, 0.0)
			ShowSyncHudMsg(id, g_SkillHud, "%L", LANG_SERVER, "HUD_ZOMBIESKILL", SkillName, Time)
		}
		
		CheckTime3[id] = get_gametime()
	}	
	
	if((CurButton & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
	{
		if(Get_BitVar(g_SprintingSkill, id)) Deactive_SprintSkill(id)
	}	
	
	if((CurButton & IN_ATTACK2))
	{
		CurButton &= ~IN_ATTACK2
		set_uc(UCHandle, UC_Buttons, CurButton)
		
		set_pdata_float(id, 83, 1.0, 5)
		if(!g_GameStart)
			return 
			
		if(zd_get_zombie_stun(id) || zd_get_zombie_slowdown(id))
			return
		
		if(get_gametime() - 0.5 > CheckTime[id])
		{
			if(zd_get_user_power(id) < g_ClimbPowerReq)
			{
				if(Get_BitVar(g_ClimbingSkill, id)) Deactive_ClimbSkill(id, 1)
				
				CheckTime[id] = get_gametime()
				return
			}
			
			
			ClimbHandle(id)
			
			CheckTime[id] = get_gametime()
		}
	} else {
		if(OldButton & IN_ATTACK2)
		{
			if(Get_BitVar(g_ClimbingSkill, id)) Deactive_ClimbSkill(id, 1)
		}
	}
}

public fw_TakeDamage(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	if(!g_GameStart)
		return HAM_IGNORED
	if(!zd_get_user_zombie(Victim) || zd_get_user_zombie(Attacker))
		return HAM_IGNORED
	if(zd_get_user_zombieclass(Victim) != g_zombieclass)
		return HAM_IGNORED
	if(!Get_BitVar(g_SprintingSkill, Victim))
		return HAM_IGNORED
		
	Damage /= SprintDefense
	SetHamParamFloat(4, Damage)
		
	return HAM_HANDLED
}

public ClimbHandle(id)
{
	static Float:Origin1[3], Float:Origin2[3], Float:Distance
	pev(id, pev_origin, Origin1)
	fm_get_aim_origin(id, Origin2)
	Distance = get_distance_f(Origin1, Origin2)
	
	if(Distance > 48.0) return
	
	zd_set_user_power(id, zd_get_user_power(id) - g_ClimbPowerReq)
	
	// Climb Action
	if(!Get_BitVar(g_ClimbingSkill, id))
	{
		Set_WeaponAnim(id, 6)
		Set_BitVar(g_ClimbingSkill, id)
	} else {
		Set_WeaponAnim(id, 8)
	}
	
	zd_set_fakeattack(id)
	set_pev(id, pev_framerate, 0.25)
	set_pev(id, pev_sequence, 113)
	
	Origin2 = Origin1; Origin2[2] += float(g_ClimbHigh)
	static Float:Velocity[3]; Get_SpeedVector(Origin1, Origin2, 500.0, Velocity)
	
	set_pev(id, pev_velocity, Velocity)
	emit_sound(id, CHAN_STATIC, g_ClimbSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public Deactive_ClimbSkill(id, Alive)
{
	zd_set_fakeattack(id)
	Set_WeaponAnim(id, 7)
	
	UnSet_BitVar(g_ClimbingSkill, id)
}

public Recheck_Key(id)
{
	id -= TASK_CHECKTIME
	
	if(!is_user_connected(id))
		return
		
	Reset_Key(id)
}

public Reset_Key(id)
{
	g_PlayerKey[id][0] = 0
	g_PlayerKey[id][1] = 0
}

public zd_user_nvg(id, On, Zombie)
{
	if(!Zombie) return
	if(!Get_BitVar(g_SprintingSkill, id))
		return
	
	if(!On)
	{
		// ScreenFade
		message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(0) // g
		write_byte(0) // b
		write_byte(35) // alpha
		message_end()
	}
}

public Active_SprintSkill(id)
{
	Set_BitVar(g_SprintingSkill, id)
	
	if(zd_get_user_nvg(id, 1, 0))
	{
		// ScreenFade
		message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(0) // g
		write_byte(0) // b
		write_byte(35) // alpha
		message_end()
	}
	
	// Set Speed
	set_pev(id, pev_maxspeed, float(SprintSpeed))
	// GM_Set_PlayerSpeed(id, float(SprintSpeed), 1)
}

public Deactive_SprintSkill(id)
{
	if(!Get_BitVar(g_SprintingSkill, id))
		return
	
	UnSet_BitVar(g_SprintingSkill, id)
	
	// Reset
	if(zd_get_user_nvg(id, 1, 0))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0000) // fade type
		write_byte(0) // r
		write_byte(0) // g
		write_byte(0) // b
		write_byte(0) // alpha
		message_end()
	}
	
	// Speed
	set_pev(id, pev_maxspeed, zclass_speed)
	// GM_Set_PlayerSpeed(id, zclass_speed, 1)
	
	zd_set_hudfastupdate(id, 0)
	zd_set_user_status(id, STATUS_SPEED, SPEED_NONE)
	zd_set_user_status(id, STATUS_STRENGTH, STRENGTH_NONE)
}

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
	format(path, charsmax(path), "%s/ZombieDarkness/%s", path, filename)
	
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
	format(path, charsmax(path), "%s/ZombieDarkness/%s", path, filename)
	
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
	format(path, charsmax(path), "%s/ZombieDarkness/%s", path, filename)
	
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

stock Get_RandomArray(Array:ArrayName)
{
	return random_num(0, ArraySize(ArrayName) - 1)
}

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
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
