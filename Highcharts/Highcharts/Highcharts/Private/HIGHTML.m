//
//  HIGHTML.m
//  Highcharts
//
//  License: www.highcharts.com/license
//  Copyright © 2016 Highsoft AS. All rights reserved.
//

#import "HIGHTML.h"
#import "HIGDependency.h"
#import "HIGJavaScript.h"

@interface HIGHTML ()
@property (strong, readwrite) NSString *html_tmp;
@property (strong, readwrite) NSString *html;
@property (strong, nonatomic) NSString *scripts;
@property (strong, nonatomic) HIGJavaScript *js;
@end

@implementation HIGHTML

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.js = [[HIGJavaScript alloc] init];
    }
    return self;
}

- (void)loadHTML:(NSString*)path
{
    self.html_tmp = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    self.html = [self.html_tmp copy];
    
    self.scripts = @"";
}

- (void)prepareScripts {
    self.scripts = @"";
}

- (void)prepareJavaScript:(NSString*)js prefix:(NSString*)prefix suffix:(NSString*)suffix;
{
    if (!js) {
        return;
    }

    NSString *template = @"<script src=\"%@\"></script>\n";

    if (SYSTEM_VERSION_LESS_THAN(@"9.0")) {
        template = @"<script src=\"%@\" charset=\"UTF-8\"></script>\n";
    }

    NSString *jsFileName = [NSString stringWithFormat:@"%@%@%@", prefix, js, suffix];
    NSString *jsFilePath = [self.baseURL stringByAppendingPathComponent:jsFileName];

    if (![[NSFileManager defaultManager] fileExistsAtPath:jsFilePath]) {
        NSLog(@"[ Highcharts ]: %@, dont exits!", jsFileName);
        return;
    }

    // Use absolute file URL for iOS 26.4 compatibility
    // This allows loading scripts from framework bundle when HTML is in temp directory
    NSURL *jsFileURL = [NSURL fileURLWithPath:jsFilePath];
    self.scripts = [self.scripts stringByAppendingString:[NSString stringWithFormat:template, jsFileURL.absoluteString]];
}

- (void)prepareOptions:(NSDictionary*)options;
{
    options = [HIGDependency addOptions:options];
    
    self.options = [self.js JSObject:options];
}

- (void)prepareLang:(NSDictionary*)lang;
{
    self.lang = [self.js JSObject:lang];
}

- (void)prepareViewWidth:(float)width height:(float)height
{
    NSString *widthString = [NSString stringWithFormat:@"%.f", width];
    self.html = [self.html_tmp stringByReplacingOccurrencesOfString:@"{{width}}" withString:widthString];

    NSString *heightString = [NSString stringWithFormat:@"%.f", height];
    self.html = [self.html stringByReplacingOccurrencesOfString:@"{{height}}" withString:heightString];
}

- (void)injectJavaScriptToHTML
{
    // Replace CSS reference with absolute file URL for iOS 26.4 compatibility
    NSString *cssFilePath = [self.baseURL stringByAppendingPathComponent:@"highcharts.css"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cssFilePath]) {
        NSURL *cssFileURL = [NSURL fileURLWithPath:cssFilePath];
        self.html = [self.html stringByReplacingOccurrencesOfString:@"href=\"highcharts.css\""
                                                         withString:[NSString stringWithFormat:@"href=\"%@\"", cssFileURL.absoluteString]];
    }

    // Replace lib path with absolute URL for exporting library
    NSString *libPath = [self.baseURL stringByAppendingPathComponent:@"js/lib/"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:libPath]) {
        NSURL *libURL = [NSURL fileURLWithPath:libPath];
        self.html = [self.html stringByReplacingOccurrencesOfString:@"libURL: 'js/lib/'"
                                                         withString:[NSString stringWithFormat:@"libURL: '%@'", libURL.absoluteString]];
    }

    self.html = [self.html stringByReplacingOccurrencesOfString:@"{{script}}" withString:self.scripts?:@""];

    self.html = [self.html stringByReplacingOccurrencesOfString:@"{{options}}" withString:self.options?:@""];

    self.html = [self.html stringByReplacingOccurrencesOfString:@"{{lang}}" withString:self.lang?:@""];

}

@end
