#include <amxmodx>
#include <cstrike>
#include <ZombieDarkness>

#define PLUGIN "[ZD] Addon: Top Team Stat"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define GAME_NAME "Zombie Darkness"
#define TOP_SOUND "ZombieDarkness/StatResult.wav"

#define MIN_DAMAGE 500
#define TASK_STAT 40231

enum
{
	TOP_ID = 0,
	TOP_DAMAGE,
	TOP_SCORE
}

new Top_1st[3], Top_2nd[3], Top_3rd[3], MyTop[33]
new g_MaxPlayers, g_MsgSayText, g_MsgHideWeapon, g_SyncHud

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_SyncHud = CreateHudSyncObj(3)
	
	g_MaxPlayers = get_maxplayers()
	g_MsgHideWeapon = get_user_msgid("HideWeapon")
	g_MsgSayText = get_user_msgid("SayText")
}

public plugin_precache()
{
	precache_sound(TOP_SOUND)
}

public zd_round_new() Reset_Stat()

public Reset_Stat()
{
	for(new i = 0; i < g_MaxPlayers; i++)
		MyTop[i] = 0
		
	remove_task(TASK_STAT)
	
	Top_1st[TOP_ID] = -1; Top_1st[TOP_DAMAGE] = 0; Top_1st[TOP_SCORE] = 0
	Top_2nd[TOP_ID] = -1; Top_2nd[TOP_DAMAGE] = 0; Top_2nd[TOP_SCORE] = 0
	Top_3rd[TOP_ID] = -1; Top_3rd[TOP_DAMAGE] = 0; Top_3rd[TOP_SCORE] = 0
}

public Clear_OldTop(id)
{
	if(id == Top_1st[TOP_ID]){ Top_1st[TOP_ID] = -1; Top_1st[TOP_DAMAGE] = 0; Top_1st[TOP_SCORE] = 0;}
	if(id == Top_2nd[TOP_ID]){ Top_2nd[TOP_ID] = -1; Top_2nd[TOP_DAMAGE] = 0; Top_2nd[TOP_SCORE] = 0;}
	if(id == Top_3rd[TOP_ID]){ Top_3rd[TOP_ID] = -1; Top_3rd[TOP_DAMAGE] = 0; Top_3rd[TOP_SCORE] = 0;}
}

public zd_round_damage(id, Damage)
{
	if(Damage > Top_1st[TOP_DAMAGE])
	{
		if(Top_1st[TOP_ID] == id)
			return
		if(Damage <= Top_1st[TOP_DAMAGE] + MIN_DAMAGE)
			return
	
		Clear_OldTop(id)
		MyTop[id] = 1
		
		Top_1st[TOP_ID] = id
		Top_1st[TOP_DAMAGE] = Damage
		Top_1st[TOP_SCORE] = zd_get_round_score(id)
		
		client_printc(id, "!g[%s]!n %L", GAME_NAME, LANG_SERVER, "STAT_REACH_TOP1")
		
		static Name[64]; get_user_name(id, Name, sizeof(Name))
		client_printc(0, "!g[%s]!n %L", GAME_NAME, LANG_SERVER, "STAT_REACH_TOP1ALL", Name, Damage)
	
		
	} else if(Damage > Top_2nd[TOP_DAMAGE]) {
		if(Top_2nd[TOP_ID] == id)
			return
			
		Clear_OldTop(id)
		MyTop[id] = 2
		
		Top_2nd[TOP_ID] = id
		Top_2nd[TOP_DAMAGE] = Damage
		Top_2nd[TOP_SCORE] = zd_get_round_score(id)
		
		client_printc(id, "!g[%s]!n %L", GAME_NAME, LANG_SERVER, "STAT_REACH_TOP2")
	} else if(Damage > Top_3rd[TOP_DAMAGE]) {
		if(Top_3rd[TOP_ID] == id)
			return
			
		Clear_OldTop(id)
		MyTop[id] = 3
		
		Top_3rd[TOP_ID] = id
		Top_3rd[TOP_DAMAGE] = Damage
		Top_3rd[TOP_SCORE] = zd_get_round_score(id)
		
		client_printc(id, "!g[%s]!n %L", GAME_NAME, LANG_SERVER, "STAT_REACH_TOP3")
	}
}

public zd_user_spawned(id, Zombie)
{
	set_task(0.5, "Reset_Crosshair", id)
}

public Reset_Crosshair(id)
{
	if(!is_user_connected(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, g_MsgHideWeapon, _, id)
	write_byte(0)
	message_end()
}

public zd_round_end(CsTeams:WinTeam)
{
	if(WinTeam == CS_TEAM_CT || WinTeam == CS_TEAM_T) set_task(0.75, "ShowStat", TASK_STAT)
}

public ShowStat()
{
	PlaySound(0, TOP_SOUND)
	
	set_hudmessage(255, 255, 255, -1.0, -1.0, 2, 5.0, 5.0, 0.05)
	
	static Id1, Id2, Id3, Highest; Id1 = Id2 = Id3 = Highest = 0
	static Name1[32], Name2[32], Name3[32]
	
	// Loop for Top 1
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(zd_get_round_damage(i) < Highest)
			continue
			
		Id1 = i
		Highest = zd_get_round_damage(i)
	}
	
	// Loop for Top 2
	Highest = 0
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(i == Id1)
			continue
		if(zd_get_round_damage(i) < Highest)
			continue
			
		Id2 = i
		Top_2nd[TOP_DAMAGE] = Highest = zd_get_round_damage(i)
	}
	
	// Loop for Top 3
	Highest = 0
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		
		// Hide Weapon
		message_begin(MSG_ONE_UNRELIABLE, g_MsgHideWeapon, _, i)
		write_byte(1<<6)
		message_end()
		
		if(i == Id1 || i == Id2)
			continue	
		if(zd_get_round_damage(i) < Highest)
			continue
			
		Id3 = i
		Top_3rd[TOP_DAMAGE] = Highest = zd_get_round_damage(i)
	}
	
	if(is_user_connected(Id1)) 
	{
		get_user_name(Id1, Name1, sizeof(Name1))
		formatex(Name1, sizeof(Name1), "%s (%i)", Name1, zd_get_round_damage(Id1))
	} else formatex(Name1, sizeof(Name1), "(NONE)")
	if(is_user_connected(Id2)) 
	{
		get_user_name(Id2, Name2, sizeof(Name2))
		formatex(Name2, sizeof(Name2), "%s (%i)", Name2, zd_get_round_damage(Id2))
	} else formatex(Name2, sizeof(Name2), "(NONE)")
	if(is_user_connected(Id3)) 
	{
		get_user_name(Id3, Name3, sizeof(Name3))
		formatex(Name3, sizeof(Name3), "%s (%i)", Name3, zd_get_round_damage(Id3))
	} else formatex(Name3, sizeof(Name3), "(NONE)")
	
	ShowSyncHudMsg(0, g_SyncHud, "%L", LANG_SERVER, "STAT_ROUNDEND", Name1, Name2, Name3)
	
	//STAT_ROUNDEND
}

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
			if(!is_user_connected(i))
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

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}
