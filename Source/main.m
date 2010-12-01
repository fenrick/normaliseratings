//
//  main.m
//  NormaliseRatings
//
//  Created by Jolyon Suthers on 1/12/10.
//  Copyright 2010 Griffith University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"

int main (int argc, const char * argv[]) {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    if ( [iTunes isRunning] ) {
        NSLog(@"Current song is %@", [[iTunes currentTrack] name]);
    }

    [pool drain];
    return 0;
}

