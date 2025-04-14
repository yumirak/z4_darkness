#include <amxmodx>
#include <fakemeta>
#include <ZombieDarkness>

#define PLUGIN "[ZD] Addon: Effect Killer"
#define VERSION "2013"
#define AUTHOR "Dias"

// Kill & Time Config
#define MAX_KILL 8
#define RESET_TIME 3.0
#define KILL_CHECK_DELAY 0.2

#define KILL_HUD_X -1.0
#define KILL_HUD_Y 0.20
#define SYNCHUD_NUMBER random_num(100, 1000)

#define TASK_CHECK_KILL 1962+1992
#define TASK_RESET_TIME 1962+1982

// Sound Config
#define MAX_HEADSHOT_SOUND 1
new HeadShot_Sound[MAX_HEADSHOT_SOUND][] = 
{
	"vox/effect_killer2/headshot.wav"
}

#define MAX_MELEE_SOUND 1
new Melee_Sound[MAX_MELEE_SOUND][] =
{
	"vox/effect_killer2/melee/humililation.wav"
}

#define MAX_GRENADE_SOUND 2
new Grenade_Sound[MAX_GRENADE_SOUND][] =
{
	"vox/effect_killer2/grenade/gotit.wav",
	"vox/effect_killer2/grenade/excellent.wav"
}

#define MAX_MELEEKILLED_SOUND 1
new MeleeKilled_Sound[MAX_MELEEKILLED_SOUND][] =
{
	"vox/effect_killer2/ohno.wav"
}

#define MAX_2KILL_SOUND 1
new Kill2_Sound[MAX_2KILL_SOUND][] = 
{
	"vox/effect_killer2/kill/doublekill.wav"
}

#define MAX_3KILL_SOUND 1
new Kill3_Sound[MAX_3KILL_SOUND][] = 
{
	"vox/effect_killer2/kill/triplekill.wav"
}

#define MAX_4KILL_SOUND 1
new Kill4_Sound[MAX_4KILL_SOUND][] = 
{
	"vox/effect_killer2/kill/multikill.wav"
}

#define MAX_5KILL_SOUND 2
new Kill5_Sound[MAX_5KILL_SOUND][] = 
{
	"vox/effect_killer2/kill/cantbelive.wav",
	"vox/effect_killer2/kill/monsterkill.wav"
}

#define MAX_6KILL_SOUND 2
new Kill6_Sound[MAX_6KILL_SOUND][] = 
{
	"vox/effect_killer2/kill/crazy.wav",
	"vox/effect_killer2/kill/megakill.wav"
}

#define MAX_7KILL_SOUND 2
new Kill7_Sound[MAX_7KILL_SOUND][] = 
{
	"vox/effect_killer2/kill/outofworld.wav",
	"vox/effect_killer2/kill/incredible.wav"
}

#define MAX_8KILL_SOUND 1
new Kill8_Sound[MAX_8KILL_SOUND][] = 
{
	"vox/effect_killer2/kill/ohgod.wav"
}

enum
{
	KILL_HEADSHOT = 1,
	KILL_GRENADE,
	KILL_MELEE
}

new g_MyKillCount[33], g_MySpecialKill[33], g_SyncHud_Kill
new g_Msg_SayText

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("DeathMsg", "Event_Death", "a")
	
	g_Msg_SayText = get_user_msgid("SayText")
	g_SyncHud_Kill = CreateHudSyncObj(SYNCHUD_NUMBER)
}

public plugin_precache()
{
	new i
	for(i = 0; i < MAX_HEADSHOT_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, HeadShot_Sound[i])
	for(i = 0; i < MAX_MELEE_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, Melee_Sound[i])
	for(i = 0; i < MAX_GRENADE_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, Grenade_Sound[i])
	for(i = 0; i < MAX_MELEEKILLED_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, MeleeKilled_Sound[i])
	for(i = 0; i < MAX_2KILL_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, Kill2_Sound[i])
	for(i = 0; i < MAX_3KILL_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, Kill3_Sound[i])
	for(i = 0; i < MAX_4KILL_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, Kill4_Sound[i])
	for(i = 0; i < MAX_5KILL_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, Kill5_Sound[i])
	for(i = 0; i < MAX_6KILL_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, Kill6_Sound[i])
	for(i = 0; i < MAX_7KILL_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, Kill7_Sound[i])	
	for(i = 0; i < MAX_8KILL_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, Kill8_Sound[i])		
}

