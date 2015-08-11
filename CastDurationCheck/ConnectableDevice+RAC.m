//
//  ConnectableDevice+RAC.m
//  CastDurationCheck
//
//  Created by Eugene Nikolskyi on 2015-08-10.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "ConnectableDevice+RAC.h"

#import <ReactiveCocoa.h>

#import <objc/runtime.h>

// the use of a category silences unimplemented method warnings
// the delegate's methods are handled with signals
@interface ConnectableDevice (Delegate) <ConnectableDeviceDelegate> @end

@implementation ConnectableDevice (RAC)

- (RACSignal *)rac_deviceReadySignal {
    // @seealso http://spin.atomicobject.com/2014/02/03/objective-c-delegate-pattern/
    self.delegate = self;

    RACSignal *signal = objc_getAssociatedObject(self, _cmd);
    if (!signal) {
        signal = [[self rac_signalForSelector:@selector(connectableDeviceReady:)
                                 fromProtocol:@protocol(ConnectableDeviceDelegate)]
            map:^id(RACTuple *tuple) {
                return tuple.first;
            }];

        objc_setAssociatedObject(self, _cmd, signal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return signal;
}

@end
