///////////////////////////////////////////////////////////////////////////////////////////
// Chess Piece Script
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
// Where to move to when selected.
vector  FLOAT_OFFSET    = <0, 0, 0.5>;

// Sensor setup.
float   SENSOR_REFRESH  = 30.0;

// How long to wait for setup info before
// asking for it again.
float   SETUP_TIMEOUT   = 1.0;
// How many times we can have a timeout
// while waiting for setup info before
// giving up.
integer MAX_TIMEOUT_ATTEMPTS    = 15;

// This is the seperator to use instead of comma.
string  FIELD_SEPERATOR = "~!~";

// Color enumeration.
integer WHITE           = 8;
integer BLACK           = 16;

// Game commands.
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

// Name of the notecard with the rez offset vector.
string  REZ_OFFSET_NOTECARD         = "Rez Offset";
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// Status flags.
integer gFloating   = FALSE;
integer gDead       = FALSE;
integer gRecruited  = FALSE;

// Board info.
vector  gBoardCenter;
vector  gBoardSize;
rotation    gBoardRot;
vector  gGraveyardStart;

// What color we are.
integer gColor;

key gBoardKey;
list gBoardInfo;

// Where we are.
integer gCol;
integer gRow;
// Original position this pieces goes to.
integer gOriginalCol;
integer gOriginalRow;
// Whether or not this piece was created as a recruitment.
integer gIsRecruitment;

// The channel to request setup info.
integer gSetupChannel;
// The callback for the setup listen.
integer gSetupCallback;
// How many times we have timed out waiting
// for setup info.
integer gNumTimesTimedOut;

// Used to follow the table around.
vector      gLastTablePosition;
rotation    gLastTableRotation;
vector      gLocalBoardPos;

// The offset to move after being rezzed.
vector      gRezOffset;

// This is our position, ignoring llGetPos problems.
vector      gCurrentPosition;

// This is the channel to listen for
// game messages.
integer gGameChannel;
/////////// END GLOBAL VARIABLES ////////////

MoveTo(vector target) {
    // This is where we want to be, regardless of
    // invalid positions.
    gCurrentPosition = target;

    // Use an invalid last position to start, so that
    // the distance is always greater than 0.001 to begin with.
    vector LastPosition = <-1, -1, -1>;

    while (llVecDist(llGetPos(), target) > 0.001 &&
           llVecDist(llGetPos(), LastPosition) > 0.001) {
        // Update the last position, in case we are trying
        // to move to an illegal position, such as below ground.
        LastPosition = llGetPos();
        // Try to move in the correct direction.
        llSetPos(target);
    }
}

// Calculate the position to move to, to
// place the pieces on a given board position.
// (row and col are 0-based)
vector GetBoardPosition(integer row, integer col) {
    // First calculate the x/y position based on the
    // board info.
    vector GridSquareSize = gBoardSize / 8.0;
    gLocalBoardPos = -GridSquareSize * 3.5;

    gLocalBoardPos.y += row * GridSquareSize.y;
    gLocalBoardPos.x += col * GridSquareSize.x;

    // Rotate the board position based on the table rotation.
    vector BoardPosition = gLocalBoardPos * gBoardRot;
    BoardPosition       += gBoardCenter;

    // Use the current position as our z-position.
    BoardPosition.z = gCurrentPosition.z;

    return BoardPosition;
}

// Calculate the position to move to, to
// place the pieces on a graveyard slot
// (slot is 0-based)
vector GetGraveyardPosition(integer slot) {
    // Calculate graveyard row / col info.
    integer Row = slot % 8;
    integer Col = slot / 8;

    // Calculate the position in the graveyard.
    vector GridSquareSize = gBoardSize / 8.0;

    //gLocalBoardPos.x = GridSquareSize.x * 5;
    //gLocalBoardPos.y = -GridSquareSize.y * 3.5;
    gLocalBoardPos    = gGraveyardStart;
    gLocalBoardPos.y += Row * GridSquareSize.y;
    gLocalBoardPos.x += Col * GridSquareSize.x;

    // The graveyards are different for each color.
    if (gColor == BLACK) {
        // Rotate the graveyard position to the black
        // graveyard.
        gLocalBoardPos *= <0, 0, -1, 0>; // 180 deg about z axis
    }

    // Rotate the position based on the table rotation.
    vector GraveyardPosition = gLocalBoardPos * gBoardRot;
    GraveyardPosition       += gBoardCenter;

    // Use the current position as our z-position.
    GraveyardPosition.z = gCurrentPosition.z;

    return GraveyardPosition;
}

StartFloating() {
    if (gFloating)
        return;

    MoveTo(gCurrentPosition + FLOAT_OFFSET);

    gFloating = TRUE;
}

