///////////////////////////////////////////////////////////////////////////////////////////
// Piece Manager Script
//
// Copyright (c) 2004 Xylor Baysklef
// Modified by Gaius Tripsa for MadPea Productions, May 2023
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
// Color enumeration.
integer WHITE           = 8;
integer BLACK           = 16;

// Piece enumeration.
integer PAWN            = 0;
integer KNIGHT          = 1;
integer BISHOP          = 2;
integer ROOK            = 3;
integer QUEEN           = 4;
integer KING            = 5;

// Graveyard scaling values.
vector  GRAVEYARD_SCALING   = <5.125, -3.5, 0.005>;

// Chess pieces info.
rotation    PIECE_ROT   =  <0, 0, 0, 1>;

// Piece names list.
list    PIECE_NAMES     = [ "Pawn", "Knight",
                            "Bishop", "Rook",
                            "Queen", "King" ];

list    LAST_RANK_SETUP = [ ROOK, KNIGHT, BISHOP, QUEEN,
                            KING, BISHOP, KNIGHT, ROOK ];

// Use the same valid toucher as the square buttons.
integer SET_VALID_TOUCHER   = 9003;

// Interface messages.
integer SQUARE_TOUCHED          = 8001;
integer RECRUIT_PAWN            = 8012;
integer DONE_RECRUITING         = 8013;

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

// Piece Interface Messages.
string  MSG_CHANGE_BOARD_POSITION   = "chg_pos";
string  MSG_START_FLOATING          = "bgn_flt";
string  MSG_STOP_FLOATING           = "end_flt";
string  MSG_PIECE_TOUCHED           = "pce_tch";
string  MSG_CLEAR_BOARD             = "clr_brd";
string  MSG_KILL_PIECE              = "kil_pce";
string  MSG_REMOVE_PIECE            = "rmv_pce";
string  MSG_RESET_BOARD             = "reset";
string  MSG_RECRUIT_PIECE           = "recruit";
string  MSG_RECRUIT_INFO            = "recruit_info";

// Board Info Channels
integer REQUEST_BOARD_INFO  = 48000;
integer RETURN_BOARD_INFO   = 48001;

// This is the seperator to use instead of comma.
string  FIELD_SEPERATOR = "~!~";

// Misc Constant
integer NONE    = -1;
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// Channel variables.
integer gGameChannel = NONE;
integer gGameChannelCallback;
integer gSetupChannel = NONE;
integer gSetupAnswerChannel;
integer gSetupChannelCallback;

// Graveyard Slots
integer gWhiteGraveyardSlot;
integer gBlackGraveyardSlot;

// The current valid toucher.
key     gValidToucher;

// Recruitment info.
integer gPawnToRecruit;
integer gPawnColor;

// This is the size and position of the board.
vector  gBoardSize;
vector  gBoardPos;
rotation gBoardRot;

// Whether or not the pieces are rezzed.
integer gPiecesRezzed;
// Which pieces need to be recreated on setup.
list    gPiecesToRecreate;
/////////// END GLOBAL VARIABLES ////////////

Init() {
    // First remove any callbacks if they exists.
    if (gGameChannelCallback != NONE) {
        llListenRemove(gGameChannelCallback);
    }

    if (gSetupChannelCallback != NONE)
        llListenRemove(gSetupChannelCallback);

    // Create a new game channel.
    gGameChannel         = llRound(llFrand(1.0) * 7812500) + 50;
    gGameChannelCallback = llListen(gGameChannel, "", "", "");

    // Create a new setup channel.
    gSetupChannel = gGameChannel - 10;
    gSetupAnswerChannel = gSetupChannel + 1;
    gSetupChannelCallback = llListen(gSetupChannel, "", "", "");

    // The pieces are not out yet.
    gPiecesRezzed = FALSE;
    // Nothing needs to be recreated.
    gPiecesToRecreate  = [];
}


//////////// Utility functions //////////////
integer GetRow(integer index) {
    return index / 8;
}

integer GetCol(integer index) {
    return index % 8;
}

