///////////////////////////////////////////////////////////////////////////////////////////
// Message Debug Script
//
// Copyright (c) 2004 Xylor Baysklef
//
// This file is part of XyChess.
//
// XyChess is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// XyChess is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with XyChess; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
///////////////////////////////////////////////////////////////////////////////////////////

/////////////// CONSTANTS ///////////////////
// Special move types.
integer PAWN_DOUBLE_MOVE    = 1000;
integer CASTLE_KING_SIDE    = 1001;
integer CASTLE_QUEEN_SIDE   = 1002;
integer PAWN_RECRUIT        = 1003;
integer PAWN_EN_PASSANT     = 1004;

list    SPECIAL_MOVE_TYPES  = [
            PAWN_DOUBLE_MOVE, CASTLE_KING_SIDE,
            CASTLE_QUEEN_SIDE, PAWN_RECRUIT,
            PAWN_EN_PASSANT ];

list    SPECIAL_MOVE_TYPE_NAMES = [
            "PAWN_DOUBLE_MOVE", "CASTLE_KING_SIDE",
            "CASTLE_QUEEN_SIDE", "PAWN_RECRUIT",
            "PAWN_EN_PASSANT" ];


// Piece enumeration.
integer PAWN            = 0;
integer KNIGHT          = 1;
integer BISHOP          = 2;
integer ROOK            = 3;
integer QUEEN           = 4;
integer KING            = 5;

// Piece names list.
list    PIECE_NAMES     = [ "Pawn", "Knight",
                            "Bishop", "Rook",
                            "Queen", "King" ];

// Color enumeration.
integer WHITE           = 8;
integer BLACK           = 16;

integer NONE            = -1;

// Interface messages.
integer AVATAR_IN_CHAIR         = 8000;
integer SQUARE_TOUCHED          = 8001;
integer RECRUIT_PAWN            = 8012;
integer DONE_RECRUITING         = 8013;

// Game messages.
integer NEW_GAME                = 16000;
integer ALLOW_INPUT             = 16001;
integer BOARD_SELECTION         = 16002;
integer SET_TURN                = 16003;

// Move validation messages.
integer VALID_MOVE              = 17000;
integer SHOW_VALID_MOVES        = 17001;
integer CANCEL_SHOW_VALID_MOVES = 17002;

// Dialog boxes.
integer DIALOG_RECRUIT_PAWN         = 12000;
integer DIALOG_RECRUIT_PAWN_DONE    = 12001;

// Piece Manager Messages
integer CLEAR_BOARD     = 13000;
integer SETUP_BOARD     = 13001;
integer ADD_PIECE       = 13002;
integer REMOVE_PIECE    = 13003;
integer MOVE_PIECE      = 13004;
integer KILL_PIECE      = 13005;
integer SELECT_PIECE    = 13006;
integer DESELECT_PIECE  = 13007;


// Channels to set up button info.
integer SET_BUTTON_INFO_A   = 9000;
integer SET_BUTTON_INFO_B   = 9001;
integer REQUEST_BUTTON_INFO = 9002;
integer SET_VALID_TOUCHER   = 9003;

list MESSAGES   = [
                BOARD_SELECTION, ALLOW_INPUT,
                DIALOG_RECRUIT_PAWN, DIALOG_RECRUIT_PAWN_DONE,
                CLEAR_BOARD, SETUP_BOARD, ADD_PIECE, NEW_GAME,
                SQUARE_TOUCHED, AVATAR_IN_CHAIR,
                SET_TURN, REMOVE_PIECE,
                MOVE_PIECE, KILL_PIECE,
                SELECT_PIECE, DESELECT_PIECE, RECRUIT_PAWN, DONE_RECRUITING ];

list MESSAGE_NAMES  = [
                "BOARD_SELECTION", "ALLOW_INPUT",
                "DIALOG_RECRUIT_PAWN", "DIALOG_RECRUIT_PAWN_DONE",
                "CLEAR_BOARD", "SETUP_BOARD", "ADD_PIECE", "NEW_GAME",
                "SQUARE_TOUCHED", "AVATAR_IN_CHAIR",
                "SET_TURN", "REMOVE_PIECE",
                "MOVE_PIECE", "KILL_PIECE",
                "SELECT_PIECE", "DESELECT_PIECE", "RECRUIT_PAWN", "DONE_RECRUITING"
                ];

string  RANK_NAMES  = "abcdefgh";

