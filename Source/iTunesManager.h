//
//  iTunesManager.h
//  NormaliseRatings
//
//  Created by Jolyon Suthers on 1/12/10.
//  Copyright 2010 Griffith University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"

@interface iTunesManager : NSObject {
@private
    iTunesApplication *iTunes;
}

@property(retain) iTunesApplication *iTunes;

- (void) loadMusicPlaylist;
- (iTunesSource *) findSource:(NSString *)sourceName;
- (iTunesPlaylist *) findPlaylistFromLibrary:(NSString *) libraryName: (NSString *) playlistName;

@end
