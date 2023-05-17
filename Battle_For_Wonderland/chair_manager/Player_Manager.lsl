///////////////////////////////////////////////////////////////////////////////////////////
// Player Manager Script
//
// Copyright (c) 2023 Gaius Tripsa
//
// This file is a plugin to XyChess. It provides new functionality for
// joining and leaving games.
///////////////////////////////////////////////////////////////////////////////////////////

string gColor;
key gPlayer;

integer AVATAR_IN_CHAIR         = 8000;
integer NEW_GAME                = 16000;

// Color enumeration.
integer WHITE                   = 8;
integer BLACK                   = 16;

integer gPlayerLastSeen;

string gColorText;

integer gChannel;
integer gHandle;

integer RandomChannel()
{
    integer channel;

    do {
        integer i = 8;
        string digits = "0123456789ABCDEFG";
        string hex;

        while (i--) {
            integer index = (integer)llFrand( 16.0 );
            hex += llGetSubString(digits, index, index);
        }
        channel = (integer)("0x" + hex);
    } while ( ~llListFindList( [ PUBLIC_CHANNEL, DEBUG_CHANNEL ], [ channel ] ) );

    return channel;
}

default
{
    state_entry()
    {
        llPassTouches(PASS_IF_NOT_HANDLED);

        string primName = llGetLinkName( LINK_THIS );

        gColorText = llToLower(llList2String( llParseString2List( primName, [ " " ], [] ), 0 ));

        if ("white" == gColorText) {
            gColor = (string)WHITE;
            state no_player;
        } else if ( "black" == gColorText ) {
            gColor = (string)BLACK;
            state no_player;
        }
    }

    link_message( integer sender_num, integer num, string str, key id )
    {
        if (num == NEW_GAME) {
            gPlayer = NULL_KEY;
        }
    }

    on_rez( integer start_param)
    {
        llResetScript();
    }

    touch_end( integer num_detected )
    {
        key toucher = llDetectedKey(0);
        if (gPlayer) {

            gPlayer = NULL_KEY;
        } else {

            gPlayer = llDetectedKey(0);
        }

        llMessageLinked(LINK_SET, AVATAR_IN_CHAIR, gColor, gPlayer);
    }
}

state no_player
{
    state_entry()
    {
        gPlayer = NULL_KEY;
        llMessageLinked(LINK_SET, AVATAR_IN_CHAIR, gColor, gPlayer);
    }

    listen( integer channel, string name, key id, string message )
    {
        if (channel == gChannel) {
            if ("Yes" == message) {
                gPlayer = id;
                state player;
            }
        }
    }

    touch_end( integer num_detected )
    {
        key toucher = llDetectedKey( 0 );

        llListenRemove( gHandle );
        gChannel = RandomChannel();
        gHandle = llListen( gChannel, "", toucher, "" );

        llDialog( toucher, "Do you want to join a chess match playing the " + gColorText + " pieces?", [ "Yes", "No" ], gChannel );
    }
}

state player
{
    state_entry()
    {
        if ( gPlayer ) {
            llMessageLinked(LINK_SET, AVATAR_IN_CHAIR, gColor, gPlayer);
            llSetTimerEvent( 30.0 );
            gPlayerLastSeen = llGetUnixTime();

            llRegionSayTo( gPlayer, 0, "Welcome to the MadPea implementation of XyChess. Click the Info button to learn more. Click the Reset button to set up the board for a new match.");
        } else {
            state no_player;
        }
    }

    state_exit()
    {
        llSetTimerEvent( 0.0 );
    }

    listen( integer channel, string name, key id, string message )
    {
        if ( channel == gChannel ) {
            llListenRemove( gHandle );

            if ( "Yes" == message ) {
                state no_player;
            }
        }
    }

    timer()
    {
        if ( llGetAgentSize( gPlayer ) ) {
            gPlayerLastSeen = llGetUnixTime();
        } else if ( llGetUnixTime() - gPlayerLastSeen > 180 ) {
            state no_player;
        }
    }

    touch_end( integer num_detected )
    {
        key toucher = llDetectedKey( 0 );

        if (toucher != gPlayer) {
            llRegionSayTo( toucher, 0, "secondlife:///app/agent/" + (string)gPlayer + "/about is playing " + gColorText );
        } else {
            llListenRemove( gHandle );
            gChannel = RandomChannel();
            gHandle = llListen( gChannel, "", gPlayer, "" );

            llDialog( gPlayer, "You are playing " + gColorText + ". Do you want to leave the game?", [ "Yes", "No" ], gChannel );
        }
    }
}
