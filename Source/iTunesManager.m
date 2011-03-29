//
//  iTunesManager.m
//  NormaliseRatings
//
//  Created by Jolyon Suthers on 1/12/10.
//  Copyright 2010 Griffith University. All rights reserved.
//

#import "iTunesManager.h"
#import <math.h>

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

- (void) normaliseMusicRatings {
    // Music playlist is within the Library source.
    iTunesPlaylist *musicPlaylist = [self findPlaylistFromLibrary:@"Library" :@"Music"];
    
    // track list
    SBElementArray *tracks = [musicPlaylist tracks];
    
    if ([tracks count] == 0) {
        return;
    }
    
    int s0 = [tracks count];
    
    bool byPlayCount = true;
    double s1_play = 0;
    double s2_play = 0;
    double mean_play = 0;
    double stdDev_play = 0;
    
    bool bySkipCount = true;
    double s1_skip = 0;
    double s2_skip = 0;
    double mean_skip = 0;
    double stdDev_skip = 0;
    
    bool varyByTime = true;
    NSDate *play_first_date = [NSDate dateWithNaturalLanguageString:@"31 December 2100 12:00:00 PM"];
    NSDate *play_last_date = [NSDate dateWithNaturalLanguageString:@"01 January 2000 12:00:00 AM"];
    double play_max_interval = 0;
    NSDate *skip_first_date = [NSDate dateWithNaturalLanguageString:@"31 December 2100 12:00:00 PM"];
    NSDate *skip_last_date = [NSDate dateWithNaturalLanguageString:@"01 January 2000 12:00:00 AM"];
    double skip_max_interval = 0;
    
    bool byAddDate = true;
    double add_max_interval = 0;
    NSDate *added_last_date = [NSDate dateWithNaturalLanguageString:@"01 January 2000 12:00:00 AM"];
    NSDate *addedSince = [NSDate dateWithNaturalLanguageString:@"4 November 2010 12:00:00 AM"];
    
    // loop over playlist processing all tracks
    for(iTunesTrack *track in tracks) {            
        // by play count
        if (byPlayCount) {
            double playedCount = [track playedCount];
            if (playedCount > 0) {
                s1_play += playedCount;
                s2_play += pow(playedCount, 2);
                
                // var by time
                if (varyByTime) {
                    NSDate *lastPlayed = [track playedDate];
                    if (lastPlayed != nil) {
                        play_first_date = [lastPlayed earlierDate:play_first_date];
                        play_last_date = [lastPlayed laterDate:play_last_date];
                    }
                }
            }
        }
        
        // by skip count
        if (bySkipCount) {
            double skippedCount = [track skippedCount];
            if (skippedCount > 0) {
                s1_skip += skippedCount;
                s2_skip += pow(skippedCount, 2);
                
                // var by time
                if (varyByTime) {
                    NSDate *lastSkipped = [track skippedDate];
                    if (lastSkipped != nil) {
                        skip_first_date = [lastSkipped earlierDate:skip_first_date];
                        skip_last_date = [lastSkipped laterDate:skip_last_date];
                    }
                }
            }
        }
        
        // by add date
        if (byAddDate) {
            NSDate *dateAdded = [track dateAdded];
            if (dateAdded != nil) {
                added_last_date = [dateAdded laterDate:added_last_date];
            }
        }
    }
    
    // calculate setup
    if (byPlayCount) {
        mean_play = s1_play / s0;
        double working = (s0 * s2_play) - pow(s1_play, 2);
        stdDev_play = sqrt(working) / s0;
        if (varyByTime) {
            play_max_interval = [play_last_date timeIntervalSinceDate:play_first_date];
        }
    }
    if (bySkipCount) {
        mean_skip = s1_skip / s0;
        double working = (s0 * s2_skip) - pow(s1_skip, 2);
        stdDev_skip = sqrt(working) / s0;
        if (varyByTime) {
            skip_max_interval = [skip_last_date timeIntervalSinceDate:skip_first_date];
        }
    }
    if (byAddDate) {
        add_max_interval = [added_last_date timeIntervalSinceDate:addedSince];
    }
    
    //
    for(iTunesTrack *track in tracks) {
        double newRating = 0;
        double totalRating = 0;
        
        // by add date
        if (byAddDate) {
            NSDate *dateAdded = [track dateAdded];
            double timeGapRating = 0;
            if (dateAdded != nil) {
                if ([dateAdded isGreaterThan:addedSince]) {
                    double timeInterval = [dateAdded timeIntervalSinceDate:addedSince];
                    timeGapRating = timeInterval / add_max_interval;
                    
                    // round rating
                    if (timeGapRating >= 0.8) {
                        timeGapRating = 0.8;
                        
                        // add rating
                        newRating += (timeGapRating + timeGapRating);
                        totalRating += 2;
                    }
                }
            }
        }
        
        // by play count
        if (byPlayCount) {
            double playedCount = [track playedCount];
            double playedRating = 0;
            if (playedCount > 0) {
                double timeGapRating = 1;
                
                // var by time
                if (varyByTime) {
                    NSDate *lastPlayed = [track playedDate];
                    if (lastPlayed != nil) {
                        double timeInterval = [lastPlayed timeIntervalSinceDate:play_first_date];
                        timeGapRating = timeInterval / play_max_interval;
                        if (timeGapRating > 1) {
                            timeGapRating = 1;
                        }
                        if (timeGapRating < 0) {
                            timeGapRating = 0;
                        }
                    }
                }
                
                playedRating = [self normaliseDeviation:(playedCount * timeGapRating) :mean_play :stdDev_play];
                
                if (playedRating > 1) {
                    playedRating = 1;
                }
                if (playedRating < 0) {
                    playedRating = 0;
                }
                
                // add rating
                newRating += playedRating;
                totalRating += 1;
            }
        }
        
        // by skip count
        if (bySkipCount) {
            double skippedCount = [track skippedCount];
            double skippedRating = 0;
            if (skippedCount > 0) {
                double timeGapRating = 1;
                
                // var by time
                if (varyByTime) {
                    NSDate *lastSkipped = [track skippedDate];
                    if (lastSkipped != nil) {
                        double timeInterval = [lastSkipped timeIntervalSinceDate:skip_first_date];
                        timeGapRating = timeInterval / skip_max_interval;
                        if (timeGapRating > 1) {
                            timeGapRating = 1;
                        }
                        if (timeGapRating < 0) {
                            timeGapRating = 0;
                        }
                    }
                }
                
                skippedRating = [self normaliseDeviation:(skippedCount * timeGapRating) :mean_skip :stdDev_skip];
                
                if (skippedRating > 1) {
                    skippedRating = 1;
                }
                if (skippedRating < 0) {
                    skippedRating = 0;
                }
                
                // add rating
                skippedRating = (1 - skippedRating);
                newRating += skippedRating;
                totalRating++;
            }
        }
        
        int rating = 0;
        if (totalRating > 0 ){
            rating = round((newRating / totalRating) * 1000);
            rating = round(rating / 10);
        }
        if ([track rating] != rating) {
            //NSLog(@"%@: %i", [track name], rating);
            [track setRating:rating];
        }
    }
}

- (double) normaliseDeviation:(double) x: (double) mean: (double) stdDev {
    return [self normaliseStandardDeviation:((x - mean)/stdDev)];
}

- (double) normaliseStandardDeviation:(double) x {
    double erfHolder = erf(x / sqrt(2.0));
    return (erfHolder + (1.0 - erfHolder) / 2.0);
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
