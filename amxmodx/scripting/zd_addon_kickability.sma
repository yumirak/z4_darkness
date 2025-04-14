#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <ZombieDarkness>
#include <reapi>

#define PLUGIN "[ZD] Addon: Kick Ability"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define GAME_FOLDER "ZombieDarkness"
#define SETTING_FILE "ZombieDarkness.ini"

// Macros
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

#define TASK_KICK 201456
new Float:KickTime, KickPower, Float:KickRange, Kick_VModel[64], Kick_PModel[64], g_OldModel[33][64]
new g_CanKick, g_Kicking, g_KickAnimEnt[33], g_KickAvtEnt[33], KickSound[64], KickHitSound[64], SafeMode
new g_MaxPlayers, g_GameStart
new g_IsUserAlive, g_BotHamRegister

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("DeathMsg", "Event_Death", "a")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)	
	register_forward(FM_CmdStart, "fw_CmdStart")
	if(SafeMode) register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)

	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	static Buffer[8]
	
	Setting_Load_String(SETTING_FILE, "Human Kick", "KICK_TIME", Buffer, sizeof(Buffer)); KickTime = str_to_float(Buffer)
	SafeMode = Setting_Load_Int(SETTING_FILE, "Human Kick", "KICK_PMODEL_ACTIVE")
	KickPower = Setting_Load_Int(SETTING_FILE, "Human Kick", "KICK_POWER")
	Setting_Load_String(SETTING_FILE, "Human Kick", "KICK_RANGE", Buffer, sizeof(Buffer)); KickRange = str_to_float(Buffer)
	Setting_Load_String(SETTING_FILE, "Human Kick", "KICK_VMODEL", Kick_VModel, sizeof(Kick_VModel)); engfunc(EngFunc_PrecacheModel, Kick_VModel)
	Setting_Load_String(SETTING_FILE, "Human Kick", "KICK_PMODEL", Kick_PModel, sizeof(Kick_PModel)); engfunc(EngFunc_PrecacheModel, Kick_PModel)

	Setting_Load_String(SETTING_FILE, "Human Kick", "KICK_SOUND", KickSound, sizeof(KickSound)); engfunc(EngFunc_PrecacheSound, KickSound)
	Setting_Load_String(SETTING_FILE, "Human Kick", "KICK_HITSOUND", KickHitSound, sizeof(KickHitSound)); engfunc(EngFunc_PrecacheSound, KickHitSound)
}

public zd_round_start() g_GameStart = 1
public zd_round_end() g_GameStart = 0

public zd_user_spawned(id, Zombie)
{
	if(!Zombie)
	{
		Set_BitVar(g_CanKick, id)
		UnSet_BitVar(g_Kicking, id)
	}
}

