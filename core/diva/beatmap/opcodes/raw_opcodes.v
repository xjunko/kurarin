module opcodes

import os

pub const (
	raw_opcodes = {
        "105": {"opcode": "AGEAGE_CTRL", "len": "8"},
        "46": {"opcode": "AIM", "len": "3"},
        "97": {"opcode": "AOTO_CAP", "len": "1"},
        "56": {"opcode": "AUTO_BLINK", "len": "2"},
        "28": {"opcode": "BAR_TIME_SET", "len": "2"},
        "93": {"opcode": "BLOOM", "len": "2"},
        "14": {"opcode": "CHANGE_FIELD", "len": "1"},
        "96": {"opcode": "CHARA_ALPHA", "len": "4"},
        "72": {"opcode": "CHARA_COLOR", "len": "2"},
        "60": {"opcode": "CHARA_HEIGHT_ADJUST", "len": "2"},
        "103": {"opcode": "CHARA_LIGHT", "len": "3"},
        "62": {"opcode": "CHARA_POS_ADJUST", "len": "4"},
        "59": {"opcode": "CHARA_SIZE", "len": "2"},
        "50": {"opcode": "CLOTH_WET", "len": "2"},
        "94": {"opcode": "COLOR_COLLE", "len": "3"},
        "13": {"opcode": "DATA_CAMERA", "len": "2"},
        "66": {"opcode": "DATA_CAMERA_START", "len": "2"},
        "95": {"opcode": "DOF", "len": "3"},
        "48": {"opcode": "EDIT_BLUSH", "len": "1"},
        "81": {"opcode": "EDIT_CAMERA", "len": "24"},
        "44": {"opcode": "EDIT_DISP", "len": "1"},
        "43": {"opcode": "EDIT_EFFECT", "len": "2"},
        "78": {"opcode": "EDIT_EXPRESSION", "len": "2"},
        "41": {"opcode": "EDIT_EYE", "len": "2"},
        "40": {"opcode": "EDIT_EYELID", "len": "1"},
        "75": {"opcode": "EDIT_EYELID_ANIM", "len": "3"},
        "79": {"opcode": "EDIT_EYE_ANIM", "len": "3"},
        "30": {"opcode": "EDIT_FACE", "len": "1"},
        "45": {"opcode": "EDIT_HAND_ANIM", "len": "2"},
        "76": {"opcode": "EDIT_INSTRUMENT_ITEM", "len": "2"},
        "42": {"opcode": "EDIT_ITEM", "len": "1"},
        "34": {"opcode": "EDIT_LYRIC", "len": "2"},
        "82": {"opcode": "EDIT_MODE_SELECT", "len": "1"},
        "27": {"opcode": "EDIT_MOTION", "len": "4"},
        "91": {"opcode": "EDIT_MOTION_F", "len": "6"},
        "77": {"opcode": "EDIT_MOTION_LOOP", "len": "4"},
        "64": {"opcode": "EDIT_MOT_SMOOTH_LEN", "len": "2"},
        "36": {"opcode": "EDIT_MOUTH", "len": "1"},
        "80": {"opcode": "EDIT_MOUTH_ANIM", "len": "2"},
        "38": {"opcode": "EDIT_MOVE", "len": "7"},
        "74": {"opcode": "EDIT_MOVE_XYZ", "len": "9"},
        "39": {"opcode": "EDIT_SHADOW", "len": "1"},
        "35": {"opcode": "EDIT_TARGET", "len": "5"},
        "9": {"opcode": "EFFECT", "len": "6"},
        "11": {"opcode": "EFFECT_OFF", "len": "1"},
        "0": {"opcode": "END", "len": "0"},
        "22": {"opcode": "EXPRESSION", "len": "4"},
        "18": {"opcode": "EYE_ANIM", "len": "3"},
        "89": {"opcode": "FACE_TYPE", "len": "1"},
        "10": {"opcode": "FADEIN_FIELD", "len": "2"},
        "17": {"opcode": "FADEOUT_FIELD", "len": "2"},
        "55": {"opcode": "FADE_MODE", "len": "1"},
        "92": {"opcode": "FOG", "len": "3"},
        "20": {"opcode": "HAND_ANIM", "len": "5"},
        "47": {"opcode": "HAND_ITEM", "len": "3"},
        "87": {"opcode": "HAND_SCALE", "len": "3"},
        "15": {"opcode": "HIDE_FIELD", "len": "1"},
        "101": {"opcode": "ITEM_ALPHA", "len": "4"},
        "61": {"opcode": "ITEM_ANIM", "len": "4"},
        "85": {"opcode": "ITEM_ANIM_ATTACH", "len": "3"},
        "88": {"opcode": "LIGHT_POS", "len": "4"},
        "51": {"opcode": "LIGHT_ROT", "len": "3"},
        "21": {"opcode": "LOOK_ANIM", "len": "4"},
        "23": {"opcode": "LOOK_CAMERA", "len": "5"},
        "24": {"opcode": "LYRIC", "len": "2"},
        "98": {"opcode": "MAN_CAP", "len": "1"},
        "4": {"opcode": "MIKU_DISP", "len": "2"},
        "2": {"opcode": "MIKU_MOVE", "len": "4"},
        "3": {"opcode": "MIKU_ROT", "len": "2"},
        "5": {"opcode": "MIKU_SHADOW", "len": "2"},
        "26": {"opcode": "MODE_SELECT", "len": "2"},
        "19": {"opcode": "MOUTH_ANIM", "len": "5"},
        "31": {"opcode": "MOVE_CAMERA", "len": "21"},
        "16": {"opcode": "MOVE_FIELD", "len": "3"},
        "102": {"opcode": "MOVIE_CUT_CHG", "len": "1"},
        "68": {"opcode": "MOVIE_DISP", "len": "1"},
        "67": {"opcode": "MOVIE_PLAY", "len": "1"},
        "25": {"opcode": "MUSIC_PLAY", "len": "0"},
        "49": {"opcode": "NEAR_CLIP", "len": "2"},
        "71": {"opcode": "OSAGE_MV_CCL", "len": "3"},
        "70": {"opcode": "OSAGE_STEP", "len": "3"},
        "57": {"opcode": "PARTS_DISP", "len": "3"},
        "106": {"opcode": "PSE", "len": "2"},
        "65": {"opcode": "PV_BRANCH_MODE", "len": "1"},
        "32": {"opcode": "PV_END", "len": "0"},
        "83": {"opcode": "PV_END_FADEOUT", "len": "2"},
        "54": {"opcode": "SATURATE", "len": "1"},
        "52": {"opcode": "SCENE_FADE", "len": "6"},
        "63": {"opcode": "SCENE_ROT", "len": "1"},
        "12": {"opcode": "SET_CAMERA", "len": "6"},
        "37": {"opcode": "SET_CHARA", "len": "1"},
        "7": {"opcode": "SET_MOTION", "len": "4"},
        "8": {"opcode": "SET_PLAYDATA", "len": "2"},
        "73": {"opcode": "SE_EFFECT", "len": "1"},
        "29": {"opcode": "SHADOWHEIGHT", "len": "2"},
        "33": {"opcode": "SHADOWPOS", "len": "3"},
        "90": {"opcode": "SHADOW_CAST", "len": "2"},
        "86": {"opcode": "SHADOW_RANGE", "len": "1"},
        "100": {"opcode": "SHIMMER", "len": "3"},
        "104": {"opcode": "STAGE_LIGHT", "len": "3"},
        "6": {"opcode": "TARGET", "len": "7"},
        "84": {"opcode": "TARGET_FLAG", "len": "1"},
        "58": {"opcode": "TARGET_FLYING_TIME", "len": "1"},
        "1": {"opcode": "TIME", "len": "1"},
        "53": {"opcode": "TONE_TRANS", "len": "6"},
        "99": {"opcode": "TOON", "len": "3"},
        "69": {"opcode": "WIND", "len": "3"},
    }
)