integer GetIndex(integer row, integer col) {
    return row * 8 + col;
}

// Map 8, 16 to 0, 1
integer ToRezColor(integer color) {
    return (color - 8) / 8;
}
////////// End Utility functions /////////////

integer GetBoardLink() {
    integer i = llGetNumberOfPrims();

    do {
        if ("Board" == llGetLinkName(i)) {
            return i;
        }
    } while (i--);

    return 257;
}

vector GetGraveyardStart() {
    return <GRAVEYARD_SCALING.x * gBoardSize.x / 8.0,
            GRAVEYARD_SCALING.y * gBoardSize.y / 8.0,
            GRAVEYARD_SCALING.z>;
}

vector GetRootPos() {
    // If this object is not linked, or if it is the
    // root object, just return llGetPos
    integer LinkNum = llGetLinkNumber();

    if (LinkNum == 0 || LinkNum == 1)
        return llGetPos();

    // Otherwise take local position into account.
    return llGetPos() - llGetLocalPos();
}

rotation GetRootRot() {
    // If this object is not linked, or if it is the
    // root object, just return llGetRot
    integer LinkNum = llGetLinkNumber();

    if (LinkNum == 0 || LinkNum == 1)
        return llGetRot();

    // Otherwise take local rotation into account.

    // This is the rotation of this object with the
    // root object's rotation as the reference frame.
    rotation LocalRot = llGetLocalRot();
    // This uses the global coord system as the
    // reference frame.
    rotation GlobalRot = llGetRot();

    // Reverse the local rotation, so we can undo it.
    LocalRot.s = -LocalRot.s;

    // Convert from local rotation to just root rotation.
    rotation RootRot = LocalRot * GlobalRot;

    // Make the sign match (mathematically, this isn't necessary,
    // but it makes the rotations look the same when printed out).
    RootRot = -RootRot;

    return RootRot;
}

key GetRootKey() {
    // Just return link number 0's key.
    integer root = (llGetNumberOfPrims() > 1);
    return llGetLinkKey(root);
}


RezPiece(integer color, integer type, integer index, integer recruiting) {
    string PieceName = llList2String(PIECE_NAMES, type);
    rotation rot = PIECE_ROT;

    if (color == WHITE) {
        if ("Pawn" == PieceName) PieceName += " " + (string)(index - 8);
        if ("Knight" == PieceName) rot *= <0.00000, 0.00000, -0.70711, 0.70711>;
        PieceName = "White " + PieceName;
    } else {
        if ("Pawn" == PieceName) PieceName += " " + (string)(index - 48);
        if ("Knight" == PieceName) rot *= <0.00000, 0.00000, -0.70711, 0.70711>;
        PieceName = "Black " + PieceName;
        rot *= <0, 0, 1, 0>;
    }

    integer Param = gSetupChannel * 256 + recruiting * 128 +
                    ToRezColor(color) * 64 + index;

    llRezObject(PieceName, gBoardPos + <0, 0, gBoardSize.z / 2.0>, ZERO_VECTOR,
                rot * GetRootRot(), Param);
}

SetupBoard() {
    // Rez the initial board setup.
    integer boardLink = GetBoardLink();
    list boardInfo = llGetLinkPrimitiveParams(boardLink, [PRIM_POSITION, PRIM_SIZE, PRIM_ROTATION]);

    gBoardPos    = llList2Vector(boardInfo, 0);
    gBoardSize   = llList2Vector(boardInfo, 1);
    gBoardRot    = llList2Rot(boardInfo, 2);

    integer i;
    integer Type;
    for (i = 0; i < 8; i++) {
        Type = llList2Integer(LAST_RANK_SETUP, i);
        RezPiece(WHITE, Type, i, FALSE);
        RezPiece(BLACK, Type, 56 + i, FALSE);
        RezPiece(WHITE, PAWN, 8 + i, FALSE);
        RezPiece(BLACK, PAWN, 48 + i, FALSE);
    }
    // The pieces are now rezzed.
    gPiecesRezzed = TRUE;
    // Nothing needs to be recreated.
    gPiecesToRecreate  = [];
}

