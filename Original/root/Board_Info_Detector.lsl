/////////////////////////////////////////////////////////////////////////////////////////////
// Board Info Detector Script
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
// Board Info Channels
integer REQUEST_BOARD_INFO  = 48000;
integer RETURN_BOARD_INFO   = 48001;

// Seperator to use instead of comma.
string  FIELD_SEPERATOR     = "~!~";
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
/////////// END GLOBAL VARIABLES ////////////

vector GetLocalPos() {
    // If this object is not linked, or if it is the
    // root object, just return ZERO_VECTOR.
    integer LinkNum = llGetLinkNumber();

    if (LinkNum == 0 || LinkNum == 1)
        return ZERO_VECTOR;

    // Otherwise return the local position.
    return llGetLocalPos();
}

// Tell all interested scripts info about the board.
SendBoardInfo() {
    llMessageLinked(LINK_SET, RETURN_BOARD_INFO, llDumpList2String([
                    llGetScale(), GetLocalPos()], FIELD_SEPERATOR), "");
}

default {
    state_entry() {
        SendBoardInfo();
    }

    link_message(integer sender, integer channel, string data, key id) {
        // Send board info in response to a request.
        if (channel == REQUEST_BOARD_INFO) {
            SendBoardInfo();
            return;
        }
    }

    changed(integer change) {
        if (change == CHANGED_SCALE || change == CHANGED_LINK) {
            // If the board size changes or linking changes, send an update.
            SendBoardInfo();
            return;
        }
    }
}
