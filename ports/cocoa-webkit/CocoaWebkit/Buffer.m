//
// Copyright © 2017-2018 Atlas Engineer LLC.
// Use of this file is governed by the license that can be found in LICENSE.
//

#import "Buffer.h"
#include "Global.h"
#include "XMLRPCRequestEncoder.h"

@implementation Buffer
@synthesize callBackCount;
@synthesize identifier;

- (instancetype)init {
    self = [super init];
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setCallBackCount:0];
    [self setNavigationDelegate:self];
    return self;
}

- (bool)loadUrl:(NSString*) url {
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    return YES;
}

- (NSString*)evaluateJavaScript:(NSString*)javaScript {
    [self setCallBackCount:[self callBackCount] + 1];
    [self evaluateJavaScript:javaScript
           completionHandler:^(id result, NSError* error) {
               if (error == nil && result != nil) {
                   NSString* transformedResult = [NSString stringWithFormat:@"%@", result];
                   NSString* coreSocket = [[Global sharedInstance] coreSocket];
                   XMLRPCRequestEncoder* request = [[XMLRPCRequestEncoder alloc] initWithURL:
                                                                                     [NSURL URLWithString:coreSocket]];
                   [request setMethod:@"buffer.javascript.call.back"
                       withParameters:@[ [self identifier],
                           transformedResult,
                           [@([self callBackCount]) stringValue] ]];
                   NSURLSession* session = [NSURLSession sharedSession];
                   [[session dataTaskWithRequest:[request request]] resume];
               } else if ([error description]) {
                   NSLog(@"evaluateJavaScript error : %@", [error description]);
               }
           }];
    return [@([self callBackCount]) stringValue];
}

- (void)webView:(WKWebView*)webView didCommitNavigation:(WKNavigation*)navigation {
    NSString* url = [[self URL] absoluteString];
    NSString* coreSocket = [[Global sharedInstance] coreSocket];
    XMLRPCRequestEncoder* request = [[XMLRPCRequestEncoder alloc] initWithURL:
                                                                      [NSURL URLWithString:coreSocket]];
    [request setMethod:@"buffer.did.commit.navigation"
        withParameters:@[ [self identifier], url ]];
    NSURLSession* session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:[request request]] resume];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSString* url = [[self URL] absoluteString];
    NSString* coreSocket = [[Global sharedInstance] coreSocket];
    XMLRPCRequestEncoder* request = [[XMLRPCRequestEncoder alloc] initWithURL:
                                     [NSURL URLWithString:coreSocket]];
    [request setMethod:@"buffer.did.finish.navigation"
        withParameters:@[ [self identifier], url ]];
    NSURLSession* session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:[request request]] resume];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    // This is a 'new window action' (aka target="_blank") > open this URL
    // in a new window by invoking MAKE-BUFFERS on the Lisp Core
    if (![navigationAction targetFrame]) {
        NSString *url = [[[navigationAction request] URL] absoluteString];
        NSString* coreSocket = [[Global sharedInstance] coreSocket];
        XMLRPCRequestEncoder* request = [[XMLRPCRequestEncoder alloc] initWithURL:
                                         [NSURL URLWithString:coreSocket]];
        // Make Buffers Expects an array of URLs
        [request setMethod:@"make.buffers"
            withParameters:@[@[url]]];
        NSURLSession* session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:[request request]] resume];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
