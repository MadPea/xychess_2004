///////////////////////////////////////////////////////////////////////////////////////////
// Chess Chair Script
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
vector  SIT_TARGET  = < -0.25, 0, 0.37>;
rotation SIT_ROT    = <0, 0, -1, 0>;

// Sensor setup.
float   SENSOR_REFRESH  = 30.0;

// Color enumeration.
integer WHITE           = 8;
integer BLACK           = 16;

// Chair Commands.
string  PING            = "ping";
string  PONG            = "pong";
string  CHAIR_DIE       = "chr_die";
string  AVATAR_CHANGE   = "av_chng";

// Seperator to use instead of comma.
string  FIELD_SEPERATOR = "~!~";
///////////// END CONSTANTS /////////////////

///////////// GLOBAL VARIABLES ///////////////
integer gChairColor;
integer gChairChannel;
vector      gLastTablePosition;
rotation    gLastTableRotation;
vector      gRelativePosition;
vector      gCurrentChairPosition;
/////////// END GLOBAL VARIABLES /////////////

MoveTo(vector target) {
    // This is where we want to be, regardless of
    // invalid positions.
    gCurrentChairPosition = target;

    // Use an invalid last position to start, so that
    // the distance is always greater than 0.001 to begin with.
    vector gLastPosition = <-1, -1, -1>;

    while (llVecDist(llGetPos(), target) > 0.001 &&
           llVecDist(llGetPos(), gLastPosition) > 0.001) {
        // Update the last position, in case we are trying
        // to move to an illegal position, such as below ground.
        gLastPosition = llGetPos();
        // Try to move in the correct direction.
        llSetPos(target);
    }
}

// Map 0, 1 to 8, 16
integer FromRezColor(integer rez_color) {
    return rez_color * 8 + 8;
}

default {
    state_entry() {
        // Set up the sit target.
        llSitTarget(SIT_TARGET, SIT_ROT);
    }

    on_rez(integer param) {
        // Don't do anything if rezzed from inventory.
        if (param == 0)
            return;

        // Split up the parameter.
        gChairColor     = FromRezColor(param % 2);
        gChairChannel   = param / 2;

        // Listen for chair commands.
        llListen(gChairChannel, "", "", "");

        // Ping the table to get its key for sensing.
        llShout(gChairChannel, PING);
    }

    sensor(integer num) {
        // Check to see if the table moved.
        vector Delta = llDetectedPos(0) - gLastTablePosition;

        if (llVecMag(Delta) > 0.01) {
            // Table moved.  Update our position.
            MoveTo(gCurrentChairPosition + Delta);
            gLastTablePosition = llDetectedPos(0);
        }

        // See if the table was rotated.
        if (llAngleBetween(llDetectedRot(0), gLastTableRotation) > 0.01) {
            gLastTableRotation = llDetectedRot(0);
            // Keep track of this for later use.
            vector OldDirToCenter = gCurrentChairPosition - gLastTablePosition;

            // Table was rotated.  Update our position.
            vector NewRelativePosition = gRelativePosition * gLastTableRotation;
            NewRelativePosition += gLastTablePosition;

            // Move to this position.
            MoveTo(NewRelativePosition);

            // Rotate to match the table.
            rotation Rot = llGetRot();
            vector NewDirToCenter = NewRelativePosition - gLastTablePosition;
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
        if (channel == gChairChannel) {
            // Split up the message.
            list Parsed = llParseString2List(mesg, [FIELD_SEPERATOR], []);

            string Command = llList2String(Parsed, 0);

            // Check the command.
            if (Command == PONG) {
                // Set the last position of table, so we can update our
                // position if it moves.
                gLastTablePosition  = (vector)  llList2String(Parsed, 1);
                gLastTableRotation  = (rotation)llList2String(Parsed, 2);
                key TableID         = (key)     llList2String(Parsed, 3);

                // Calculate our relative position from the table.
                gCurrentChairPosition = llGetPos();
                gRelativePosition   = gCurrentChairPosition - gLastTablePosition;
                // Undo the table's rotation to get the true relative position.
                rotation gRelativeRot = gLastTableRotation;
                gRelativeRot.s = -gRelativeRot.s;

                gRelativePosition *= gRelativeRot;

                // Start sensing for the table, to update our position and
                // see if the table goes away.
                llSensorRepeat("", TableID, PASSIVE | ACTIVE, 96.0, PI, SENSOR_REFRESH);
                return;
            }
            if (Command == CHAIR_DIE) {
                llDie();
                return;
            }
        }
    }

    changed(integer change) {
        // Check if someone sat down or stood up.
        if (change == CHANGED_LINK) {
            // Make sure chair channel was initialized.
            if (gChairChannel != 0)
                // Tell the table who is sitting here.
                llShout(gChairChannel, llDumpList2String(
                        [AVATAR_CHANGE, gChairColor, llAvatarOnSitTarget()],
                        FIELD_SEPERATOR));
        }
    }

}
