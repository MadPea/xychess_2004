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


// Channels to set up button activate texture.
integer SET_ACTIVE_INFO     = 9000;
integer REQUEST_ACTIVE_INFO = 9002;
integer SET_VALID_TOUCHER   = 9003;

// Rules checking messages.
integer CHECK_PAWN      = 11000;
integer CHECK_KNIGHT    = 11001;
integer CHECK_BISHOP    = 11002;
integer CHECK_ROOK      = 11003;
integer CHECK_QUEEN     = 11004;
integer CHECK_KING      = 11005;
integer TEST_CHECK_SETUP  = 11006;
integer TEST_CHECK_RESULTS= 11098;
integer CHECK_RESULTS     = 11099;
integer TEST_CHECK_BASE   = 11100;

integer VALID_MOVE              = 17000;
integer SHOW_VALID_MOVES        = 17001;
integer CANCEL_SHOW_VALID_MOVES = 17002;
integer BOARD_UPDATE            = 17003;
integer CHECK_VALID_MOVES       = 17004;
integer GET_VALIDATION          = 17005;
integer RETURN_VALIDATION       = 17006;

list MESSAGES   = [
                SET_ACTIVE_INFO, REQUEST_ACTIVE_INFO, SET_VALID_TOUCHER,
                CHECK_PAWN, CHECK_KNIGHT, CHECK_BISHOP, CHECK_ROOK,
                CHECK_QUEEN, CHECK_KING, CHECK_RESULTS,
                TEST_CHECK_SETUP, TEST_CHECK_RESULTS,
                VALID_MOVE, SHOW_VALID_MOVES, CANCEL_SHOW_VALID_MOVES,
                BOARD_UPDATE, CHECK_VALID_MOVES, GET_VALIDATION, RETURN_VALIDATION ];

