#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <ZombieDarkness>
#include <reapi>

#define PLUGIN "[ZD] Zombie Class: Spin Diver"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define GAME_FOLDER "ZombieDarkness"
#define SETTING_FILE "ZombieDarkness_Classes.ini"
#define LANG_FILE "ZombieDarkness.txt"

#define HUD_ADRENALINE_X -1.0
#define HUD_ADRENALINE_Y 0.83

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

#define TIME_INTERVAL 0.25
#define TASK_CHECKTIME 3125365

// Loaded Vars
new g_zombieclass
new zclass_name[16], zclass_desc[32]
new Float:zclass_speed, Float:zclass_gravity, Float:zclass_knockback, Float:zclass_defense, zclass_healthregen
new zclass_model[16], zclass_clawmodel[32], zclass_deathsound[64], 
zclass_painsound1[64], zclass_painsound2[64], zclass_stunsound[64],
zclass_cost

new g_GameStart, g_IsUserBot, g_BotHamRegister, g_IsUserAlive
new Float:CheckTime[33], Float:CheckTime2[33], Float:CheckTime3[33], g_SkillHud
new g_PlayerKey[33][2], g_MsgScreenFade

new g_RollingSpeed, Float:g_RollingDefense, g_RollingDecPer01Sec, g_RollingSound[64]
new g_PouncePower, g_PounceHigh, g_PounceFar, g_PounceSound[64]

new g_Rolling, g_Leaping

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("DeathMsg", "Event_Death", "a")
	register_forward(FM_CmdStart, "fw_CmdStart")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")	
	
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	g_SkillHud = CreateHudSyncObj(3)
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)
	
	Load_ClassConfig()
	g_zombieclass = zd_register_zombieclass(zclass_name, zclass_desc, zclass_speed, zclass_gravity, zclass_knockback, zclass_defense, zclass_healthregen, zclass_model, zclass_clawmodel, zclass_deathsound, zclass_painsound1, zclass_painsound2, zclass_stunsound, zclass_cost)
}

public Load_ClassConfig()
{
	static Buffer[64], Temp[32]
	
	formatex(zclass_name, sizeof(zclass_name), "%L", LANG_SERVER, "ZOMBIE_CLASS_SPINDIVER_NAME")
	formatex(zclass_desc, sizeof(zclass_desc), "%L", LANG_SERVER, "ZOMBIE_CLASS_SPINDIVER_DESC")
	
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_SPEED", Temp, sizeof(Temp)); zclass_speed = str_to_float(Temp)
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_GRAVITY", Temp, sizeof(Temp)); zclass_gravity = str_to_float(Temp)
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_KNOCKBACK", Temp, sizeof(Temp)); zclass_knockback = str_to_float(Temp)
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_DEFENSE", Temp, sizeof(Temp)); zclass_defense = str_to_float(Temp)
	zclass_healthregen = Setting_Load_Int(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_HEALTHREGEN")
	
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_MODEL", zclass_model, sizeof(zclass_model))
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_CLAWMODEL", zclass_clawmodel, sizeof(zclass_clawmodel))
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_DEATHSOUND", zclass_deathsound, sizeof(zclass_deathsound))
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_PAINSOUND1", zclass_painsound1, sizeof(zclass_painsound1))
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_PAINSOUND2", zclass_painsound2, sizeof(zclass_painsound2))
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_STUNSOUND", zclass_stunsound, sizeof(zclass_stunsound))
	
	zclass_cost = Setting_Load_Int(SETTING_FILE, "Zombie Class", "CLASS_SPINDIVER_COST")
	
	/// Skill
	g_RollingSpeed = Setting_Load_Int(SETTING_FILE, "Spin Diver", "ROLLING_SPEED")
	Setting_Load_String(SETTING_FILE, "Spin DIver", "ROLLING_DEFENSE", Buffer, sizeof(Buffer));  g_RollingDefense = str_to_float(Buffer)
	g_RollingDecPer01Sec = Setting_Load_Int(SETTING_FILE, "Spin Diver", "ROLLING_DECREASE_PER015SEC")
	Setting_Load_String(SETTING_FILE, "Spin Diver", "ROLLING_SOUND", g_RollingSound, sizeof(g_RollingSound))
	
	
	g_PouncePower = Setting_Load_Int(SETTING_FILE, "Spin Diver", "LEAP_POWER")
	g_PounceHigh = Setting_Load_Int(SETTING_FILE, "Spin Diver", "LEAP_HIGH")
	g_PounceFar = Setting_Load_Int(SETTING_FILE, "Spin Diver", "LEAP_FAR")
	Setting_Load_String(SETTING_FILE, "Spin Diver", "LEAP_SOUND", g_PounceSound, sizeof(g_PounceSound))
	
	engfunc(EngFunc_PrecacheSound, g_RollingSound)
	engfunc(EngFunc_PrecacheSound, g_PounceSound)
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
}

public fw_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsUserAlive, id)
}

