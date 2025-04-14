#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <ZombieDarkness>
#include <cstrike>

#define PLUGIN "[ZD] Addon: Weapon"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define GAME_NAME "Zombie Darkness"
#define LANG_FILE "ZombieDarkness.txt"

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

#define MAX_WEAPON 64

enum
{
	WEAPON_PRIMARY = 1,
	WEAPON_SECONDARY,
	WEAPON_MELEE
}

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

new g_SelectedPri, g_SelectedSec, g_SelectedMelee
new Array:WeaponName, Array:WeaponType, Array:WeaponBasedOn, Array:WeaponCost
new g_WeaponCount, g_WeaponCount2[4], g_UnlockedWeapon[33][MAX_WEAPON], g_SelectedWeapon[33][4], g_RememberSelect

new g_Forward_Bought, g_Forward_Remove, g_Forward_AddAmmo, g_fwResult
new g_MaxPlayers, g_MsgSayText, g_Connected

new g_WeaponList[4][MAX_WEAPON], g_WeaponListCount[4]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary(LANG_FILE)
	
	g_MaxPlayers = get_maxplayers()
	g_MsgSayText = get_user_msgid("SayText")
	
	g_Forward_Bought = CreateMultiForward("zd_weapon_bought", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward_Remove = CreateMultiForward("zd_weapon_remove", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward_AddAmmo = CreateMultiForward("zd_weapon_addammo", ET_IGNORE, FP_CELL, FP_CELL)
}

public plugin_precache()
{
	WeaponName = ArrayCreate(64, 1)
	WeaponType = ArrayCreate(1, 1)
	WeaponBasedOn = ArrayCreate(1, 1)
	WeaponCost = ArrayCreate(1, 1)
}

public plugin_natives()
{
	register_native("zd_weapon_register", "Native_RegisterWeapon", 1)
	register_native("zd_weapon_get_cswid", "Native_Get_CSWID", 1)
}

public Native_RegisterWeapon(const Name[], Type, BasedOn, Cost)
{
	param_convert(1)
	
	ArrayPushString(WeaponName, Name)
	ArrayPushCell(WeaponType, Type)
	ArrayPushCell(WeaponBasedOn, BasedOn)
	ArrayPushCell(WeaponCost, Cost)
	
	g_WeaponCount++
	g_WeaponCount2[Type]++
	
	return g_WeaponCount - 1
}

public Native_Get_CSWID(id, ItemID)
{
	if(ItemID >= g_WeaponCount)
		return 0
	
	return ArrayGetCell(WeaponBasedOn, ItemID)
}

public client_putinserver(id)
{
	Set_BitVar(g_Connected, id)
	Reset_FirstTime(id)
}

public client_disconnect(id)
{
	UnSet_BitVar(g_Connected, id)
}

public zd_user_spawned(id, Zombie)
{
	if(Zombie) return
	
	Reset_PlayerWeapon(id)
	
	if(!is_user_bot(id)) Show_WeaponMenu(id)
	else set_task(0.1, "Bot_HandleWeapon", id)
}

public zd_nightmare(DayTime)
{
	if(DayTime == DAY_AFTER) 
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_user_alive(i))
				continue
			if(zd_get_user_zombie(i))
				continue
				
			Add_Ammo(i, g_SelectedWeapon[i][WEAPON_PRIMARY])
			Add_Ammo(i, g_SelectedWeapon[i][WEAPON_SECONDARY])
		}
	}
}

