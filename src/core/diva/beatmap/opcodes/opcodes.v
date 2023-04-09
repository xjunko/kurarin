module opcodes

// This file is auto-generated from `raw_opcodes.v`
pub const (
	codes = {
		0:   OPCode{
			action: 'END'
			length: 0
		}
		1:   OPCode{
			action: 'TIME'
			length: 1
		}
		2:   OPCode{
			action: 'MIKU_MOVE'
			length: 4
		}
		3:   OPCode{
			action: 'MIKU_ROT'
			length: 2
		}
		4:   OPCode{
			action: 'MIKU_DISP'
			length: 2
		}
		5:   OPCode{
			action: 'MIKU_SHADOW'
			length: 2
		}
		6:   OPCode{
			action: 'TARGET'
			length: 7
		}
		7:   OPCode{
			action: 'SET_MOTION'
			length: 4
		}
		8:   OPCode{
			action: 'SET_PLAYDATA'
			length: 2
		}
		9:   OPCode{
			action: 'EFFECT'
			length: 6
		}
		10:  OPCode{
			action: 'FADEIN_FIELD'
			length: 2
		}
		11:  OPCode{
			action: 'EFFECT_OFF'
			length: 1
		}
		12:  OPCode{
			action: 'SET_CAMERA'
			length: 6
		}
		13:  OPCode{
			action: 'DATA_CAMERA'
			length: 2
		}
		14:  OPCode{
			action: 'CHANGE_FIELD'
			length: 1
		}
		15:  OPCode{
			action: 'HIDE_FIELD'
			length: 1
		}
		16:  OPCode{
			action: 'MOVE_FIELD'
			length: 3
		}
		17:  OPCode{
			action: 'FADEOUT_FIELD'
			length: 2
		}
		18:  OPCode{
			action: 'EYE_ANIM'
			length: 3
		}
		19:  OPCode{
			action: 'MOUTH_ANIM'
			length: 5
		}
		20:  OPCode{
			action: 'HAND_ANIM'
			length: 5
		}
		21:  OPCode{
			action: 'LOOK_ANIM'
			length: 4
		}
		22:  OPCode{
			action: 'EXPRESSION'
			length: 4
		}
		23:  OPCode{
			action: 'LOOK_CAMERA'
			length: 5
		}
		24:  OPCode{
			action: 'LYRIC'
			length: 2
		}
		25:  OPCode{
			action: 'MUSIC_PLAY'
			length: 0
		}
		26:  OPCode{
			action: 'MODE_SELECT'
			length: 2
		}
		27:  OPCode{
			action: 'EDIT_MOTION'
			length: 4
		}
		28:  OPCode{
			action: 'BAR_TIME_SET'
			length: 2
		}
		29:  OPCode{
			action: 'SHADOWHEIGHT'
			length: 2
		}
		30:  OPCode{
			action: 'EDIT_FACE'
			length: 1
		}
		31:  OPCode{
			action: 'MOVE_CAMERA'
			length: 21
		}
		32:  OPCode{
			action: 'PV_END'
			length: 0
		}
		33:  OPCode{
			action: 'SHADOWPOS'
			length: 3
		}
		34:  OPCode{
			action: 'EDIT_LYRIC'
			length: 2
		}
		35:  OPCode{
			action: 'EDIT_TARGET'
			length: 5
		}
		36:  OPCode{
			action: 'EDIT_MOUTH'
			length: 1
		}
		37:  OPCode{
			action: 'SET_CHARA'
			length: 1
		}
		38:  OPCode{
			action: 'EDIT_MOVE'
			length: 7
		}
		39:  OPCode{
			action: 'EDIT_SHADOW'
			length: 1
		}
		40:  OPCode{
			action: 'EDIT_EYELID'
			length: 1
		}
		41:  OPCode{
			action: 'EDIT_EYE'
			length: 2
		}
		42:  OPCode{
			action: 'EDIT_ITEM'
			length: 1
		}
		43:  OPCode{
			action: 'EDIT_EFFECT'
			length: 2
		}
		44:  OPCode{
			action: 'EDIT_DISP'
			length: 1
		}
		45:  OPCode{
			action: 'EDIT_HAND_ANIM'
			length: 2
		}
		46:  OPCode{
			action: 'AIM'
			length: 3
		}
		47:  OPCode{
			action: 'HAND_ITEM'
			length: 3
		}
		48:  OPCode{
			action: 'EDIT_BLUSH'
			length: 1
		}
		49:  OPCode{
			action: 'NEAR_CLIP'
			length: 2
		}
		50:  OPCode{
			action: 'CLOTH_WET'
			length: 2
		}
		51:  OPCode{
			action: 'LIGHT_ROT'
			length: 3
		}
		52:  OPCode{
			action: 'SCENE_FADE'
			length: 6
		}
		53:  OPCode{
			action: 'TONE_TRANS'
			length: 6
		}
		54:  OPCode{
			action: 'SATURATE'
			length: 1
		}
		55:  OPCode{
			action: 'FADE_MODE'
			length: 1
		}
		56:  OPCode{
			action: 'AUTO_BLINK'
			length: 2
		}
		57:  OPCode{
			action: 'PARTS_DISP'
			length: 3
		}
		58:  OPCode{
			action: 'TARGET_FLYING_TIME'
			length: 1
		}
		59:  OPCode{
			action: 'CHARA_SIZE'
			length: 2
		}
		60:  OPCode{
			action: 'CHARA_HEIGHT_ADJUST'
			length: 2
		}
		61:  OPCode{
			action: 'ITEM_ANIM'
			length: 4
		}
		62:  OPCode{
			action: 'CHARA_POS_ADJUST'
			length: 4
		}
		63:  OPCode{
			action: 'SCENE_ROT'
			length: 1
		}
		64:  OPCode{
			action: 'EDIT_MOT_SMOOTH_LEN'
			length: 2
		}
		65:  OPCode{
			action: 'PV_BRANCH_MODE'
			length: 1
		}
		66:  OPCode{
			action: 'DATA_CAMERA_START'
			length: 2
		}
		67:  OPCode{
			action: 'MOVIE_PLAY'
			length: 1
		}
		68:  OPCode{
			action: 'MOVIE_DISP'
			length: 1
		}
		69:  OPCode{
			action: 'WIND'
			length: 3
		}
		70:  OPCode{
			action: 'OSAGE_STEP'
			length: 3
		}
		71:  OPCode{
			action: 'OSAGE_MV_CCL'
			length: 3
		}
		72:  OPCode{
			action: 'CHARA_COLOR'
			length: 2
		}
		73:  OPCode{
			action: 'SE_EFFECT'
			length: 1
		}
		74:  OPCode{
			action: 'EDIT_MOVE_XYZ'
			length: 9
		}
		75:  OPCode{
			action: 'EDIT_EYELID_ANIM'
			length: 3
		}
		76:  OPCode{
			action: 'EDIT_INSTRUMENT_ITEM'
			length: 2
		}
		77:  OPCode{
			action: 'EDIT_MOTION_LOOP'
			length: 4
		}
		78:  OPCode{
			action: 'EDIT_EXPRESSION'
			length: 2
		}
		79:  OPCode{
			action: 'EDIT_EYE_ANIM'
			length: 3
		}
		80:  OPCode{
			action: 'EDIT_MOUTH_ANIM'
			length: 2
		}
		81:  OPCode{
			action: 'EDIT_CAMERA'
			length: 24
		}
		82:  OPCode{
			action: 'EDIT_MODE_SELECT'
			length: 1
		}
		83:  OPCode{
			action: 'PV_END_FADEOUT'
			length: 2
		}
		84:  OPCode{
			action: 'TARGET_FLAG'
			length: 1
		}
		85:  OPCode{
			action: 'ITEM_ANIM_ATTACH'
			length: 3
		}
		86:  OPCode{
			action: 'SHADOW_RANGE'
			length: 1
		}
		87:  OPCode{
			action: 'HAND_SCALE'
			length: 3
		}
		88:  OPCode{
			action: 'LIGHT_POS'
			length: 4
		}
		89:  OPCode{
			action: 'FACE_TYPE'
			length: 1
		}
		90:  OPCode{
			action: 'SHADOW_CAST'
			length: 2
		}
		91:  OPCode{
			action: 'EDIT_MOTION_F'
			length: 6
		}
		92:  OPCode{
			action: 'FOG'
			length: 3
		}
		93:  OPCode{
			action: 'BLOOM'
			length: 2
		}
		94:  OPCode{
			action: 'COLOR_COLLE'
			length: 3
		}
		95:  OPCode{
			action: 'DOF'
			length: 3
		}
		96:  OPCode{
			action: 'CHARA_ALPHA'
			length: 4
		}
		97:  OPCode{
			action: 'AOTO_CAP'
			length: 1
		}
		98:  OPCode{
			action: 'MAN_CAP'
			length: 1
		}
		99:  OPCode{
			action: 'TOON'
			length: 3
		}
		100: OPCode{
			action: 'SHIMMER'
			length: 3
		}
		101: OPCode{
			action: 'ITEM_ALPHA'
			length: 4
		}
		102: OPCode{
			action: 'MOVIE_CUT_CHG'
			length: 1
		}
		103: OPCode{
			action: 'CHARA_LIGHT'
			length: 3
		}
		104: OPCode{
			action: 'STAGE_LIGHT'
			length: 3
		}
		105: OPCode{
			action: 'AGEAGE_CTRL'
			length: 8
		}
		106: OPCode{
			action: 'PSE'
			length: 2
		}
	}
)

// Struct Declaration
pub struct OPCode {
pub mut:
	action    string
	length    int
	arguments []int
}

pub fn (opcode OPCode) clone() OPCode {
	return OPCode{
		...opcode
	}
}