list MESSAGE_NAMES  = [
                "SET_ACTIVE_INFO", "REQUEST_ACTIVE_INFO", "SET_VALID_TOUCHER",
                "CHECK_PAWN", "CHECK_KNIGHT", "CHECK_BISHOP", "CHECK_ROOK",
                "CHECK_QUEEN", "CHECK_KING", "CHECK_RESULTS",
                "TEST_CHECK_SETUP", "TEST_CHECK_RESULTS",
                "VALID_MOVE", "SHOW_VALID_MOVES", "CANCEL_SHOW_VALID_MOVES",
                "BOARD_UPDATE", "CHECK_VALID_MOVES", "GET_VALIDATION", "RETURN_VALIDATION"
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

string GetSpecialTypeName(integer type) {
    integer index = llListFindList(SPECIAL_MOVE_TYPES, [type]);
    if (index == -1)
        return "None";

    return llList2String(SPECIAL_MOVE_TYPE_NAMES, index);
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

        // Format contents.
        string Contents;

        if (MessageIndex == -1) {
            // See if this was a TEST_CHECK_BASE message.
            if (channel >= TEST_CHECK_BASE && channel < TEST_CHECK_BASE + 100) {
                MessageName = "TEST_CHECK_BASE (" +
                            (string) (channel - TEST_CHECK_BASE) + ")";

                list CSVList = llCSV2List(data);
                integer MoveToTest      = (integer) llList2String(CSVList, 0);
                integer SpecialMoveType = (integer) llList2String(CSVList, 1);

                Contents = GetCoord(MoveToTest);
                if (SpecialMoveType != NONE)
                    Contents += " (" + GetSpecialTypeName(SpecialMoveType) + ")";

                llSay(0, "Debug 2->" + llGetSubString(MessageName + ": " + Contents, 0, 254));
            }

            return;
        }
        else
            MessageName = llList2String(MESSAGE_NAMES, MessageIndex);


        // Split up the data.
        list FieldList  = llParseString2List(data, [FIELD_SEPERATOR], []);
        list CSVList    = llCSV2List(data);

        if( channel == SET_VALID_TOUCHER) {
            string Name;
            key Avatar = llKey2Name(id);

            if (Avatar == NULL_KEY || Avatar == "")
                Name = "Nobody";
            else Name = llKey2Name(id);

            if (Name == "")
                Name = "Unknown";

            Contents = Name;
        }
        else if (channel == SET_ACTIVE_INFO) {
            string Alpha = llList2String(FieldList, 1);
            string ActiveColor    = llList2String(FieldList, 2);
            string ValidColor     = llList2String(FieldList, 3);
            integer ShowValidMoves = (integer)llList2String(FieldList, 4);

            Contents = "Alpha: " + (string) Alpha + ", Active Color: " + ActiveColor +
                        ", Valid Color: " + ValidColor + ", Show Valid Moves: " +
                        TrueFalse(ShowValidMoves);
        }
        else if (channel >= CHECK_PAWN && channel <= TEST_CHECK_SETUP) {
            integer Color                  = (integer) llList2String(CSVList, 0);
            integer Type                   = (integer) llList2String(CSVList, 1);
            integer Row                    = (integer) llList2String(CSVList, 2);
            integer Col                    = (integer) llList2String(CSVList, 3);
            integer WhiteCanCastleKingSide = (integer) llList2String(CSVList, 4);
            integer WhiteCanCastleQueenSide= (integer) llList2String(CSVList, 5);
            integer BlackCanCastleKingSide = (integer) llList2String(CSVList, 6);
            integer BlackCanCastleQueenSide= (integer) llList2String(CSVList, 7);
            integer PawnEnPassant          = (integer) llList2String(CSVList, 8);

            string PieceName = llList2String(PIECE_NAMES, Type);

            Contents = GetColorName(Color) + " " + PieceName + " (" +
                        GetCoordRowCol(Row, Col) + ")";

            if (WhiteCanCastleKingSide)
                Contents += ", WKS";
            if (WhiteCanCastleQueenSide)
                Contents += ", WQS";
            if (BlackCanCastleKingSide)
                Contents += ", BKS";
            if (BlackCanCastleQueenSide)
                Contents += ", BQS";

            Contents += ", PEP: " + GetCoord(PawnEnPassant);
        }
        else if (channel == CHECK_RESULTS) {
            // Split up the results into useful lists.
            integer ValidPiece      = (integer) llList2String(CSVList, 0);
            integer ValidMovesLen   = (integer) llList2String(CSVList, 1);
            integer SpecialMovesLen = (integer) llList2String(CSVList, ValidMovesLen + 2);
            integer SpecialTypesLen = (integer) llList2String(CSVList, ValidMovesLen + 2
                                                            + SpecialMovesLen + 2);

            list SpecialMoves;
            list SpecialTypes;

            if (SpecialMovesLen) {
                SpecialMoves = llList2List(CSVList, ValidMovesLen + 3,
                                        ValidMovesLen + SpecialMovesLen + 2);
                SpecialTypes = llList2List(CSVList, ValidMovesLen + SpecialMovesLen + 4,
                                        ValidMovesLen + SpecialMovesLen + SpecialTypesLen + 3);

                integer i;
                integer Move;
                integer Type;
                Contents = "Special Moves (" + GetCoord(ValidPiece) + "): ";
                for (i = 0; i < SpecialMovesLen - 1; i++) {
                    Move = (integer) llList2String(SpecialMoves, i);
                    Type = (integer) llList2String(SpecialTypes, i);

                    Contents +=  GetCoord(Move) + " (" + GetSpecialTypeName(Type) + "), ";
                }
                Move = (integer) llList2String(SpecialMoves, -1);
                Type = (integer) llList2String(SpecialTypes, -1);

                Contents +=  GetCoord(Move) + " (" + GetSpecialTypeName(Type) + ")";
            }
            else
                Contents = "No Special Moves";
        }
        else if (channel == TEST_CHECK_RESULTS) {
            integer MoveToTest      = (integer) llList2String(CSVList, 0);
            integer SpecialMoveType = (integer) llList2String(CSVList, 1);

            Contents = GetCoord(MoveToTest);
            if (SpecialMoveType != NONE)
                Contents += " (" + GetSpecialTypeName(SpecialMoveType) + ")";

            if (channel == TEST_CHECK_RESULTS) {
                integer InCheck = (integer) llList2String(CSVList, 2);
                if (InCheck)
                    Contents += " Check";
                else
                    Contents += " No Check";
            }
        }
        else if (data == "")
            Contents = "N/A";
        else
            Contents = data;

        llSay(0, "Debug 2->" + llGetSubString(MessageName + ": " + Contents, 0, 254));
    }
}