public Bot_HandleWeapon(id)
{
	static Type
	
	g_WeaponListCount[WEAPON_PRIMARY] = 0
	g_WeaponListCount[WEAPON_SECONDARY] = 0
	g_WeaponListCount[WEAPON_MELEE] = 0
	
	for(new i = 0; i < g_WeaponCount; i++)
	{
		Type = ArrayGetCell(WeaponType, i)
		
		if(Type == WEAPON_PRIMARY)
		{
			g_WeaponList[WEAPON_PRIMARY][g_WeaponListCount[WEAPON_PRIMARY]] = i
			g_WeaponListCount[WEAPON_PRIMARY]++
		} else if(Type == WEAPON_SECONDARY) {
			g_WeaponList[WEAPON_SECONDARY][g_WeaponListCount[WEAPON_SECONDARY]] = i
			g_WeaponListCount[WEAPON_SECONDARY]++
		} else if(Type == WEAPON_MELEE) {
			g_WeaponList[WEAPON_MELEE][g_WeaponListCount[WEAPON_MELEE]] = i
			g_WeaponListCount[WEAPON_MELEE]++
		}
	}
	
	set_task(random_float(0.5, 3.0), "Bot_SelectRandom", id+2222)
}

public Bot_SelectRandom(id)
{
	id -= 2222
	if(!is_user_alive(id))
		return

	static RandomID; 
	
	RandomID = g_WeaponList[WEAPON_PRIMARY][random(g_WeaponListCount[WEAPON_PRIMARY])]
	Activate_Weapon(id, ArrayGetCell(WeaponType, RandomID), RandomID)
	
	RandomID = g_WeaponList[WEAPON_SECONDARY][random(g_WeaponListCount[WEAPON_SECONDARY])]
	Activate_Weapon(id, ArrayGetCell(WeaponType, RandomID), RandomID)
	
	//RandomID = g_WeaponList[WEAPON_MELEE][random(g_WeaponListCount[WEAPON_MELEE])]
	//Activate_Weapon(id, ArrayGetCell(WeaponType, RandomID), RandomID)
}

public Reset_FirstTime(id)
{
	for(new i = 0; i < MAX_WEAPON; i++)
		g_UnlockedWeapon[id][i] = 0

	g_SelectedWeapon[id][WEAPON_PRIMARY] = -1
	g_SelectedWeapon[id][WEAPON_SECONDARY] = -1
	g_SelectedWeapon[id][WEAPON_MELEE] = -1

	UnSet_BitVar(g_SelectedPri, id)
	UnSet_BitVar(g_SelectedSec, id)
	UnSet_BitVar(g_SelectedMelee, id)
	UnSet_BitVar(g_RememberSelect, id)
}

public Reset_PlayerWeapon(id)
{
	UnSet_BitVar(g_SelectedPri, id)
	UnSet_BitVar(g_SelectedSec, id)
	UnSet_BitVar(g_SelectedMelee, id)
	
	ExecuteForward(g_Forward_Remove, g_fwResult, id, g_SelectedWeapon[id][WEAPON_PRIMARY])
	ExecuteForward(g_Forward_Remove, g_fwResult, id, g_SelectedWeapon[id][WEAPON_SECONDARY])
	ExecuteForward(g_Forward_Remove, g_fwResult, id, g_SelectedWeapon[id][WEAPON_MELEE])
}

public zd_user_preinfect(id, Infector, Infection)
{
	Reset_PlayerWeapon(id)
	
	// Reset
	set_task(0.25, "Real_Reset", id)
}

public Real_Reset(id)
{
	set_pdata_string(id, 492 * 4, "knife", -1 , 20)
	set_pev(id, pev_weaponmodel2, "")
}

public Show_WeaponMenu(id)
{
	if(!g_WeaponCount)
		return
		
	new MenuName[32], ItemData[32]
	formatex(MenuName, sizeof(MenuName), "%L", LANG_SERVER, "WEAPON_MENU_NAMEF")
	
	new Menu = menu_create(MenuName, "MenuHandle_FirstM")
	
	formatex(ItemData, sizeof(ItemData), "%L", LANG_SERVER, "WEAPON_MENU_NEW")
	menu_additem(Menu, ItemData, "0")
	
	if(Get_BitVar(g_RememberSelect, id)) 
	{
		formatex(ItemData, sizeof(ItemData), "%L", LANG_SERVER, "WEAPON_MENU_PREVIOUS")
		menu_additem(Menu, ItemData, "1")
	} else {
		formatex(ItemData, sizeof(ItemData), "\d%L", LANG_SERVER, "WEAPON_MENU_PREVIOUS")
		menu_additem(Menu, ItemData, "1")
	}
	
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, 0)
}