// Internal uses
fn generate_opcode_based_on_dict_to_v_code() {
    // Sort the raw opcodes
    mut sorted_keys := raw_opcodes.keys()
    sorted_keys.sort_with_compare(fn (a &string, b &string) int {
        return a.int() - b.int()
    })
    sorted_raw_opcodes := sorted_keys.map(raw_opcodes[it])

    // header
    mut result_code := "module opcodes\n\n// This file is auto-generated from `raw_opcodes.v`\n"

    // const decl
    result_code += "pub const (
    codes = {\n"

    for id, data in sorted_raw_opcodes {
        // Generate da motherfuckin c0de
        result_code += "        ${id}: OPCode{ action: \"${data['opcode']}\", length: ${data['len']} }, \n"
    }

    result_code += "    }\n)\n\n" // Done

    // struct decl
    result_code += "// Struct Declaration\n"

    result_code += "pub struct OPCode {
    pub mut:
        action string
        length int
        arguments []int
}\n"

    os.write_file("./core/diva/beatmap/opcodes/opcodes.v", result_code) or { panic("Failed to save generated opcodes: ${err}") }
}

fn init() {
    if !os.exists("./core/diva/beatmap/opcodes/opcodes.v") {
        println("No OPCODEs file detected, generating one.")
        generate_opcode_based_on_dict_to_v_code()
        println("OPCODEs generation done!")
        panic("Recompile the program.")
    }
}