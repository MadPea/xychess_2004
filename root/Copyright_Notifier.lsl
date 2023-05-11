///////////////////////////////////////////////////////////////////////////////////////////
// Copyright Notifier
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
list BLURB = [  "XyChess version 1.0, Copyright (C) 2004 Xylor Baysklef, bUTTONpUSHER Jones, Lynnix Muse",
                "XyChess comes with ABSOLUTELY NO WARRANTY.",
                "This is free software, and you are welcome to redistribute it",
                "under certain conditions; type `show c' for details."  ];
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
key gOwner;
/////////// END GLOBAL VARIABLES ////////////

ShowBlurb() {
    integer i;
    for (i = 0; i < llGetListLength(BLURB); i++)
        llSay(0, llList2String(BLURB, i));
}

default {
    state_entry() {
        ShowBlurb();

        // Keep track of the owner to check for transfers of ownership.
        gOwner = llGetOwner();

        llListen(0, "", "", "show c");
    }

    on_rez(integer param) {
        if (llGetOwner() != gOwner)
            llResetScript();
    }

    listen(integer channel, string name, key id, string mesg) {
        llGiveInventory(id, "COPYING");
    }
}