public MenuHandle_FirstM(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)

	new ItemId = str_to_num(Data)
	if(ItemId == 0)
	{
		if(!Get_BitVar(g_SelectedPri, id)) Show_RealWeaponMenu(id, WEAPON_PRIMARY, 0)
		else if(!Get_BitVar(g_SelectedSec, id)) Show_RealWeaponMenu(id, WEAPON_SECONDARY, 0)
		else if(!Get_BitVar(g_SelectedMelee, id)) Show_RealWeaponMenu(id, WEAPON_MELEE, 0)
	} else if(ItemId == 1) {
		if(Get_BitVar(g_RememberSelect, id)) 
		{
			drop_weapons(id, 1)
			drop_weapons(id, 2)
			
			Activate_Weapon(id, ArrayGetCell(WeaponBasedOn, g_SelectedWeapon[id][WEAPON_PRIMARY]), g_SelectedWeapon[id][WEAPON_PRIMARY])
			Activate_Weapon(id, ArrayGetCell(WeaponBasedOn, g_SelectedWeapon[id][WEAPON_SECONDARY]), g_SelectedWeapon[id][WEAPON_SECONDARY])
			Activate_Weapon(id, ArrayGetCell(WeaponBasedOn, g_SelectedWeapon[id][WEAPON_MELEE]), g_SelectedWeapon[id][WEAPON_MELEE])
		} else {
			Show_WeaponMenu(id)
		}
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public Show_RealWeaponMenu(id, WpnType, Page)
{
	if(!is_user_alive(id))
		return
		
	static WeaponTypeN[16], MenuName[32]
	
	if(WpnType == WEAPON_PRIMARY) formatex(WeaponTypeN, sizeof(WeaponTypeN), "%L", LANG_SERVER, "WEAPON_TYPE_PRI")
	else if(WpnType == WEAPON_SECONDARY) formatex(WeaponTypeN, sizeof(WeaponTypeN), "%L", LANG_SERVER, "WEAPON_TYPE_SEC")
	else if(WpnType == WEAPON_MELEE) formatex(WeaponTypeN, sizeof(WeaponTypeN), "%L", LANG_SERVER, "WEAPON_TYPE_MELEE")
	
	formatex(MenuName, sizeof(MenuName), "%L", LANG_SERVER, "WEAPON_MENU_NAME", WeaponTypeN)
	new Menu = menu_create(MenuName, "MenuHandle_Weapon")

	static WeaponTypeI, WeaponNameN[32], MenuItem[64], ItemID[4]
	static WeaponPriceI, Money; Money = cs_get_user_money(id)
	
	for(new i = 0; i < g_WeaponCount; i++)
	{
		WeaponTypeI = ArrayGetCell(WeaponType, i)
		if(WpnType != WeaponTypeI)
			continue
			
		ArrayGetString(WeaponName, i, WeaponNameN, sizeof(WeaponNameN))
		WeaponPriceI = ArrayGetCell(WeaponCost, i)
		
		if(WeaponPriceI > 0)
		{
			if(g_UnlockedWeapon[id][i] || (get_user_flags(id) & ADMIN_LEVEL_H)) formatex(MenuItem, sizeof(MenuItem), "%s", WeaponNameN)
			else {
				if(Money >= WeaponPriceI) formatex(MenuItem, sizeof(MenuItem), "%s \y($%i)\w", WeaponNameN, WeaponPriceI)
				else formatex(MenuItem, sizeof(MenuItem), "\d%s \r($%i)\w", WeaponNameN, WeaponPriceI)
			}
		} else {
			formatex(MenuItem, sizeof(MenuItem), "%s", WeaponNameN)
		}
		
		num_to_str(i, ItemID, sizeof(ItemID))
		menu_additem(Menu, MenuItem, ItemID)
	}
   
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, Page)
}