// This is the seperator to use instead of comma.
string  FIELD_SEPERATOR = "~!~";

///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
key gOwner;
/////////// END GLOBAL VARIABLES ////////////

//////////// Utility functions //////////////
integer GetColor(integer piece) {
    if (piece == NONE)
        return NONE;

    return piece & 24;
}

string GetColorName(integer color) {
    if (color == 8)
        return "WHITE";

    if (color == 16)
        return "BLACK";

    return "NONE";
}

integer GetType(integer piece) {
    if (piece == NONE)
        return NONE;

    return piece & 7;
}

integer GetRow(integer index) {
    return index / 8;
}

integer GetCol(integer index) {
    return index % 8;
}

integer GetIndex(integer row, integer col) {
    // Bounds check.
    if (row < 0 || row > 7 ||
        col < 0 || col > 7)
        return NONE;

    return row * 8 + col;
}


string GetCoordRowCol(integer row, integer col) {
    return llGetSubString(RANK_NAMES, col, col) + (string) (row + 1);
}

string GetCoord(integer index) {
    if (index == NONE)
        return "None";

    return GetCoordRowCol(GetRow(index), GetCol(index));
}

integer GetEnemy(integer color) {
    if (color == WHITE)
        return BLACK;

    return WHITE;
}

////////// End Utility functions /////////////

string TrueFalse(integer flag) {
    if (flag)
        return "TRUE";

    return "FALSE";
}

default {
    state_entry() {
        // Keep track of the owner.
        gOwner = llGetOwner();
    }

    on_rez(integer param) {
        // If the owner changed, reset.
        if (llGetOwner() != gOwner)
            llResetScript();
    }

    touch_start(integer num_detected) {
        // Only process touches from owner.
        if (llDetectedKey(0) != llGetOwner())
            return;
    }

    listen(integer channel, string name, key id, string mesg) {
    }

    link_message(integer sender, integer channel, string data, key id) {
        // Check for the message in our list.
        string MessageName;
        integer MessageIndex = llListFindList(MESSAGES, [channel]);

        if (MessageIndex == -1)
            return;
        else
            MessageName = llList2String(MESSAGE_NAMES, MessageIndex);

        // Format contents.
        string Contents;

        // Split up the data.
        list FieldList  = llParseString2List(data, [FIELD_SEPERATOR], []);
        list CSVList    = llCSV2List(data);

        if (channel == ADD_PIECE) {
            integer Color   = (integer) llList2String(FieldList, 0);
            integer Type    = (integer) llList2String(FieldList, 1);
            integer Row     = (integer) llList2String(FieldList, 2);
            integer Col     = (integer) llList2String(FieldList, 3);

            string PieceName = llList2String(PIECE_NAMES, Type);

            Contents = GetColorName(Color) + " " + PieceName + " at " +
                        GetCoordRowCol(Row, Col);
        }
        else if (channel == AVATAR_IN_CHAIR) {
            string Name;
            key Avatar = llKey2Name(id);

            if (Avatar == NULL_KEY || Avatar == "")
                Name = "Nobody";
            else Name = llKey2Name(id);

            if (Name == "")
                Name = "Unknown";

            integer Color = (integer) data;

            Contents = GetColorName(Color) + " Player: " + Name;
        }
        else if (channel == SET_TURN) {
            integer Color = (integer) data;
            Contents = GetColorName(Color);
        }
        else if (channel == KILL_PIECE) {
            integer Piece   = (integer) llList2String(FieldList, 0);
            integer Color   = (integer) llList2String(FieldList, 1);

            Contents = GetColorName(Color) + ": " + GetCoord(Piece);
        }
        else if (channel == MOVE_PIECE) {
            integer Start   = (integer) llList2String(CSVList, 0);
            integer End     = (integer) llList2String(CSVList, 1);
            Contents = GetCoord(Start) + " " + GetCoord(End);
        }
        else if (channel == SELECT_PIECE || channel == DESELECT_PIECE ||
                 channel == SQUARE_TOUCHED || channel == REMOVE_PIECE ||
                 channel == BOARD_SELECTION) {
            integer Square = (integer) data;
            Contents = GetCoord(Square);
        }
        else if (data == "")
            Contents = "N/A";
        else
            Contents = data;

        llSay(0, "Debug 1->" + llGetSubString(MessageName + ": " + Contents, 0, 254));
    }
}
