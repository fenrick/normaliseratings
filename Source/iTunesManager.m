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
    
    double mean_play = 0;
    double stdDev_play = 0;
    
    double mean_skip = 0;
    double stdDev_skip = 0;
    
    double play_max_interval = 0;
    double skip_max_interval = 0;
    
    double add_max_interval = 0;
    NSDate *addedSince = [NSDate dateWithNaturalLanguageString:@"4 November 2010 12:00:00 AM"];
    
    NSLog(@"Data retrieval");
    
    // played counts
    NSArray *playedCounts = [tracks arrayByApplyingSelector:@selector(playedCount)];
    int s1_play = [[playedCounts valueForKeyPath:@"@sum.intValue"] intValue];
    int s2_play = 0;
    for(NSNumber *count in playedCounts) {
        s2_play += pow([count intValue], 2);
    }
    
    // played dates
    NSArray *playedDates = [tracks arrayByApplyingSelector:@selector(playedDate)];
    NSDate *play_first_date = [[playedDates valueForKeyPath:@"@min.self"] earlierDate:[NSDate dateWithNaturalLanguageString:@"31 December 2100 12:00:00 PM"]];
    NSDate *play_last_date = [[playedDates valueForKeyPath:@"@max.self"] laterDate:[NSDate dateWithNaturalLanguageString:@"01 January 2000 12:00:00 AM"]];
    
    // skiped counts
    NSArray *skippedCounts = [tracks arrayByApplyingSelector:@selector(skippedCount)];
    int s1_skip = [[skippedCounts valueForKeyPath:@"@sum.intValue"] intValue];
    int s2_skip = 0;
    for(NSNumber *count in skippedCounts) {
        s2_skip += pow([count intValue], 2);
    }
    
    // played dates
    NSArray *skippedDates = [tracks arrayByApplyingSelector:@selector(skippedDate)];
    NSDate *skip_first_date = [[skippedDates valueForKeyPath:@"@min.self"] earlierDate:[NSDate dateWithNaturalLanguageString:@"31 December 2100 12:00:00 PM"]];
    NSDate *skip_last_date = [[skippedDates valueForKeyPath:@"@max.self"] laterDate:[NSDate dateWithNaturalLanguageString:@"01 January 2000 12:00:00 AM"]];
    
    // add dates
    NSArray *addedDates = [tracks arrayByApplyingSelector:@selector(dateAdded)];
    NSDate *added_last_date = [[addedDates valueForKeyPath:@"@max.self"] laterDate:[NSDate dateWithNaturalLanguageString:@"01 January 2000 12:00:00 AM"]];
    
    
    NSLog(@"Calculations");
    
    // calculate setup
    mean_play = s1_play / s0;
    stdDev_play = sqrt((s0 * s2_play) - pow(s1_play, 2)) / s0;
    play_max_interval = [play_last_date timeIntervalSinceDate:play_first_date];
    mean_skip = s1_skip / s0;
    stdDev_skip = sqrt((s0 * s2_skip) - pow(s1_skip, 2)) / s0;
    skip_max_interval = [skip_last_date timeIntervalSinceDate:skip_first_date];
    add_max_interval = [added_last_date timeIntervalSinceDate:addedSince];
    
    NSLog(@"Wiping track ratings");
    
    [tracks makeObjectsPerformSelector:@selector(setRating:)];
    
    NSLog(@"Wiping album ratings");
    
    [tracks makeObjectsPerformSelector:@selector(setAlbumRating:)];
    
    NSLog(@"Updating song rating");
    
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
