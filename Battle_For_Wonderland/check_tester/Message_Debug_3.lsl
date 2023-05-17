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

// Check channel bases.
integer CHECK_FOR_PAWNS_OR_KING     = 11200;
integer CHECK_FOR_ROOKS_OR_QUEEN    = 11300;
integer CHECK_FOR_BISHOPS_OR_QUEEN  = 11400;
integer CHECK_FOR_KNIGHTS           = 11500;
// Check return channel base.
integer CHECK_FOR_PIECE_RETURN      = 11600;

// How many check types we have.
integer NUM_CHECK_TYPES = 4;


string  RANK_NAMES  = "abcdefgh";

// This is the seperator to use instead of comma.
string  FIELD_SEPERATOR = "~!~";

///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
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
    }

    link_message(integer sender, integer channel, string data, key id) {
        string MessageName;
        string Contents;
        // See if this message falls into specific categories.

        if (channel >= CHECK_FOR_PIECE_RETURN && channel < CHECK_FOR_PIECE_RETURN + 100) {
            MessageName = "CHECK_FOR_PIECE_RETURN (" +
                            (string) (channel - CHECK_FOR_PIECE_RETURN) + ")";

            integer InCheck = (integer) data;
            if (InCheck)
                Contents = "Check";
            else
                Contents = "No Check";
        }
        else {
            if (channel >= CHECK_FOR_PAWNS_OR_KING && channel < CHECK_FOR_ROOKS_OR_QUEEN) {
                MessageName = "CHECK_FOR_PAWNS_OR_KING (" +
                                (string) (channel - CHECK_FOR_PAWNS_OR_KING) + ")";
            }
            else if (channel >= CHECK_FOR_ROOKS_OR_QUEEN && channel < CHECK_FOR_BISHOPS_OR_QUEEN) {
                MessageName = "CHECK_FOR_ROOKS_OR_QUEEN (" +
                                (string) (channel - CHECK_FOR_ROOKS_OR_QUEEN) + ")";
            }
            else if (channel >= CHECK_FOR_BISHOPS_OR_QUEEN && channel < CHECK_FOR_KNIGHTS) {
                MessageName = "CHECK_FOR_BISHOPS_OR_QUEEN (" +
                                (string) (channel - CHECK_FOR_BISHOPS_OR_QUEEN) + ")";
            }
            else if (channel >= CHECK_FOR_KNIGHTS && channel < CHECK_FOR_PIECE_RETURN) {
                MessageName = "CHECK_FOR_KNIGHTS (" +
                                (string) (channel - CHECK_FOR_KNIGHTS) + ")";
            }
            else
                return;

            list CSVList = llCSV2List(data);
            integer Color                  = (integer) llList2String(CSVList, 0);
            integer Row                    = (integer) llList2String(CSVList, 1);
            integer Col                    = (integer) llList2String(CSVList, 2);

            Contents = GetColorName(Color) + " King at " + GetCoordRowCol(Row, Col);
        }

        llSay(0, "Debug 3->" + llGetSubString(MessageName + ": " + Contents, 0, 254));
    }
}