public MenuHandle_Weapon(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)

	new ItemId = str_to_num(Data)
	new WeaponPriceI = ArrayGetCell(WeaponCost, ItemId)
	new Money = cs_get_user_money(id)
	new WeaponNameN[32]; ArrayGetString(WeaponName, ItemId, WeaponNameN, sizeof(WeaponNameN))
	new OutputInfo[80], WeaponTypeI; WeaponTypeI = ArrayGetCell(WeaponType, ItemId)
	
	if(WeaponPriceI > 0)
	{
		if(g_UnlockedWeapon[id][ItemId]) 
		{
			Activate_Weapon(id, WeaponTypeI, ItemId)
			Recheck_Weapon(id)
		} else {
			if((get_user_flags(id) & ADMIN_LEVEL_H))
			{
				g_UnlockedWeapon[id][ItemId] = 1
				
				Activate_Weapon(id, WeaponTypeI, ItemId)
				Recheck_Weapon(id)
			} else {
				if(Money >= WeaponPriceI) // Unlock now
				{
					g_UnlockedWeapon[id][ItemId] = 1
					
					Activate_Weapon(id, WeaponTypeI, ItemId)
					Recheck_Weapon(id)
					
					formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GAME_NAME, LANG_SERVER, "WEAPON_UNLOCKED", WeaponNameN, WeaponPriceI)
					client_printc(id, OutputInfo)
					
					cs_set_user_money(id, Money - (WeaponPriceI / 2))
				} else { // Not Enough $
					formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GAME_NAME, LANG_SERVER, "WEAPON_UNLOCK_MONEY", WeaponPriceI, WeaponNameN)
					client_printc(id, OutputInfo)
					
					Show_RealWeaponMenu(id, WeaponTypeI, 0)
				}
			}
		}
	} else {
		Activate_Weapon(id, WeaponTypeI, ItemId)
		Recheck_Weapon(id)
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public Activate_Weapon(id, WeaponType, ItemID)
{
	if(WeaponType == WEAPON_PRIMARY) 
	{
		Set_BitVar(g_SelectedPri, id)
		g_SelectedWeapon[id][WEAPON_PRIMARY] = ItemID
		
		drop_weapons(id, 1)
	} else if(WeaponType == WEAPON_SECONDARY) {
		Set_BitVar(g_SelectedSec, id)
		g_SelectedWeapon[id][WEAPON_SECONDARY] = ItemID
		
		drop_weapons(id, 2)
	} else if(WeaponType == WEAPON_MELEE) {
		Set_BitVar(g_SelectedMelee, id)
		g_SelectedWeapon[id][WEAPON_MELEE] = ItemID
		
		Set_BitVar(g_RememberSelect, id)
	}

	ExecuteForward(g_Forward_Bought, g_fwResult, id, ItemID)
	Add_Ammo(id, ItemID)
}

public Add_Ammo(id, ItemID)
{
	ExecuteForward(g_Forward_AddAmmo, g_fwResult, id, ItemID)
}

public Recheck_Weapon(id)
{
	if(!Get_BitVar(g_SelectedPri, id)) Show_RealWeaponMenu(id, WEAPON_PRIMARY, 0)
	else if(!Get_BitVar(g_SelectedSec, id)) Show_RealWeaponMenu(id, WEAPON_SECONDARY, 0)
	else if(!Get_BitVar(g_SelectedMelee, id)) Show_RealWeaponMenu(id, WEAPON_MELEE, 0)
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

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32]; get_weaponname(weaponid, wname, charsmax(wname))

			// Player drops the weapon and looses his bpammo
			engclient_cmd(id, "drop", wname)
		}
	}
}
