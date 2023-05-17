///////////////////////////////////////////////////////////////////////////////////////////
// Player Manager Script
//
// Copyright (c) 2023 Gaius Tripsa
//
// This file is a plugin to XyChess. It provides new functionality for
// joining and leaving games.
///////////////////////////////////////////////////////////////////////////////////////////

string message = "Welcome to MadPea Battle For Wonderland Chess!\n\nBattle For Wonderland Chess uses a modified version of the XyChess system, licensed under the GNU General Public License v2.0 (GPLv2). Go to https://github.com/MadPea/xychess_2004 more information.\n\nMadPea Chess is for two human players. The scripted gameplay handles setting up the chess board, taking turns, and moving the pieces, including castling, pawn promotion, and capturing en passant. Importantly, the system does NOT detect when a king is in check, meaning that certain illegal moves are possible. Players themselves are responsible for recognizing and calling check and checkmate, and for avoiding illegal moves.";

default
{
    touch_end( integer count )
    {
        while ( count-- ) {
            key toucher = llDetectedKey( count );
            integer i = llGetInventoryNumber( INVENTORY_NOTECARD );

            llRegionSayTo( toucher, 0, message );

            while ( i-- ) {
                llGiveInventory( toucher, llGetInventoryName( INVENTORY_NOTECARD, i ) );
            }
        }
    }
}