public fw_TakeDamage(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	if(!g_GameStart)
		return HAM_IGNORED
	if(zd_get_user_zombieclass(Victim) != g_zombieclass)
		return HAM_IGNORED
	if(!Get_BitVar(g_Rolling, Victim))
		return HAM_IGNORED
		
	Damage /= g_RollingDefense
	SetHamParamFloat(4, Damage)
		
	return HAM_HANDLED
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
	UnSet_BitVar(g_Rolling, id)
	UnSet_BitVar(g_Leaping, id)
	
	Deactive_RollingSkill(id)
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
		
		if(Get_BitVar(g_Rolling, id))
		{
			// Make the player crouch
			set_pev(id, pev_bInDuck, 1)
			client_cmd(id, "+duck")
		}
		
		if(Get_BitVar(g_Rolling, id) && (get_gametime() - 0.15 > CheckTime[id]))
		{
			if(zd_get_user_power(id) <= 0)
			{
				Deactive_RollingSkill(id)
				return
			}
			/*
			if(!(pev(id, pev_flags) & FL_DUCKING) || !pev(id, pev_bInDuck))
			{
				Deactive_RollingSkill(id)
				return
			}*/
			
			// Handle Other
			if(!zd_get_hudfastupdate(id)) zd_set_hudfastupdate(id, 1)
			if(zd_get_user_status(id, STATUS_SPEED) != SPEED_INC) zd_set_user_status(id, STATUS_SPEED, SPEED_INC)
			if(zd_get_user_status(id, STATUS_STRENGTH) != STRENGTH_HARDENING) zd_set_user_status(id, STATUS_STRENGTH, STRENGTH_HARDENING)
			zd_set_user_power(id, zd_get_user_power(id) - g_RollingDecPer01Sec)
		
			CheckTime[id] = get_gametime()
		}	
			
		if(Get_BitVar(g_Rolling, id) && (get_gametime() - 0.5 > CheckTime2[id]))
		{
			zd_set_fakeattack(id)
			Set_WeaponAnim(id, 10)
			
			set_pev(id, pev_framerate, 2.0)
			set_pev(id, pev_sequence, 111)
			
			// Play Sound
			emit_sound(id, CHAN_VOICE, g_RollingSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
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
			Deactive_RollingSkill(id)
		}
		
		return
	}
	
	if(equali(g_PlayerKey[id], "ww"))
	{
		Reset_Key(id)
		Active_RollingSkill(id)
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
	
	if(get_gametime() - 1.0 > CheckTime3[id])
	{
		static Time; Time = zd_get_user_power(id) / g_PouncePower
		static Hud[64], SkillName[32]; 
		
		formatex(SkillName, sizeof(SkillName), "%L", LANG_SERVER, "ZOMBIE_CLASS_SPINDIVER_SKILL")
		if(Time >= 1) formatex(Hud, sizeof(Hud), "%L", LANG_SERVER, "HUD_ZOMBIESKILL", SkillName, Time)

		set_hudmessage(200, 200, 200, HUD_ADRENALINE_X, HUD_ADRENALINE_Y - 0.02, 0, 1.0, 1.0, 0.0, 0.0)
		ShowSyncHudMsg(id, g_SkillHud, Hud)
		
		CheckTime3[id] = get_gametime()
	}	
	
	if((CurButton & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP) || ((CurButton & IN_ATTACK) && !(pev(id, pev_oldbuttons) & IN_ATTACK)))
	{
		if(Get_BitVar(g_Rolling, id)) Deactive_RollingSkill(id)
	}

	if((CurButton & IN_ATTACK2))
	{
		CurButton &= ~IN_ATTACK2
		set_uc(UCHandle, UC_Buttons, CurButton)

		if(!g_GameStart)
		{
			set_pdata_float(id, 83, 0.5, 5)
			return 	
		}
		if(Get_BitVar(g_Leaping, id))
		{
			set_pdata_float(id, 83, 0.5, 5)
			return
		}
		if(zd_get_zombie_stun(id) || zd_get_zombie_slowdown(id))
		{
			set_pdata_float(id, 83, 0.5, 5)
			return
		}
		if(zd_get_user_power(id) < g_PouncePower)
		{
			set_pdata_float(id, 83, 0.5, 5)
			return
		}
		/*
		if((pev(id, pev_flags) & FL_DUCKING) || pev(id, pev_bInDuck))
		{
			set_pdata_float(id, 83, 0.5, 5)
			return
		}*/
		if(get_pdata_float(id, 83, 5) > 0.0)
			return
			
		set_pdata_float(id, 83, 0.5, 5)
		Handle_Pounce(id)
	}
}

public Handle_Pounce(id)
{
	if(Get_BitVar(g_Rolling, id)) Deactive_RollingSkill(id)
	
	static Float:Origin1[3], Float:Origin2[3]
	pev(id, pev_origin, Origin1)

	Set_BitVar(g_Leaping, id)
	
	zd_set_user_power(id, zd_get_user_power(id) - g_PouncePower)
	zd_set_fakeattack(id)
	
	// Climb Action
	Set_WeaponAnim(id, 6)
	set_pev(id, pev_framerate, 2.0)
	set_pev(id, pev_sequence, 111)
	
	set_pdata_float(id, 83, 3.0, 5)
	
	get_position(id, float(g_PounceFar), 0.0, float(g_PounceHigh), Origin2)
	static Float:Velocity[3]; Get_SpeedVector(Origin1, Origin2, 1000.0, Velocity)
	
	set_pev(id, pev_velocity, Velocity)
	emit_sound(id, CHAN_STATIC, g_PounceSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public client_PostThink(id)
{
	if(!Get_BitVar(g_IsUserAlive, id))
		return
	if(!Get_BitVar(g_Leaping, id))
		return
	if(!zd_get_user_zombie(id))
		return
	if(zd_get_user_zombieclass(id) != g_zombieclass)
		return
			
	static Float:flFallVelocity; flFallVelocity = get_pdata_float(id, 251, 5)
        
	if(flFallVelocity && pev(id, pev_flags) & FL_ONGROUND)
	{
		//zd_set_fakeattack(id)
		
		//set_pev(id, pev_framerate, 2.0)
		//set_pev(id, pev_sequence, 113)
		Set_WeaponAnim(id, 7)

		UnSet_BitVar(g_Leaping, id)
	}
}

public Active_RollingSkill(id)
{
	if(pev(id, pev_flags) & FL_DUCKING || pev(id, pev_bInDuck))
		return
	if(!(pev(id, pev_flags) & FL_ONGROUND))
		return
		
	Set_BitVar(g_Rolling, id)
	CheckTime2[id] = get_gametime()
	
	zd_set_fakeattack(id)
	set_pev(id, pev_framerate, 2.0)
	set_pev(id, pev_sequence, 111)
	
	Set_WeaponAnim(id, 9)
	set_pev(id, pev_maxspeed, float(g_RollingSpeed))
	// GM_Set_PlayerSpeed(id, float(g_RollingSpeed), 1)

	if(zd_get_user_nvg(id, 1, 0))
	{
		// ScreenFade
		message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(170) // g
		write_byte(0) // b
		write_byte(35) // alpha
		message_end()
	}
	
	client_cmd(id, "cl_forwardspeed %d", float(g_RollingSpeed))
	client_cmd(id, "+duck")
}

public Deactive_RollingSkill(id)
{
	set_pev(id, pev_bInDuck, 0)
	client_cmd(id, "-duck")
	client_cmd(id, "-duck") // prevent bug
	
	client_cmd(id, "cl_forwardspeed 400")
	
	if(!is_user_alive(id))
		return
	if(!Get_BitVar(g_Rolling, id))
		return
	
	UnSet_BitVar(g_Rolling, id)
	
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
	zd_set_hudfastupdate(id, 0)
	zd_set_user_status(id, STATUS_SPEED, SPEED_NONE)
	zd_set_user_status(id, STATUS_STRENGTH, STRENGTH_NONE)

	// Reset Claw
	Set_WeaponAnim(id, 11)
	set_pev(id, pev_maxspeed, zclass_speed)
	// GM_Set_PlayerSpeed(id, zclass_speed, 1)
}

public Reset_Key(id)
{
	g_PlayerKey[id][0] = 0
	g_PlayerKey[id][1] = 0
}

public Recheck_Key(id)
{
	id -= TASK_CHECKTIME
	
	if(!is_user_connected(id))
		return
		
	Reset_Key(id)
}

public zd_user_nvg(id, On, Zombie)
{
	if(!Zombie) return
	if(!Get_BitVar(g_Rolling, id))
		return
	
	if(!On)
	{
		// ScreenFade
		message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(127) // g
		write_byte(0) // b
		write_byte(35) // alpha
		message_end()
	}
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
		static DataA[80]; formatex(DataA, sizeof(DataA), "[ZD] Can't load: %s", path)
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

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock Get_RandomArray(Array:ArrayName)
{
	return random_num(0, ArraySize(ArrayName) - 1)
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
