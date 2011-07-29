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
    [iTunes setFixedIndexing:true];
    
    // Music playlist is within the Library source.
    iTunesPlaylist *musicPlaylist = [self findPlaylistFromLibrary:@"Library" :@"Music"];
    
    // track list
    SBElementArray *tracks = [musicPlaylist tracks];
    
    if ([tracks count] == 0) {
        return;
    }
    
    int s0 = [tracks count];
    
    double s1_play = 0;
    double s2_play = 0;
    double mean_play = 0;
    double stdDev_play = 0;
    
    double s1_skip = 0;
    double s2_skip = 0;
    double mean_skip = 0;
    double stdDev_skip = 0;
    
    NSDate *play_first_date = [NSDate dateWithNaturalLanguageString:@"31 December 2100 12:00:00 PM"];
    NSDate *play_last_date = [NSDate dateWithNaturalLanguageString:@"01 January 2000 12:00:00 AM"];
    double play_max_interval = 0;
    NSDate *skip_first_date = [NSDate dateWithNaturalLanguageString:@"31 December 2100 12:00:00 PM"];
    NSDate *skip_last_date = [NSDate dateWithNaturalLanguageString:@"01 January 2000 12:00:00 AM"];
    double skip_max_interval = 0;
    
    double add_max_interval = 0;
    NSDate *added_last_date = [NSDate dateWithNaturalLanguageString:@"01 January 2000 12:00:00 AM"];
    NSDate *addedSince = [NSDate dateWithNaturalLanguageString:@"4 November 2010 12:00:00 AM"];
    
    // loop over playlist processing all tracks
    for(iTunesTrack *track in tracks) {            
        // by play count
        {
            double playedCount = [track playedCount];
            if (playedCount > 0) {
                s1_play += playedCount;
                s2_play += pow(playedCount, 2);
                
                // var by time
                {
                    NSDate *lastPlayed = [track playedDate];
                    if (lastPlayed != nil) {
                        play_first_date = [lastPlayed earlierDate:play_first_date];
                        play_last_date = [lastPlayed laterDate:play_last_date];
                    }
                }
            }
        }
        
        // by skip count
        {
            double skippedCount = [track skippedCount];
            if (skippedCount > 0) {
                s1_skip += skippedCount;
                s2_skip += pow(skippedCount, 2);
                
                // var by time
                {
                    NSDate *lastSkipped = [track skippedDate];
                    if (lastSkipped != nil) {
                        skip_first_date = [lastSkipped earlierDate:skip_first_date];
                        skip_last_date = [lastSkipped laterDate:skip_last_date];
                    }
                }
            }
        }
        
        // by add date
        {
            NSDate *dateAdded = [track dateAdded];
            if (dateAdded != nil) {
                added_last_date = [dateAdded laterDate:added_last_date];
            }
        }
    }
    
    // calculate setup
    {
        mean_play = s1_play / s0;
        double working = (s0 * s2_play) - pow(s1_play, 2);
        stdDev_play = sqrt(working) / s0;
        {
            play_max_interval = [play_last_date timeIntervalSinceDate:play_first_date];
        }
    }
    {
        mean_skip = s1_skip / s0;
        double working = (s0 * s2_skip) - pow(s1_skip, 2);
        stdDev_skip = sqrt(working) / s0;
        {
            skip_max_interval = [skip_last_date timeIntervalSinceDate:skip_first_date];
        }
    }
    {
        add_max_interval = [added_last_date timeIntervalSinceDate:addedSince];
    }
    
    //
    for(iTunesTrack *track in tracks) {
        double newRating = 0;
        double totalRating = 0;
        
        // by play time
        {
            double timeGapRating = 1;
            double weighting = 1;
            
            // var by time
            if (weighting > 0)
            {
                NSDate *lastPlayed = [track playedDate];
                if (lastPlayed != nil) {
                    double timeInterval = [lastPlayed timeIntervalSinceDate:play_first_date];
                    timeGapRating = timeInterval / play_max_interval;
                    if (timeGapRating > 1) {
                        timeGapRating = 1;
                    } else
                        if (timeGapRating < 0) {
                            timeGapRating = 0;
                        }
                    
                    int rating = round(timeGapRating * 10);
                    
                    // add rating
                    newRating += (((double) rating) / 10) * weighting;
                }
            }
            totalRating += weighting;
        }
        
        
        // by play count
        {
            double playedCount = [track playedCount];
            double playedRating = 0;
            double weighting = 2;
            if (weighting > 0) {
                if (playedCount > 0) {
                    playedRating = [self normaliseDeviation:playedCount :mean_play :stdDev_play];
                    
                    if (playedRating > 1) {
                        playedRating = 1;
                    } else
                        if (playedRating < 0) {
                            playedRating = 0;
                        }
                }
                
                int rating = round(playedRating * 10);
                
                // add rating
                newRating += (((double) rating) / 10) * weighting;
            }
            totalRating += weighting;
        }
        
        double newSkipRating = 0;
        double totalSkipRating = 0;
        
        // by skip time
        {
            double timeGapRating = 1;
            double weighting = 1;   
            
            // var by time
            if (weighting > 0) {
                NSDate *lastSkipped = [track skippedDate];
                if (lastSkipped != nil) {
                    double timeInterval = [lastSkipped timeIntervalSinceDate:skip_first_date];
                    timeGapRating = timeInterval / skip_max_interval;
                    if (timeGapRating > 1) {
                        timeGapRating = 1;
                    } else
                        if (timeGapRating < 0) {
                            timeGapRating = 0;
                        }
                    int rating = round(timeGapRating * 10);
                    
                    // add rating
                    timeGapRating = (0 - (((double) rating) / 10));
                    newSkipRating += timeGapRating * weighting;
                    totalSkipRating += weighting;
                }
            }
        }
        
        // by skip count 
        {
            double skippedCount = [track skippedCount];
            double skippedRating = 0;
            double weighting = 2;
            if (weighting > 0) {
                if (skippedCount > 0) {
                    skippedRating = [self normaliseDeviation:skippedCount :mean_skip :stdDev_skip];
                    
                    if (skippedRating > 1) {
                        skippedRating = 1;
                    } else
                        if (skippedRating < 0) {
                            skippedRating = 0;
                        }
                    int rating = round(skippedRating * 10);
                    
                    // add rating
                    skippedRating = (0 - (((double) rating) / 10));
                    newSkipRating += skippedRating * weighting;
                    totalSkipRating += weighting;
                }
            }
        }
        
        // skip effect
        {
            double weighting = 1;
            
            if (totalSkipRating > 0) {
                newRating += ((newSkipRating / totalSkipRating) * weighting);
                totalRating += weighting;
            }
        }
        
        // by add date
        {
            double weighting = 2;
            double timeGapRating = 0;
            if (weighting > 0) {
                NSDate *dateAdded = [track dateAdded];
                if (dateAdded != nil) {
                    if ([dateAdded isGreaterThan:addedSince]) {
                        double timeInterval = [dateAdded timeIntervalSinceDate:addedSince];
                        timeGapRating = timeInterval / add_max_interval;
                        if (timeGapRating > 1) {
                            timeGapRating = 1;
                        } else
                            if (timeGapRating < 0) {
                                timeGapRating = 0;
                            }
                        // apply weighting
                        int rating = round(timeGapRating * 5);
                        
                        if (rating >= 4) {
                            rating = 4;
                        } else if (rating >= 2) {
                            rating = 2;
                        } else {
                            rating = 0;
                        }
                        
                        // if never played, never skipped, then remove all counter effects
                        if (newRating == 0 && totalRating > 0 && rating > 0) {
                            totalRating = 0;
                        }
                        
                        
                        // add rating
                        if (rating > 0) {
                            newRating += (((double) rating / 5)  * weighting);
                            totalRating += weighting;
                        }
                    }
                }
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
    
    [iTunes setFixedIndexing:false];
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
