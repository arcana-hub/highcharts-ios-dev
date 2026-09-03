//
//  HIGBundle.m
//  Highcharts
//
//  License: www.highcharts.com/license
//  Copyright © 2016 Highsoft AS. All rights reserved.
//

#import "HIGBundle.h"

@implementation HIGBundle

static dispatch_queue_t higBundleQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.highcharts.bundle.preload.queue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (BOOL)preloadBundle:(NSString*)bundleName
{
    __block BOOL result = YES;
    dispatch_sync(higBundleQueue(), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSBundle *frameworkBundle = [self sourceBundle:bundleName];
        NSString *tmpBundle = [frameworkBundle bundlePath];
        NSString *tmpBundleDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:bundleName];

        // A previously-copied temp bundle may be stale or incomplete: earlier builds
        // populated this directory differently, and because the copy below is skipped
        // whenever the directory already exists, a partial copy (e.g. missing
        // highcharts.html) would otherwise be reused forever. The chart's HTML template
        // and all JS/CSS resources are loaded relative to this directory, so an
        // incomplete copy results in a blank chart (file:// load fails with -1100).
        //
        // Validate the copy using highcharts.html as a sentinel. If the directory exists
        // but is missing the template, treat it as stale, remove it, and re-copy.
        if ([fileManager fileExistsAtPath:tmpBundleDirectory]) {
            NSString *sentinel = [tmpBundleDirectory stringByAppendingPathComponent:@"highcharts.html"];
            if ([fileManager fileExistsAtPath:sentinel]) {
                return;
            }
            [fileManager removeItemAtPath:tmpBundleDirectory error:nil];
        }

        NSError *error = nil;
        if (![fileManager copyItemAtPath:tmpBundle toPath:tmpBundleDirectory error:&error]) {
            NSLog(@"Error copying files: %@", [error localizedDescription]);
            result = NO;
        }
    });
    return result;
}

+ (void)preloadBundleInBackground:(NSString*)bundleName
{
    dispatch_async(higBundleQueue(), ^{
        NSBundle *frameworkBundle = [self sourceBundle:bundleName];
        NSString *tmpBundle = [frameworkBundle bundlePath];
        NSString *tmpBundleDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:bundleName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:tmpBundleDirectory]) {
            return;
        }
        
        NSError *error = nil;
        if (![[NSFileManager defaultManager] copyItemAtPath:tmpBundle toPath:tmpBundleDirectory error:&error]) {
            NSLog(@"Error copying files: %@", [error localizedDescription]);
        }
    });
}

+ (NSBundle*)bundle:(NSString*)bundleName
{
    NSBundle *bundle = [self bundleIfExists:bundleName];
    if (!bundle) {
        bundle = [self sourceBundle:bundleName];
    }
    NSAssert(bundle, @"Highcharts bundle was not found!");
    return bundle;
}

+ (NSBundle*)bundleIfExists:(NSString*)bundleName
{
    NSBundle *bundle = nil;
    NSString *tmpBundleDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:bundleName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tmpBundleDirectory]) {
        bundle = [NSBundle bundleWithPath:tmpBundleDirectory];
    }
    return bundle;
}

+ (NSBundle*)sourceBundle:(NSString*)bundleName
{
    NSBundle *frameworkBundle = [NSBundle bundleForClass:[self class]];
    NSString *bundlePath = [frameworkBundle pathForResource:bundleName ofType:nil];
    if (!bundlePath) {
        return nil;
    }
    return [NSBundle bundleWithPath:bundlePath];
}

@end
