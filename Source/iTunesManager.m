//
//  iTunesManager.m
//  NormaliseRatings
//
//  Created by Jolyon Suthers on 1/12/10.
//  Copyright 2010 Griffith University. All rights reserved.
//

#import "iTunesManager.h"


@implementation iTunesManager

@synthesize iTunes;

- (id) init {
    if (!(self = [super init]))
        return nil;
    
    iTunesApplication *iTunesApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    [self setITunes:iTunesApplication];
    
    return self;
}

- (void) dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

- (void) loadMusicPlaylist {
    // Music playlist is within the Library source.
    iTunesPlaylist *musicPlaylist = [self findPlaylistFromLibrary:@"Library" :@"Music"];
}
                
- (iTunesPlaylist *) findPlaylistFromLibrary:(NSString *) libraryName: (NSString *) playlistName {
    // loop through all playlists for source
    SBElementArray *playlists = [[self findSource:libraryName] userPlaylists];
    
    if ([playlists count] > 0) {
        for (iTunesPlaylist *playlist in playlists) {
            if([[playlist name] isEqualToString:playlistName]) {
                return playlist;
            }
        }
    }
    return nil;
}
   

- (iTunesSource *) findSource:(NSString *)sourceName {
    // List of all sources
    SBElementArray *sources = [iTunes sources];
    
    if ([sources count] > 0) {
        for (iTunesSource *source in sources) {
            if ([[source name] isEqualToString:sourceName]) {
                return source;
            }
        }
    }
    return nil;
}

@end
