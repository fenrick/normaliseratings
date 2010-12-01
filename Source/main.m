//
//  main.m
//  NormaliseRatings
//
//  Created by Jolyon Suthers on 1/12/10.
//  Copyright 2010 Griffith University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"
#import "iTunesManager.h"

int main (int argc, const char * argv[]) {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    iTunesManager *iTunesMgr = [[[iTunesManager alloc] init] autorelease];
    
    // confirm itunes it active
    if ( [[iTunesMgr iTunes] isRunning] ) {
        [iTunesMgr loadMusicPlaylist];
    }

    [pool drain];
    return 0;
}