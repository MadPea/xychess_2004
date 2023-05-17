///////////////////////////////////////////////////////////////////////////////////////////
// Chair Manager Script
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
string  CHAIR_OBJECT    = "Chess Table - Chair";
string  CHAIR_DATA      = "Chair Data";

// Chair Commands.
string  PING            = "ping";
string  PONG            = "pong";
string  CHAIR_DIE       = "chr_die";
string  AVATAR_CHANGE   = "av_chng";

// Chair data line numbers.
integer WHITE_CHAIR_POSITION_LINE   = 1;
integer WHITE_CHAIR_ROTATION_LINE   = 3;
integer BLACK_CHAIR_POSITION_LINE   = 5;
integer BLACK_CHAIR_ROTATION_LINE   = 7;
integer NONE                        = -1;

// Interface message.
integer AVATAR_IN_CHAIR         = 8000;

// Seperator to use instead of comma.
string  FIELD_SEPERATOR = "~!~";
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
integer gChairChannel;
integer gCallback = -1;

// Chair data
vector      gWhiteChairPosition;
rotation    gWhiteChairRotation;
vector      gBlackChairPosition;
rotation    gBlackChairRotation;

// Current line number in notecard we are on.
integer     gLineNumber;
// Query ID to check against.
key         gQueryID;
/////////// END GLOBAL VARIABLES ////////////

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
    return llGetLinkKey(0);
}


RezChairs() {
    // First remove any callback if it exists.
    if (gCallback != NONE) {
        llListenRemove(gCallback);
        // Remove any chairs already out.
        llShout(gChairChannel, CHAIR_DIE);
    }

    // Create a new chair manager channel.
    gChairChannel = llRound(llFrand(1.0) * 1000000000) + 1;
    gCallback = llListen(gChairChannel, "", "", "");

    // Now rez new chairs.
    vector      RootPos = GetRootPos();
    rotation    RootRot = GetRootRot();

    llRezObject(CHAIR_OBJECT, RootPos + gWhiteChairPosition * RootRot,
                ZERO_VECTOR, gWhiteChairRotation * RootRot, gChairChannel * 2);
    llRezObject(CHAIR_OBJECT, RootPos + gBlackChairPosition * RootRot,
                ZERO_VECTOR, gBlackChairRotation * RootRot, gChairChannel * 2 + 1);
}

ReadChairData() {
    // Start the notecard reading process.
    gLineNumber = WHITE_CHAIR_POSITION_LINE;
    gQueryID = llGetNotecardLine(CHAIR_DATA, gLineNumber);
}

default {
    state_entry() {
        // Read the chair data from the notecard.
        ReadChairData();
    }

    on_rez(integer param) {
        // First remove any callback if it exists.
        if (gCallback != NONE) {
            llListenRemove(gCallback);
            gCallback = NONE;
        }

        // Read the chair data from the notecard.
        ReadChairData();
    }

    dataserver(key query_id, string data) {
        // Make sure this is the data we requested.
        if (query_id != gQueryID)
            return;

        // If this is EOF, give a warning.
        if (data == EOF) {
            llSay(0, "ERROR: " + CHAIR_DATA + " notecard is invalid!");
            return;
        }

        // Check which line number this is.
        if (gLineNumber == WHITE_CHAIR_POSITION_LINE) {
            gWhiteChairPosition = (vector) data;

            // Set up the next line.
            gLineNumber = WHITE_CHAIR_ROTATION_LINE;
        }
        else if (gLineNumber == WHITE_CHAIR_ROTATION_LINE) {
            gWhiteChairRotation = (rotation) data;

            // Set up the next line.
            gLineNumber = BLACK_CHAIR_POSITION_LINE;
        }
        else if (gLineNumber == BLACK_CHAIR_POSITION_LINE) {
            gBlackChairPosition = (vector) data;

            // Set up the next line.
            gLineNumber = BLACK_CHAIR_ROTATION_LINE;
        }
        else if (gLineNumber == BLACK_CHAIR_ROTATION_LINE) {
            gBlackChairRotation = (rotation) data;

            // No next line.
            gLineNumber = NONE;
        }
        else { // Unknown...
            llSay(0, "ERROR: Unknown line number.");
            return;
        }

        // Retrieve the next line.
        if (gLineNumber != NONE) {
            gQueryID = llGetNotecardLine(CHAIR_DATA, gLineNumber);
            return;
        }
        else {
            // We are done reading the notecard.
            RezChairs();
        }
    }

    listen(integer channel, string name, key id, string mesg) {
        if (channel == gChairChannel) {
            // Split up the mesg.
            list Parsed = llParseString2List(mesg, [FIELD_SEPERATOR], []);

            string Command = llList2String(Parsed, 0);

            // Check the command.
            if (Command == PING) {
                // Send out a pong.
                llShout(gChairChannel, llDumpList2String(
                            [PONG, GetRootPos(), GetRootRot(),
                             GetRootKey()], FIELD_SEPERATOR));
                return;
            }
            if (Command == AVATAR_CHANGE) {
                integer ChairColor  = (integer) llList2String(Parsed, 1);
                key     Avatar      = (key)     llList2String(Parsed, 2);

                // Tell the interface about the avatar change.
                llMessageLinked(LINK_SET, AVATAR_IN_CHAIR,
                                (string) ChairColor, Avatar);
                return;
            }
        }
    }

    // Re-read the notecard if inventory changes.
    changed(integer change) {
        if (change == CHANGED_INVENTORY) {
            ReadChairData();
        }
    }

    link_message(integer sender, integer channel, string data, key id) {
    }
}
