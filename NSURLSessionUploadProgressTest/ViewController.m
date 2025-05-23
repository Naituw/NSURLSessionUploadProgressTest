//
//  ViewController.m
//  NSURLSessionUploadProgressTest
//
//  Created by Wu Tian on 2025/1/24.
//

#import "ViewController.h"

@interface ViewController () <NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession * session;
@property (nonatomic, strong) NSURLSessionUploadTask * task;

@end

@implementation ViewController

- (NSURLSession *)session
{
    if (!_session) {
        __auto_type config = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

static NSInteger UnixTimestampMs(void) {
    return (int64_t)((CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970) * 1000); /* milliseconds */
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // ⚠️ First limit uplink bandwidth to 200Kbps with the Network Link Conditioner
    
    // Make random 1MB body data
    __auto_type length = 1 * 1024 * 1024;
    __auto_type buffer = malloc(length);
    __auto_type data = [NSData dataWithBytesNoCopy:buffer length:length freeWhenDone:YES];
    
    __auto_type endpoint = @"https://developer.apple.com"; /* like most servers, the progress will be inaccurate, and timeout happens easily */
//    __auto_type endpoint = @"https://tryit.w3schools.com"; /* but the progress & timeout mechanism works fine when uploading to this server */
    
    __auto_type request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:endpoint]];
    request.HTTPMethod = @"POST";
    
    // 💥 the request will timeout after about 10 seconds, due to the progress became 100% at the begining and not updating then
    request.timeoutInterval = 10;
    
    _task = [self.session uploadTaskWithRequest:request fromData:data];
    
    NSLog(@"!!! time: %zd, task(%lu) start", UnixTimestampMs(), _task.taskIdentifier);

    [_task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    __auto_type progress = (double)totalBytesSent / totalBytesExpectedToSend * 100;
    NSLog(@"!!! time: %zd, task(%lu) progress: %f%% (%lld/%lld)", UnixTimestampMs(), task.taskIdentifier, progress, totalBytesSent, totalBytesExpectedToSend);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        NSLog(@"!!! time: %zd, task(%lu) failed with error: %@", UnixTimestampMs(), task.taskIdentifier, error);
    } else {
        NSLog(@"!!! time: %zd, task(%lu) finished", UnixTimestampMs(), task.taskIdentifier);
    }
}

@end
