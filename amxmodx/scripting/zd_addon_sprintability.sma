#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <ZombieDarkness>
#include <hamsandwich>
#include <reapi>

#define PLUGIN "[ZD] Addon: Sprint Ability"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon" // CmdStart code by PomanoB

#define SETTING_FILE "ZombieDarkness.ini"

#define TIME_INTERVAL 0.15
#define TASK_CHECKTIME 3125365

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_PlayerKey[33][2], g_DoingSkill, Float:CheckTime[33], Float:CheckTime2[33]
new SprintSpeed, SprintPower015S, SprintHeartSound[64]
new g_MsgScreenFade, g_GameStart
new g_IsUserAlive, g_BotHamRegister

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("DeathMsg", "Event_Death", "a")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)		
	
	g_MsgScreenFade = get_user_msgid("ScreenFade")
}

public plugin_precache()
{
	SprintSpeed = Setting_Load_Int(SETTING_FILE, "Human Sprint", "SPRINT_SPEED")
	SprintPower015S = Setting_Load_Int(SETTING_FILE, "Human Sprint", "SPRINT_DECREASE_PER015SEC")
	Setting_Load_String(SETTING_FILE, "Human Sprint", "SPRINT_HEARTSOUND", SprintHeartSound, sizeof(SprintHeartSound)); engfunc(EngFunc_PrecacheSound, SprintHeartSound)
}

public zd_game_start() g_GameStart = 1
public zd_round_end() g_GameStart = 0

public zd_user_spawned(id, Zombie)
{
	if(!Zombie)
	{
		UnSet_BitVar(g_DoingSkill, id)
		Reset_Key(id)
	}
}

public zd_user_infected(id)
{
	UnSet_BitVar(g_DoingSkill, id)
	Reset_Key(id)
}

public client_disconnect(id) UnSet_BitVar(g_IsUserAlive, id)
public client_putinserver(id)
{
	if(!g_BotHamRegister && is_user_bot(id))
	{
		g_BotHamRegister = 1
		set_task(0.1, "Bot_RegisterHam", id)
	}

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

public Event_Death()
{
	static Victim; Victim = read_data(2); UnSet_BitVar(g_IsUserAlive, Victim)
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
		if(zd_get_user_zombie(id) || zd_get_user_nightstalker(id))
			return
		if(Get_BitVar(g_DoingSkill, id) && (get_gametime() - 0.15 > CheckTime[id]))
		{
			if(zd_get_user_power(id) <= 0)
			{
				Deactive_Skill(id)
				return
			}
		
			if(!zd_get_hudfastupdate(id)) zd_set_hudfastupdate(id, 1)
			if(zd_get_user_status(id, STATUS_SPEED) != SPEED_INC) zd_set_user_status(id, STATUS_SPEED, SPEED_INC)
			zd_set_user_power(id, zd_get_user_power(id) - SprintPower015S)
			
			CheckTime[id] = get_gametime()
		}	
			
		if(Get_BitVar(g_DoingSkill, id) && (get_gametime() - 1.0 > CheckTime2[id]))
		{
			emit_sound(id, CHAN_VOICE, SprintHeartSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
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
			Deactive_Skill(id)
		}
		
		return
	}
	
	if(equali(g_PlayerKey[id], "ww"))
	{
		Reset_Key(id)
		Active_Skill(id)
	}
	
	return
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

public Active_Skill(id)
{
	Set_BitVar(g_DoingSkill, id)
	
	// ScreenFade
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	write_byte(255) // r
	write_byte(255) // g
	write_byte(255) // b
	write_byte(25) // alpha
	message_end()	
	
	// Set Speed
	// GM_Set_PlayerSpeed(id, float(SprintSpeed), 1)
	set_pev(id, pev_maxspeed, float(SprintSpeed))
}

public Deactive_Skill(id)
{
	if(!Get_BitVar(g_DoingSkill, id))
		return
	
	UnSet_BitVar(g_DoingSkill, id)
	
	// Reset
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0000) // fade type
	write_byte(0) // r
	write_byte(0) // g
	write_byte(0) // b
	write_byte(0) // alpha
	message_end()
	
	// Speed
	rg_reset_maxspeed(id)
	
	zd_set_hudfastupdate(id, 0)
	zd_set_user_status(id, STATUS_SPEED, SPEED_NONE)
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
	new path[64]
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
	new path[64]
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
	new path[64]
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
