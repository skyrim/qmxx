/* 
 * Q Jumpstats constants by Quaker
 *
 * This file is provided as is (no warranties).
 */

#if defined _q_jumpstats_const_included
	#endinput
#endif

#define _q_jumpstats_const_included

#define MAX_STRAFES 12
#define MAX_DROP_HEIGHT 280.0

enum JumpType
{
	JumpType_LJ,
	JumpType_HJ,
	JumpType_BJ,
	JumpType_SBJ,
	JumpType_DropBJ,
	JumpType_CJ,
	JumpType_DCJ,
	JumpType_MCJ,
	JumpType_DropCJ,
	JumpType_WJ,
	JumpType_LadderBJ,
	
	JumpType_TOTAL
};

stock jump_name[JumpType_TOTAL][] =
{
	"LongJump",
	"HighJump",
	"BhopJump",
	"StandUp BhopJump",
	"Drop BhopJump",
	"CountJump",
	"Double CountJump",
	"Multi CountJump",
	"Drop CountJump",
	"WeirdJump",
	"Ladder BhopJump"
};

stock jump_shortname[JumpType_TOTAL][] =
{
	"LJ",
	"HJ",
	"BJ",
	"SBJ",
	"Drop BJ",
	"CJ",
	"DCJ",
	"MCJ",
	"Drop CJ",
	"WJ",
	"Ladder BJ"
};

stock const Float:g_jump_minpre[JumpType_TOTAL] =
{
	250.0, // LJ
	250.0, // HJ
	270.0, // BJ
	270.0, // SBJ
	270.0, // Drop BJ
	260.0, // CJ
	260.0, // DCJ
	260.0, // MCJ
	260.0, // Drop CJ
	260.0, // WJ
	270.0  // Ladder BJ
};

stock const Float:g_jump_targetpre[JumpType_TOTAL] =
{
	278.0, // LJ
	278.0, // HJ
	300.0, // BJ
	300.0, // SBJ
	300.0, // Drop BJ
	290.0, // CJ
	300.0, // DCJ
	300.0, // MCJ
	300.0, // Drop CJ
	300.0, // WJ
	300.0  // Ladder BJ
};

stock const Float:g_jump_mindist[JumpType_TOTAL] =
{
	210.0, // LJ
	210.0, // HJ
	210.0, // BJ
	210.0, // SBJ
	220.0, // Drop BJ
	220.0, // CJ
	220.0, // DCJ
	220.0, // MCJ
	220.0, // Drop CJ
	230.0, // WJ
	230.0  // Ladder BJ
};

stock jump_level[JumpType_TOTAL][3] =
{
	{ 240, 245, 250 }, // LJ
	{ 240, 245, 250 }, // HJ
	{ 230, 235, 240 }, // BJ
	{ 230, 235, 240 }, // SBJ
	{ 240, 245, 250 }, // Drop BJ
	{ 250, 255, 260 }, // CJ
	{ 250, 255, 260 }, // DCJ
	{ 250, 255, 260 }, // MCJ
	{ 250, 255, 260 }, // Drop CJ
	{ 250, 255, 260 }, // WJ
	{ 250, 255, 260 }  // Ladder BJ
};
