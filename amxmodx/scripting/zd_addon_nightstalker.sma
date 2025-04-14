#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <ZombieDarkness>

#define PLUGIN "[ZD] Addon: Night Stalker"
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
new g_ClassSpeed, g_ClawModel[64]
new Float:g_InvisibleTime, g_InvisibleClawModel[64]
new g_BerserkSpeed, Float:g_BerserkDefense, g_BerserkDecPer015S, Array:g_BerserkSound
new g_DashPower, g_DashJump, g_DashDashing, g_DashSound[64]

new g_GameStart, g_IsUserBot, g_BotHamRegister, g_IsUserAlive
new Float:CheckTime[33], Float:CheckTime2[33], Float:CheckTime3[33], g_SkillHud

new g_Sprinting, g_PlayerKey[33][2], g_MsgScreenFade, g_InvisiblePercent[33]
new g_Dashing

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
	g_BerserkSound = ArrayCreate(64, 1)
	
	Load_ClassConfig()
}

public Load_ClassConfig()
{
	static Buffer[64]
	
	Setting_Load_String(SETTING_FILE, "Night Stalker", "INVISIBLE_TIME", Buffer, sizeof(Buffer)); g_InvisibleTime = str_to_float(Buffer)
	g_ClassSpeed = Setting_Load_Int(SETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_SPEED")
	Setting_Load_String(SETTING_FILE, "Zombie Class", "CLASS_NIGHTSTALKER_CLAWMODEL", g_ClawModel, sizeof(g_ClawModel))
	Setting_Load_String(SETTING_FILE, "Night Stalker", "INVISIBLE_CLAWMODEL", g_InvisibleClawModel, sizeof(g_InvisibleClawModel))
	engfunc(EngFunc_PrecacheModel, g_InvisibleClawModel)

	g_BerserkSpeed = Setting_Load_Int(SETTING_FILE, "Night Stalker", "BERSERK_SPEED")
	Setting_Load_String(SETTING_FILE, "Night Stalker", "BERSERK_DEFENSE", Buffer, sizeof(Buffer)); g_BerserkDefense = str_to_float(Buffer)
	g_BerserkDecPer015S = Setting_Load_Int(SETTING_FILE, "Night Stalker", "BERSERK_DECREASE_PER015SEC")
	Setting_Load_StringArray(SETTING_FILE, "Night Stalker", "BERSERK_SOUND", g_BerserkSound)
	for(new i = 0; i < ArraySize(g_BerserkSound); i++)
	{
		ArrayGetString(g_BerserkSound, i, Buffer, sizeof(Buffer))
		engfunc(EngFunc_PrecacheSound, Buffer)
	}
	
	g_DashPower = Setting_Load_Int(SETTING_FILE, "Night Stalker", "DASH_POWER")
	g_DashJump = Setting_Load_Int(SETTING_FILE, "Night Stalker", "DASH_JUMP")
	g_DashDashing = Setting_Load_Int(SETTING_FILE, "Night Stalker", "DASH_DASHING")
	Setting_Load_String(SETTING_FILE, "Night Stalker", "DASH_SOUND", g_DashSound, sizeof(g_DashSound))
	engfunc(EngFunc_PrecacheSound, g_DashSound)
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
	if(!zd_get_user_nightstalker(Victim))
		return HAM_IGNORED
	if(!Get_BitVar(g_Sprinting, Victim))
		return HAM_IGNORED
		
	Damage /= g_BerserkDefense
	SetHamParamFloat(4, Damage)
		
	return HAM_HANDLED
}

public Event_Death()
{
	static Victim; Victim = read_data(2); UnSet_BitVar(g_IsUserAlive, Victim)
}

public zd_zombie_stun(id) Reset_Skill(id)
public zd_zombie_slowdown(id) Reset_Skill(id)

public Reset_Skill(id)
{
	UnSet_BitVar(g_Sprinting, id)
	UnSet_BitVar(g_Dashing, id)
	g_InvisiblePercent[id] = 0
	
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
		if(!zd_get_user_nightstalker(id))
			return
		if(zd_get_zombie_stun(id) || zd_get_zombie_slowdown(id))
			return
		
		if(Get_BitVar(g_Sprinting, id) && (get_gametime() - 0.15 > CheckTime[id]))
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
			
			static Float:RenderAmt; pev(id, pev_renderamt, RenderAmt)
			if(RenderAmt > 0) 
			{
				RenderAmt -= ((255.0 / g_InvisibleTime) * 0.15)
				if(RenderAmt < 0.0) 
				{
					RenderAmt = 0.0
					set_pev(id, pev_viewmodel2, g_InvisibleClawModel)
				}
				
				g_InvisiblePercent[id] = floatround(((255.0 - RenderAmt) / 255.0) * 100.0)
				set_pev(id, pev_renderamt, RenderAmt)
			}
			
			// Handle Other
			if(!zd_get_hudfastupdate(id)) zd_set_hudfastupdate(id, 1)
			if(zd_get_user_status(id, STATUS_SPEED) != SPEED_INC) zd_set_user_status(id, STATUS_SPEED, SPEED_INC)
			if(zd_get_user_status(id, STATUS_STRENGTH) != STRENGTH_HARDENING) zd_set_user_status(id, STATUS_STRENGTH, STRENGTH_HARDENING)
			zd_set_user_power(id, zd_get_user_power(id) - g_BerserkDecPer015S)
			
			CheckTime[id] = get_gametime()
		}	
			
		if(Get_BitVar(g_Sprinting, id) && (get_gametime() - 0.5 > CheckTime2[id]))
		{
			zd_set_fakeattack(id)
			Set_WeaponAnim(id, 10)
			
			set_pev(id, pev_framerate, 2.0)
			set_pev(id, pev_sequence, 110)
			
			// Play Sound
			static Sound[64]; ArrayGetString(g_BerserkSound, Get_RandomArray(g_BerserkSound), Sound, sizeof(Sound))
			emit_sound(id, CHAN_VOICE, Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
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
	if(!zd_get_user_nightstalker(id))
		return

	static CurButton; CurButton = get_uc(UCHandle, UC_Buttons)
	
	if(get_gametime() - 1.0 > CheckTime3[id])
	{
		static Time; Time = zd_get_user_power(id) / g_DashPower
		static Hud[64], SkillName[32]; 
		
		formatex(SkillName, sizeof(SkillName), "%L", LANG_SERVER, "ZOMBIE_CLASS_NIGHTSTALKER_SKILL")
		formatex(Hud, sizeof(Hud), "%L", LANG_SERVER, "HUD_ZOMBIESKILL_INV", g_InvisiblePercent[id])
		
		if(Time >= 1) formatex(Hud, sizeof(Hud), "%s^n%L", Hud, LANG_SERVER, "HUD_ZOMBIESKILL", SkillName, Time)

		set_hudmessage(200, 200, 200, HUD_ADRENALINE_X, HUD_ADRENALINE_Y - 0.04, 0, 1.0, 1.0, 0.0, 0.0)
		ShowSyncHudMsg(id, g_SkillHud, Hud)
		
		CheckTime3[id] = get_gametime()
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
		if(Get_BitVar(g_Sprinting, id))
		{
			set_pdata_float(id, 83, 0.5, 5)
			return
		}
		if(zd_get_zombie_stun(id) || zd_get_zombie_slowdown(id))
		{
			set_pdata_float(id, 83, 0.5, 5)
			return
		}
		if(zd_get_user_power(id) < g_DashPower)
		{
			set_pdata_float(id, 83, 0.5, 5)
			return
		}
		if((pev(id, pev_flags) & FL_DUCKING) || pev(id, pev_bInDuck))
		{
			set_pdata_float(id, 83, 0.5, 5)
			return
		}
		if(get_pdata_float(id, 83, 5) > 0.0)
			return
			
		set_pdata_float(id, 83, 0.5, 5)
		Handle_Dashing(id)
	}
}

public Handle_Dashing(id)
{
	if((pev(id, pev_flags) & FL_ONGROUND)) // On Ground
	{
		static Float:Origin1[3], Float:Origin2[3]
		pev(id, pev_origin, Origin1)
	
		Set_BitVar(g_Dashing, id)
		
		zd_set_user_power(id, zd_get_user_power(id) - g_DashPower)
		zd_set_fakeattack(id)
		
		// Climb Action
		Set_WeaponAnim(id, 6)
		set_pev(id, pev_framerate, 0.5)
		set_pev(id, pev_sequence, 112)
		
		set_pdata_float(id, 83, 0.5, 5)
		
		get_position(id, 0.0, 0.0, 200.0, Origin2)
		static Float:Velocity[3]; Get_SpeedVector(Origin1, Origin2, float(g_DashJump), Velocity)
		
		set_pev(id, pev_velocity, Velocity)
		emit_sound(id, CHAN_STATIC, g_DashSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	} else { // In Air
		static Float:Origin1[3], Float:Origin2[3]
		pev(id, pev_origin, Origin1)
	
		Set_BitVar(g_Dashing, id)
		
		zd_set_user_power(id, zd_get_user_power(id) - g_DashPower)
		zd_set_fakeattack(id)
		
		// Climb Action
		Set_WeaponAnim(id, 6)
		set_pev(id, pev_framerate, 0.5)
		set_pev(id, pev_sequence, 112)
		
		set_pdata_float(id, 83, 0.5, 5)
		
		get_position(id, 250.0, 0.0, 60.0, Origin2)
		static Float:Velocity[3]; Get_SpeedVector(Origin1, Origin2, float(g_DashDashing), Velocity)
		
		set_pev(id, pev_velocity, Velocity)
		emit_sound(id, CHAN_STATIC, g_DashSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public client_PostThink(id)
{
	if(!Get_BitVar(g_IsUserAlive, id))
		return
	if(!Get_BitVar(g_Dashing, id))
		return
	if(!zd_get_user_nightstalker(id))
		return
		
	static Float:flFallVelocity; flFallVelocity = get_pdata_float(id, 251, 5)
        
	if(flFallVelocity && pev(id, pev_flags) & FL_ONGROUND)
	{
		zd_set_fakeattack(id)
		
		set_pev(id, pev_framerate, 2.0)
		set_pev(id, pev_sequence, 113)
		Set_WeaponAnim(id, 7)

		UnSet_BitVar(g_Dashing, id)
	}
}

public Active_SprintSkill(id)
{
	Set_BitVar(g_Sprinting, id)
	CheckTime2[id] = get_gametime()
	
	zd_set_fakeattack(id)
	set_pev(id, pev_framerate, 2.0)
	set_pev(id, pev_sequence, 110)
	
	Set_WeaponAnim(id, 9)
	set_pev(id, pev_maxspeed, float(g_BerserkSpeed))
	// GM_Set_PlayerSpeed(id, float(g_BerserkSpeed), 1)

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
	
	set_pev(id, pev_rendermode, kRenderTransAlpha)
	set_pev(id, pev_renderfx, kRenderFxNone)
	set_pev(id, pev_renderamt, 255.0)	
}

public Deactive_SprintSkill(id)
{
	if(!Get_BitVar(g_Sprinting, id))
		return
	
	UnSet_BitVar(g_Sprinting, id)
	g_InvisiblePercent[id] = 0
	
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
	set_pev(id, pev_rendermode, kRenderNormal)
	Set_WeaponAnim(id, 11)
	set_pev(id, pev_maxspeed, float(g_ClassSpeed))
	// GM_Set_PlayerSpeed(id, float(g_ClassSpeed), 1)
	
	static ClawModel[64]; formatex(ClawModel, sizeof(ClawModel), "models/%s/%s", GAME_FOLDER, g_ClawModel)
	set_pev(id, pev_viewmodel2, ClawModel)
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
	if(!Get_BitVar(g_Sprinting, id))
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