public zd_user_infected(id)
{
	UnSet_BitVar(g_CanKick, id)
	Set_BitVar(g_Kicking, id)
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

public fw_AddToFullPack_Post(es_handle, e , ent, host, hostflags, player, pSet)
{
	if(!(1 <= host <= 32) && !pev_valid(ent))
		return FMRES_IGNORED
	if(g_KickAvtEnt[host] != ent)
		return FMRES_IGNORED
			
	set_es(es_handle, ES_Effects, get_es(es_handle, ES_Effects) | EF_NODRAW)
	return FMRES_IGNORED
}

public fw_CmdStart(id, UCHandle, Seed)
{
	if(!Get_BitVar(g_IsUserAlive, id))
		return
		
	static CurButton, OldButton;
	CurButton = get_uc(UCHandle, UC_Buttons)
	OldButton = pev(id, pev_oldbuttons)
	
	if((CurButton & IN_USE) && !(OldButton & IN_USE))
	{
		if(!Get_BitVar(g_CanKick, id) || Get_BitVar(g_Kicking, id))
			return
		if(!g_GameStart)
			return
		if((pev(id, pev_flags) & FL_DUCKING) || pev(id, pev_bInDuck))
			return
			
		UnSet_BitVar(g_CanKick, id)
		Set_BitVar(g_Kicking, id)
			
		// Save Weapon
		pev(id, pev_viewmodel2, g_OldModel[id], 63)
		
		// Stop Player
		set_pev(id, pev_maxspeed, 1)
		Set_Player_NextAttack(id, KickTime + get_pdata_float(id, 83, 5))
		
		// Kick Action: View Model
		set_pev(id, pev_viewmodel2, Kick_VModel)
		Set_WeaponAnim(id, 1)
		
		// Kick Action: Player Model
		Handle_PlayerAnim(id)

		// Check Radius
		Check_KickKnockback(id)
		
		// Stop Time ?
		set_task(KickTime, "Reset_Kick", id+TASK_KICK)
	}
}

public Check_KickKnockback(id)
{
	static Float:Origin[3], Float:MyOrigin[3], Float:Speed[3]
	new Enemy
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i)) continue
		if(id == i) continue
		pev(i, pev_origin, Origin)
		if(!is_in_viewcone(id, Origin, 1))
			continue
		if(entity_range(id, i) > KickRange)
			continue
		Enemy = 1
		if(!zd_get_user_zombie(i)) continue
			
		Origin[2] += 36.0
		Get_SpeedVector(MyOrigin, Origin, float(KickPower), Speed)
		set_pev(i, pev_velocity, Speed)
	}
	
	if(Enemy) emit_sound(id, CHAN_ITEM, KickHitSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public Reset_Kick(id)
{
	id -= TASK_KICK
	if(!Get_BitVar(g_IsUserAlive, id))
		return
		
	Set_BitVar(g_CanKick, id)
	UnSet_BitVar(g_Kicking, id)
		
	Set_Entity_Invisible(id, 0)
		
	if(SafeMode)
	{
		Set_Entity_Invisible(g_KickAnimEnt[id], 1)
		Set_Entity_Invisible(g_KickAvtEnt[id], 1)
		//UnHandle_PlayerAnim(id)
	}
	
	if(zd_get_user_zombie(id))
		return
		
	set_pev(id, pev_viewmodel2, g_OldModel[id])
	rg_reset_maxspeed(id)
}

public Handle_PlayerAnim(id)
{
	if(!SafeMode) return
	
	Create_AvtEnt(id)
	Create_AnimEnt(id)
	
	Set_Entity_Invisible(id, 1)
	
	// Set Player Coords
	static Float:Origin[3], Float:Angles[3], Float:Velocity[3]
		
	pev(id, pev_origin, Origin)
	pev(id, pev_angles, Angles)
	pev(id, pev_velocity, Velocity)
	
	// Set Info
	set_pev(g_KickAnimEnt[id], pev_origin, Origin)
	Angles[0] = 0.0; Angles[2] = 0.0; set_pev(g_KickAnimEnt[id], pev_angles, Angles)
	set_pev(g_KickAnimEnt[id], pev_velocity, Velocity)
		
	// Active Action
	set_pev(g_KickAvtEnt[id], pev_aiment, g_KickAnimEnt[id])

	Set_Entity_Invisible(g_KickAvtEnt[id], 0)
	Set_Entity_Anim(g_KickAnimEnt[id], 0, 1)
	
	// Play Sound
	emit_sound(id, CHAN_BODY, KickSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public UnHandle_PlayerAnim(id)
{
	
	
	if(!SafeMode) return
	
	if(pev_valid(g_KickAvtEnt[id]) == 2) 
	{
		set_pev(g_KickAvtEnt[id], pev_flags, FL_KILLME)
		set_pev(g_KickAvtEnt[id], pev_nextthink, get_gametime() + 0.1)
	} 
	if(pev_valid(g_KickAnimEnt[id]) == 2) 
	{
		set_pev(g_KickAnimEnt[id], pev_flags, FL_KILLME)
		set_pev(g_KickAnimEnt[id], pev_nextthink, get_gametime() + 0.1)
	}
}

public Create_AvtEnt(id)
{
	if(pev_valid(g_KickAvtEnt[id]))
		return
	
	g_KickAvtEnt[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))

	if(!pev_valid(g_KickAvtEnt[id])) 
		return	
	
	static ent; ent = g_KickAvtEnt[id]
	set_pev(ent, pev_classname, "kickavatar")
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(ent, pev_solid, SOLID_NOT)

	// Set Model
	static PlayerModel[64]
	fm_cs_get_user_model(id, PlayerModel, sizeof(PlayerModel))
	
	format(PlayerModel, sizeof(PlayerModel), "models/player/%s/%s.mdl", PlayerModel, PlayerModel)
	engfunc(EngFunc_SetModel, g_KickAvtEnt[id], PlayerModel)	
	
	// Set Avatar
	set_pev(ent, pev_body, pev(id, pev_body))
	set_pev(ent, pev_skin, pev(id, pev_skin))
	
	set_pev(ent, pev_renderamt, pev(id, pev_renderamt))
	static Float:Color[3]; pev(id, pev_rendercolor, Color)
	set_pev(ent, pev_rendercolor, Color)
	set_pev(ent, pev_renderfx, pev(id, pev_renderfx))
	set_pev(ent, pev_rendermode, pev(id, pev_rendermode))
	
	Set_Entity_Invisible(ent, 0)
}

public Create_AnimEnt(id)
{
	if(pev_valid(g_KickAnimEnt[id]))
		return
			
	g_KickAnimEnt[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(g_KickAnimEnt[id])) 
		return
		
	static ent; ent = g_KickAnimEnt[id]
	set_pev(ent, pev_classname, "AnimEnt")
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)
	
	engfunc(EngFunc_SetModel, ent, Kick_PModel)
	engfunc(EngFunc_SetSize, ent, {-16.0, -16.0, -36.0}, {16.0, 16.0, 36.0})
	set_pev(ent, pev_solid, SOLID_NOT)
	
	engfunc(EngFunc_DropToFloor, ent)
	Set_Entity_Invisible(ent, 0)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
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
	if(pev_valid(id) != 2)
		return
		
	set_pdata_float(id, 83, Time, 5)
}

stock fm_cs_get_user_model(id, Model[], Len)
{
	if(!is_user_connected(id))
		return
		
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", Model, Len)
}

stock Set_Entity_Invisible(ent, Invisible = 1)
{
	if(!pev_valid(ent))
		return
		
	if(!Invisible)
	{
		set_pev(ent, pev_renderamt, 16.0)
		set_pev(ent, pev_rendercolor, {0.0, 0.0, 0.0})
		set_pev(ent, pev_renderfx, kRenderFxNone)
		set_pev(ent, pev_rendermode, kRenderNormal)
	} else {
		set_pev(ent, pev_renderamt, 0.0)
		set_pev(ent, pev_rendercolor, {0.0, 0.0, 0.0})
		set_pev(ent, pev_renderfx, kRenderFxNone)
		set_pev(ent, pev_rendermode, kRenderTransAlpha)
	}
}

stock Set_Entity_Anim(ent, Anim, ResetFrame)
{
	if(!pev_valid(ent))
		return
		
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, 1.5)
	set_pev(ent, pev_sequence, Anim)
	if(ResetFrame) set_pev(ent, pev_frame, 0)
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
	format(path, charsmax(path), "%s/%s/%s", path, GAME_FOLDER, filename)
	
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
	format(path, charsmax(path), "%s/%s/%s", path, GAME_FOLDER, filename)
	
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

stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != 2)
		return -1;
	
	return get_pdata_cbase(ent, 41, 4);
}

stock Get_SpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= (num)
	new_velocity[1] *= (num)
	new_velocity[2] *= (num)
}  
