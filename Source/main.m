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
    
    // confirm itunes it active
    if ( [iTunes isRunning] ) {
        // set fixed indexing
        bool existingFixedIndexing;
        existingFixedIndexing = [iTunes fixedIndexing];
        [iTunes setFixedIndexing:true];
        
        
        
        
        // restore fixed indexing
        [iTunes setFixedIndexing:existingFixedIndexing];
    }

    [pool drain];
    return 0;
}

