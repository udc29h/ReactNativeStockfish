#import <React/RCTLog.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#import "ReactNativeStockfish.h"

@implementation ReactNativeStockfish {
    NSThread *stockfishThread;
    BOOL shouldStopStockfish;

    dispatch_source_t stdoutTimer;
    dispatch_source_t stderrTimer;
}

RCT_EXPORT_MODULE(ReactNativeStockfish);

- (instancetype)init {
    NSLog(@"ReactNativeStockfish module is loading");
    self = [super init];
    return self;
}

// Supported events
- (NSArray<NSString *> *)supportedEvents {
    return @[@"stockfish-output", @"stockfish-error"];
}

// Start Stockfish in a background thread
RCT_EXPORT_METHOD(stockfishLoop) {
    if (stockfishThread && stockfishThread.isExecuting) {
        RCTLogInfo(@"Stockfish is already running. Ignoring start request.");
        return;
    }

    shouldStopStockfish = NO;
    stockfishThread = [[NSThread alloc] initWithTarget:self selector:@selector(runStockfish) object:nil];
    [stockfishThread start];
    [self startTimerForStdoutReading];
    [self startTimerForStderrReading];
}   

// The actual execution of stockfish_main
- (void)runStockfish {
    @autoreleasepool {
        RCTLogInfo(@"Stockfish thread started.");

        reactnativestockfish::stockfish_main();

        RCTLogInfo(@"Stockfish thread ended.");
    }
}

// Send a command to Stockfish
RCT_EXPORT_METHOD(sendCommandToStockfish:(NSString *)command) {
    if (!stockfishThread || !stockfishThread.isExecuting) {
        RCTLogInfo(@"Cannot send command: Stockfish is not running.");
        return;
    }

    const char *nativeCommand = [command UTF8String];
    reactnativestockfish::stockfish_stdin_write(nativeCommand);
}

- (void)startTimerForStdoutReading {
    if (stdoutTimer) {
        RCTLogInfo(@"Stdout timer is already running.");
        return;
    }

    RCTLogInfo(@"Stdout timer is starting.");

    // Create dedicated queue
    dispatch_queue_t queue = dispatch_queue_create("com.reactnativestockfish.stdout", DISPATCH_QUEUE_SERIAL);

    // Create timer
    stdoutTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(stdoutTimer,
                              dispatch_time(DISPATCH_TIME_NOW, 0), // Start immediately
                              0.1 * NSEC_PER_SEC,                  // 100 ms inteval
                              0);                                  // Tolerance

    dispatch_source_set_event_handler(stdoutTimer, ^{
        const char *output = reactnativestockfish::stockfish_stdout_read();
        if (output) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self sendEventWithName:@"stockfish-output" body:@(output)];
            });
        }
    });

    dispatch_resume(stdoutTimer); // Start timer

    RCTLogInfo(@"Stdout timer is started.");
}

- (void)startTimerForStderrReading {
    if (stderrTimer) {
        RCTLogInfo(@"Stderr timer is already running.");
        return;
    }

    RCTLogInfo(@"Stderr timer is starting.");

    // Create dedicated queue
    dispatch_queue_t queue = dispatch_queue_create("com.reactnativestockfish.stderr", DISPATCH_QUEUE_SERIAL);

    // Create timer
    stderrTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(stderrTimer,
                              dispatch_time(DISPATCH_TIME_NOW, 0), // Start immediately
                              0.1 * NSEC_PER_SEC,                  // 100 ms interval
                              0);                                  // Tolerance

    dispatch_source_set_event_handler(stderrTimer, ^{
        const char *error = reactnativestockfish::stockfish_stderr_read();
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self sendEventWithName:@"stockfish-error" body:@(error)];
            });
        }
    });

    dispatch_resume(stderrTimer); // Start timer

    RCTLogInfo(@"Sterr timer is started.");
}

- (void)stopTimers {
    if (stdoutTimer) {
        RCTLogInfo(@"Stdout timer is being stopped.");
        dispatch_source_cancel(stdoutTimer);
        stdoutTimer = nil;
        RCTLogInfo(@"Stdout timer is stopped.");
    }
    if (stderrTimer) {
        RCTLogInfo(@"Stderr timer is being stopped.");
        dispatch_source_cancel(stderrTimer);
        stderrTimer = nil;
        RCTLogInfo(@"Stderr timer is stopped.");
    }
}

// Stop the Stockfish thread and timers
RCT_EXPORT_METHOD(stopStockfish) {
    [self stopTimers];
    if (stockfishThread && stockfishThread.isExecuting) {
        shouldStopStockfish = YES;

        reactnativestockfish::stockfish_stdin_write("quit\n");

        [stockfishThread cancel];
        stockfishThread = nil;

        RCTLogInfo(@"Stockfish stopped.");
    } else {
        RCTLogInfo(@"Stockfish is not running.");
    }
}

- (void)dealloc {
    NSLog(@"ReactNativeStockfish module is being removed");
    [self stopStockfish];
}


@end