public zd_user_infected(id, Attacker, Infection)
{
	if(!Infection) return
	
	g_MyKillCount[Attacker] = min(g_MyKillCount[Attacker] + 1, MAX_KILL)
	
	if(g_MyKillCount[Attacker] <= 1)
	{ // 1 Kill
		g_MySpecialKill[Attacker] = 0
	}
	
	remove_task(Attacker+TASK_CHECK_KILL)
	set_task(KILL_CHECK_DELAY, "Check_Kill", Attacker+TASK_CHECK_KILL)	
}

public Event_Death()
{
	static Attacker, Victim, Headshot, Weapon[32]
	
	Attacker = read_data(1)
	Victim = read_data(2)
	Headshot = read_data(3)
	read_data(4, Weapon, sizeof(Weapon))
	
	if(!is_user_connected(Attacker))
		return
	if(zd_get_user_zombie(Attacker))
		return
		
	g_MyKillCount[Attacker] = min(g_MyKillCount[Attacker] + 1, MAX_KILL)
	
	if(g_MyKillCount[Attacker] <= 1)
	{ // 1 Kill
		g_MySpecialKill[Attacker] = 0
		
		if(Headshot)
		{
			g_MySpecialKill[Attacker] = KILL_HEADSHOT
		}/* else if(equal(Weapon, "knife")) {
			g_MySpecialKill[Attacker] = KILL_MELEE
			if(is_user_connected(Victim)) PlaySound(Victim, MeleeKilled_Sound[random_num(0, MAX_MELEEKILLED_SOUND - 1)])
		} */else if(equal(Weapon, "grenade")) {
			g_MySpecialKill[Attacker] = KILL_GRENADE
		}
	}
	
	remove_task(Attacker+TASK_CHECK_KILL)
	set_task(KILL_CHECK_DELAY, "Check_Kill", Attacker+TASK_CHECK_KILL)
}