StopFloating() {
    if (!gFloating)
        return;

    llParticleSystem([]);
    MoveTo(gCurrentPosition - FLOAT_OFFSET);
    gFloating = FALSE;
}

// Map 0, 1 to 8, 16
integer FromRezColor(integer rez_color) {
    return rez_color * 8 + 8;
}

vector CalcOffset(vector pieceSize, vector boardSize) {
    // We want to align the bottom of the piece with the bottom of
    // the invisible board prim
    return <0.0, 0.0, (pieceSize.z - boardSize.z) / 2.0>;
}

vector CalcAdjustedHeight(vector curPos, vector boardPos, vector offset) {
    return <curPos.x, curPos.y, boardPos.z + offset.z>;
}

SetBoardInfo() {
    gBoardInfo = llGetObjectDetails(gBoardKey, [OBJECT_POS, OBJECT_SCALE, OBJECT_ROT]);

    gBoardCenter = llList2Vector(gBoardInfo, 0);
    gBoardSize   = llList2Vector(gBoardInfo, 1);
    gBoardRot    = llList2Rot(gBoardInfo, 2);
}

default {
    on_rez(integer param) {
        // Don't do anything if rezzed from inventory.
        if (param == 0) {
            llResetScript();
            return;
        }

        // Otherwise split up the parameter into
        // a setup channel, and piece info..
        integer PieceInfo   = param % 256;
        gSetupChannel       = param / 256;

        // Split up the piece info.
        gIsRecruitment      = PieceInfo / 128;
        PieceInfo           = PieceInfo % 128;
        gColor              = FromRezColor(PieceInfo / 64);
        integer BoardPos    = PieceInfo % 64;

        // Split up the board position.
        gRow = BoardPos / 8;
        gCol = BoardPos % 8;

        // Save this information for if the board is reset.
        gOriginalRow    = gRow;
        gOriginalCol    = gCol;

        // Guess at the table info..
        gBoardKey = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
        SetBoardInfo();

        gRezOffset = CalcOffset(llGetScale(), gBoardSize);

        // Set our position, with rez correction.
        gCurrentPosition = CalcAdjustedHeight(llGetPos(), gBoardCenter, gRezOffset);

        // Move to the board position.
        MoveTo(GetBoardPosition(gRow, gCol));

        // Check for a bogus setup channel.
        if (gSetupChannel == 0)
            return;

        // Listen for setup info.
        gSetupCallback = llListen(gSetupChannel + 1, "", "", "");

        // Since all pieces need setup info, only a few
        // need to request setup info for all.
        // Wait for setup, and if we time out then
        // request setup info on behalf of other pieces
        // as well.
        llSetTimerEvent(SETUP_TIMEOUT);
        // Reset the timeout counter.
        gNumTimesTimedOut = 0;

    }

    timer() {
        // No setup message was received.
        // Have we already timed out too many times?
        if (gNumTimesTimedOut++ >= MAX_TIMEOUT_ATTEMPTS) {
            // Just die.
            llDie();
            return;
        }

        // Otherwise request setup.
        llShout(gSetupChannel, "request");
    }

    sensor(integer num) {
        // Check to see if the table moved.
        vector curBoardPos = llList2Vector(llGetObjectDetails(gBoardKey, [OBJECT_POS]), 0);
        rotation curBoardRot = llList2Rot(llGetObjectDetails(gBoardKey, [OBJECT_ROT]), 0);

        vector Delta = curBoardPos - gLastTablePosition;

        if (llVecMag(Delta) > 0.01) {
            SetBoardInfo();
            // Table moved.  Update our position.
            MoveTo(GetBoardPosition(gRow, gCol));
            // MoveTo(gCurrentPosition + Delta);
            gLastTablePosition = curBoardPos;

            // Update the center of the table.
            // gBoardCenter += Delta;
        }

        // See if the table was rotated.
        if (llAngleBetween(curBoardRot, gLastTableRotation) > 0.01) {
            gLastTableRotation = curBoardRot;
            // Keep track of this for later use.
            vector OldDirToCenter = gCurrentPosition - gBoardCenter;

            // Table was rotated.  Update our position.
            gBoardRot = curBoardRot;
            vector NewBoardPosition = gLocalBoardPos * gBoardRot;
            NewBoardPosition       += gBoardCenter;

            // Use the current position as our z-position.
            NewBoardPosition.z = gCurrentPosition.z;

            MoveTo(GetBoardPosition(gRow, gCol));
            // MoveTo(NewBoardPosition);

            // Rotate to match the table.
            rotation Rot = llGetRot();
            vector NewDirToCenter = NewBoardPosition - gBoardCenter;
            // Ignore z values.
            OldDirToCenter.z = 0;
            NewDirToCenter.z = 0;
            Rot *= llRotBetween(OldDirToCenter, NewDirToCenter);
            llSetRot(Rot);
        }
    }

    no_sensor() {
        // Table is gone.  Die.
        llDie();
    }

    listen(integer channel, string name, key id, string mesg) {
        if (channel == gSetupChannel + 1) {
            // We only need to listen for this once,
            // so remove the listen, and the timeout.
            llListenRemove(gSetupCallback);
            llSetTimerEvent(0.0);

            // Split up the mesg into useful info.
            list Parsed = llParseString2List(mesg, [FIELD_SEPERATOR], []);

            SetBoardInfo();

            gLastTablePosition  = gBoardCenter; // llList2String(Parsed, 0);
            gGraveyardStart     = (vector)  llList2String(Parsed, 3);
            gGameChannel        = (integer) llList2String(Parsed, 4);
            key TableID         = (key)     llList2String(Parsed, 5);

            // Update the last known info about the table.
            gLastTableRotation  = gBoardRot;

            // Remove the z component of the board size.
            gBoardSize.z = 0;

            // Start listening for game messages.
            llListen(gGameChannel, "", "", "");

            // Start sensing for the table, to update our position and
            // see if the table goes away.
            llSensorRepeat("", TableID, PASSIVE | ACTIVE, 96.0, PI, SENSOR_REFRESH);
            return;
        }
        if (channel == gGameChannel) {
            // Split up the mesg into useful info.
            list Parsed = llParseString2List(mesg, [FIELD_SEPERATOR], []);

            string  Command =           llList2String(Parsed, 0);
            integer Row     = (integer) llList2String(Parsed, 1);
            integer Col     = (integer) llList2String(Parsed, 2);

            // Check for commands that concern all pieces first.
            if (Command == MSG_CLEAR_BOARD) {
                llDie();
                return;
            }
            if (Command == MSG_RESET_BOARD) {
                // If this was a recruited piece, just die.  The original pawn
                // will be recreated.
                if (gIsRecruitment)
                    llDie();

                // If we were floating, stop.
                StopFloating();
                // We are no longer dead.
                gDead = FALSE;
                // Move back to our original location.
                SetBoardInfo();
                gRezOffset = CalcOffset(llGetScale(), gBoardSize);
                gCurrentPosition = CalcAdjustedHeight(llGetPos(), gBoardCenter, gRezOffset);
                gRow = gOriginalRow;
                gCol = gOriginalCol;
                MoveTo(GetBoardPosition(gRow, gCol));
                return;
            }

            // See if this message concerns us.
            if (Row != gRow ||
                Col != gCol ||
                gDead)
                return;

            // Determine which command this is.
            if (Command == MSG_CHANGE_BOARD_POSITION) {
                // Move to the given position.
                gRow     = (integer) llList2String(Parsed, 3);
                gCol     = (integer) llList2String(Parsed, 4);

                MoveTo(GetBoardPosition(gRow, gCol));
                StopFloating();
                return;
            }
            if (Command == MSG_START_FLOATING) {
                StartFloating();
                return;
            }
            if (Command == MSG_STOP_FLOATING) {
                StopFloating();
                return;
            }
            if (Command == MSG_KILL_PIECE) {
                gDead = TRUE;
                // Position in the graveyard to move to.
                integer GraveyardSlot   = (integer) llList2String(Parsed, 3);
                MoveTo(GetGraveyardPosition(GraveyardSlot));
                return;
            }
            if (Command == MSG_REMOVE_PIECE) {
                // Just die, this is probably a pawn being recruited.
                llDie();
                return;
            }
            if (Command == MSG_RECRUIT_PIECE) {
                // Before we die, tell the piece manager our original settings, to
                // it can replace us on reset.
                llShout(gGameChannel, llDumpList2String(
                            [MSG_RECRUIT_INFO, gOriginalRow, gOriginalCol], FIELD_SEPERATOR));
                // Now die, to make room for the new piece being recruited.
                llDie();
                return;
            }
            return;
        }
    }

    touch_start(integer num_detected) {
        // If gGameChannel is 0, then we haven't
        // been initialized yet.
        if (gGameChannel == 0)
            return;

        // If we are dead, don't respond to touches.
        if (gDead)
            return;

        // Tell the game about this touch.
        llShout(gGameChannel, llDumpList2String(
                            [MSG_PIECE_TOUCHED, gColor,
                             gRow, gCol, llDetectedKey(0)],
                            FIELD_SEPERATOR));
    }
}