ResetBoard() {
    // Reset the board.
    llShout(gGameChannel, MSG_RESET_BOARD);
    // Recreate all pieces that were recruited.
    integer i;
    integer NumPieces = llGetListLength(gPiecesToRecreate);
    integer Piece;
    integer Color;
    for (i = 0; i < NumPieces; i++) {
        Piece = llList2Integer(gPiecesToRecreate, i);
        // Check which half of the board this piece is on, to get color.
        if (Piece > 32)
            Color = BLACK;
        else
            Color = WHITE;

        // Recreate this pawn.
        RezPiece(Color, PAWN, Piece, FALSE);
    }

    // We no longer need to recreate these pieces.
    gPiecesToRecreate = [];
}

default {
    state_entry() {
        Init();
        // Ask for board information.
        llMessageLinked(LINK_SET, REQUEST_BOARD_INFO, "", "");
    }

    on_rez(integer param) {
        Init();
    }

    listen(integer channel, string name, key id, string mesg) {
        if (channel == gSetupChannel) {
            integer boardLink = GetBoardLink();
            list boardInfo = llGetLinkPrimitiveParams(boardLink, [PRIM_POSITION, PRIM_SIZE, PRIM_ROTATION]);

            gBoardPos    = llList2Vector(boardInfo, 0);
            gBoardSize   = llList2Vector(boardInfo, 1);
            gBoardRot    = llList2Rot(boardInfo, 2);

            llShout(gSetupAnswerChannel, llDumpList2String(
                [gBoardPos, gBoardRot,
                 gBoardSize, GetGraveyardStart(), gGameChannel, GetRootKey()],
                 FIELD_SEPERATOR));
            return;
        }
        if (channel == gGameChannel) {
            // Split up the message.
            list Parsed = llParseString2List(mesg, [FIELD_SEPERATOR], []);

            string Command = llList2String(Parsed, 0);

            // Check the command.
            if (Command == MSG_PIECE_TOUCHED) {
                // Extract touch info.
                integer Color   = (integer) llList2String(Parsed, 1);
                integer Row     = (integer) llList2String(Parsed, 2);
                integer Col     = (integer) llList2String(Parsed, 3);
                key     Toucher = (key)     llList2String(Parsed, 4);

                // Make sure this was from the current valid toucher.
                if (Toucher != gValidToucher)
                    return;

                integer Piece   = GetIndex(Row, Col);

                // Tell the interface about this touch.
                llMessageLinked(LINK_SET, SQUARE_TOUCHED,
                            (string) Piece, Toucher);
            }
            else if (Command == MSG_RECRUIT_INFO) {
                // Add this piece's original info into the list of pieces to re-create on setup.
                integer Row     = (integer) llList2String(Parsed, 1);
                integer Col     = (integer) llList2String(Parsed, 2);
                gPiecesToRecreate += [GetIndex(Row, Col)];
            }
            return;
        }
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel == RETURN_BOARD_INFO) {
            // Set the board size and local position within the set.
            list Parsed = llParseString2List(data, [FIELD_SEPERATOR], []);
            gBoardSize  = (vector)  llList2String(Parsed, 0);
            gBoardPos   = (vector)  llList2String(Parsed, 1);
            return;
        }
        if (channel == SET_VALID_TOUCHER) {
            // Only the valid toucher can activate a piece.
            gValidToucher = id;
            return;
        }
        if (channel == CLEAR_BOARD) {
            // Clear the board.
            llShout(gGameChannel, MSG_CLEAR_BOARD);
            gPiecesRezzed = FALSE;
            return;
        }
        if (channel == SETUP_BOARD) {
            // Reset graveyard slots.
            gWhiteGraveyardSlot = 0;
            gBlackGraveyardSlot = 0;

            // See if we need to create the pieces, or reuse them.
            if (gPiecesRezzed) {
                // Reuse the current pieces.
                ResetBoard();
            }
            else { // !gPiecesRezzed.
                // Create the pieces.
                SetupBoard();
            }

            return;
        }
        if (channel == ADD_PIECE) {
            // Rez the requested piece at the correct position.

            // Split up the data.
            list Parsed = llParseString2List(data, [FIELD_SEPERATOR], []);
            integer Color   = (integer) llList2String(Parsed, 0);
            integer Type    = (integer) llList2String(Parsed, 1);
            integer Row     = (integer) llList2String(Parsed, 2);
            integer Col     = (integer) llList2String(Parsed, 3);

            RezPiece(Color, Type, GetIndex(Row, Col), FALSE);
            return;
        }
        if (channel == REMOVE_PIECE) {
            integer Piece = (integer) data;
            // Remove the piece from the board.
            llShout(gGameChannel, llDumpList2String(
                            [MSG_REMOVE_PIECE, GetRow(Piece), GetCol(Piece)],
                            FIELD_SEPERATOR));
            return;
        }
        if (channel == KILL_PIECE) {
            // Split up the message.
            list Parsed = llParseString2List(data, [FIELD_SEPERATOR], []);
            integer Piece   = (integer) llList2String(Parsed, 0);
            integer Color   = (integer) llList2String(Parsed, 1);
            // Kill the piece and place in the next graveyard slot.
            integer Slot;
            if (Color == WHITE)
                Slot = gWhiteGraveyardSlot++;
            else
                Slot = gBlackGraveyardSlot++;

            llShout(gGameChannel, llDumpList2String(
                            [MSG_KILL_PIECE, GetRow(Piece), GetCol(Piece), Slot],
                            FIELD_SEPERATOR));
            return;
        }
        if (channel == MOVE_PIECE) {
            // Split up the message.
            list Parsed = llCSV2List(data);
            integer PieceToMove = (integer) llList2String(Parsed, 0);
            integer Position    = (integer) llList2String(Parsed, 1);

            // Tell the piece to move.
            llShout(gGameChannel, llDumpList2String(
                            [MSG_CHANGE_BOARD_POSITION,
                             GetRow(PieceToMove), GetCol(PieceToMove),
                             GetRow(Position), GetCol(Position)], FIELD_SEPERATOR));

            return;
        }
        if (channel == SELECT_PIECE) {
            integer Piece = (integer) data;
            // Tell the piece to float.
            llShout(gGameChannel, llDumpList2String(
                            [MSG_START_FLOATING,
                             GetRow(Piece), GetCol(Piece)], FIELD_SEPERATOR));
            return;
        }
        if (channel == DESELECT_PIECE) {
            integer Piece = (integer) data;
            // Tell the piece to stop floating.
            llShout(gGameChannel, llDumpList2String(
                            [MSG_STOP_FLOATING,
                             GetRow(Piece), GetCol(Piece)], FIELD_SEPERATOR));
            return;
        }
        if (channel == RECRUIT_PAWN) {
            list Parsed = llCSV2List(data);
            gPawnToRecruit  = (integer) llList2String(Parsed, 0);
            gPawnColor      = (integer) llList2String(Parsed, 1);

            // Give the dialog.
            llMessageLinked(LINK_SET, DIALOG_RECRUIT_PAWN, (string) gPawnColor, "");
            return;
        }
        if (channel == DIALOG_RECRUIT_PAWN_DONE) {
            integer Type = (integer) data;
            // Tell the game which piece we recruited to.
            llMessageLinked(LINK_SET, DONE_RECRUITING, (string) Type, "");

            // Recruit the pawn on the board (this causes it to send back its original location,
            // so we can 'fix' the new pawn on board setup).
            llShout(gGameChannel, llDumpList2String(
                            [MSG_RECRUIT_PIECE, GetRow(gPawnToRecruit), GetCol(gPawnToRecruit)],
                            FIELD_SEPERATOR));

            // Create a new piece of the new type at the same position.
            RezPiece(gPawnColor, Type, gPawnToRecruit, TRUE);
            return;
        }
    }
}