public Check_Kill(id)
{
	id -= TASK_CHECK_KILL
	if(!is_user_connected(id))
		return
		
	static Color[3], KillText[64], MsgText
	Color[0] = Color[1] = Color[2] = 0
	MsgText = 0
		
	switch(g_MyKillCount[id])
	{
		case 0..1:
		{
			MsgText = 0
			switch(g_MySpecialKill[id])
			{
				case KILL_HEADSHOT: 
				{
					Color[0] = 250; Color[1] = 250; Color[2] = 250
					formatex(KillText, sizeof(KillText), "HEADSHOT !!!")
					PlaySound(id, HeadShot_Sound[random_num(0, MAX_HEADSHOT_SOUND - 1)])
				}
				case KILL_MELEE: 
				{
					Color[0] = 250; Color[1] = 250; Color[2] = 250
					formatex(KillText, sizeof(KillText), "MELEE KILL !!!")
					PlaySound(id, Melee_Sound[random_num(0, MAX_MELEE_SOUND - 1)])
				}
				case KILL_GRENADE: 
				{
					Color[0] = 250; Color[1] = 250; Color[2] = 250
					formatex(KillText, sizeof(KillText), "GRENADE KILL !!!")
					PlaySound(id, Grenade_Sound[random_num(0, MAX_GRENADE_SOUND - 1)])
				}
			}
		}
		case 2:
		{
			MsgText = 1
			Color[0] = 0; Color[1] = 255; Color[2] = 0
			if(g_MySpecialKill[id] == KILL_HEADSHOT) formatex(KillText, sizeof(KillText), "2 KILL !!!^n- Headshot -")
			else formatex(KillText, sizeof(KillText), "2 KILL !!!")
			PlaySound(id, Kill2_Sound[random_num(0, MAX_2KILL_SOUND - 1)])
		}
		case 3:
		{
			MsgText = 1
			Color[0] = 150; Color[1] = 150; Color[2] = 0
			if(g_MySpecialKill[id] == KILL_HEADSHOT) formatex(KillText, sizeof(KillText), "3 KILL !!!^n- Headshot -")
			else formatex(KillText, sizeof(KillText), "3 KILL !!!")
			PlaySound(id, Kill3_Sound[random_num(0, MAX_3KILL_SOUND - 1)])
		}
		case 4:
		{
			MsgText = 1
			Color[0] = 150; Color[1] = 0; Color[2] = 0
			if(g_MySpecialKill[id] == KILL_HEADSHOT) formatex(KillText, sizeof(KillText), "4 KILL !!!^n- Headshot -")
			else formatex(KillText, sizeof(KillText), "4 KILL !!!")
			PlaySound(id, Kill4_Sound[random_num(0, MAX_4KILL_SOUND - 1)])
		}
		case 5:
		{
			MsgText = 1
			Color[0] = 200; Color[1] = 0; Color[2] = 0
			if(g_MySpecialKill[id] == KILL_HEADSHOT) formatex(KillText, sizeof(KillText), "5 KILL !!!^n- Headshot -")
			else formatex(KillText, sizeof(KillText), "5 KILL !!!")
			PlaySound(id, Kill5_Sound[random_num(0, MAX_5KILL_SOUND - 1)])	
		}
		case 6:
		{
			MsgText = 1
			Color[0] = 250; Color[1] = 0; Color[2] = 0
			if(g_MySpecialKill[id] == KILL_HEADSHOT) formatex(KillText, sizeof(KillText), "6 KILL !!!^n- Headshot -")
			else formatex(KillText, sizeof(KillText), "6 KILL !!!")
			PlaySound(id, Kill6_Sound[random_num(0, MAX_6KILL_SOUND - 1)])	
		}
		case 7:
		{
			MsgText = 1
			Color[0] = 255; Color[1] = 0; Color[2] = 0
			if(g_MySpecialKill[id] == KILL_HEADSHOT) formatex(KillText, sizeof(KillText), "7 KILL !!!^n- Headshot -")
			else formatex(KillText, sizeof(KillText), "7 KILL !!!")
			PlaySound(id, Kill7_Sound[random_num(0, MAX_7KILL_SOUND - 1)])		
		}
		case 8:
		{
			MsgText = 1
			Color[0] = 255; Color[1] = 0; Color[2] = 0
			if(g_MySpecialKill[id] == KILL_HEADSHOT) formatex(KillText, sizeof(KillText), "8 KILL !!!^n- Headshot -")
			else formatex(KillText, sizeof(KillText), "8 KILL !!!")
			PlaySound(id, Kill7_Sound[random_num(0, MAX_8KILL_SOUND - 1)])	
			
		}
		default:
		{
			return
		}
	}
	
	g_MySpecialKill[id] = 0

	set_hudmessage(Color[0], Color[1], Color[2], KILL_HUD_X, KILL_HUD_Y, 0, 3.0, 3.0)
	ShowSyncHudMsg(id, g_SyncHud_Kill, KillText)
	
	remove_task(id+TASK_RESET_TIME)
	set_task(RESET_TIME, "Do_Reset", id+TASK_RESET_TIME)
	
	if(MsgText && g_MyKillCount[id] != 0)
	{
		static Name[64]
		get_user_name(id, Name, sizeof(Name))
		
		client_printc(0, "!g[CSO]!n Player !g%s!n did !t%i!n kill(s) !!!", Name, g_MyKillCount[id])
	}
}

public Do_Reset(id)
{
	id -= TASK_RESET_TIME
	if(!is_user_connected(id))
		return
		
	g_MyKillCount[id] = 0
	g_MySpecialKill[id] = 0
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}


// Colour Chat
stock client_printc(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
    
	replace_all(msg, 190, "!g", "^x04"); // Green Color
	replace_all(msg, 190, "!n", "^x01"); // Default Color
	replace_all(msg, 190, "!t", "^x03"); // Team Color
    
	if (id) players[0] = id; else get_players(players, count, "ch");
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, g_Msg_SayText, _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}  
