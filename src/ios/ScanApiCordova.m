/********* ScanApiCordova.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "ScanApiHelper.h"

@interface ScanApiCordova : CDVPlugin <ScanApiHelperDelegate> {
    // Member variables go here..
    NSString* _callbackId;
    NSOperationQueue* _queue;
    ScanApiHelper* _scanApi;
    NSDictionary* _devices;
}

- (void)useScanApi:(CDVInvokedUrlCommand*)command;
@end

@implementation ScanApiCordova

- (void)useScanApi:(CDVInvokedUrlCommand*)command
{
    _callbackId = command.callbackId;
    if (_queue == nil) {
        _queue = [NSOperationQueue new];
        [_queue setMaxConcurrentOperationCount:1];
    }

    _scanApi = [ScanApiHelper new];
    [_scanApi setDelegate:self];
    [_scanApi open];

    NSOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        [self differedOperation];
    }];

    [_queue addOperation:operation];
}

-(void) differedOperation {
    [_scanApi doScanApiReceive];
    sleep(1);
    NSOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        [self differedOperation];
    }];

    [_queue addOperation:operation];
}

-(void)sendJsonFromDictionary:(NSDictionary*)dictionary {
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];

    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:result callbackId:self->_callbackId];
}

-(DeviceInfo*)getDeviceFromHandle:(NSString*)handle {
    DeviceInfo* device = [_devices objectForKey:handle];
    return device;
}

+(NSString*)getHandleFromDevice:(DeviceInfo*)device {
    NSString* handle = [NSString stringWithFormat:@"%ld",(long)device];
    return handle;
}

-(NSString*)addDevice:(DeviceInfo*)device {
    NSMutableDictionary* devices = (NSMutableDictionary*)_devices;
    if (devices == nil) {
        devices = [NSMutableDictionary new];
    }
    NSString* handle = [ScanApiCordova getHandleFromDevice: device];
    [devices setObject:device forKey:handle];
    _devices = devices;
    return handle;
}

-(NSString*)removeDevice:(DeviceInfo*)device {
    NSMutableDictionary* devices = (NSMutableDictionary*)_devices;
    NSString* handle = [ScanApiCordova getHandleFromDevice: device];
    if (devices != nil) {
        [devices removeObjectForKey:handle];
    }
    return handle;
}


#pragma  mark - ScanApiHelperDelegate
/**
 * called each time a device connects to the host
 * @param result contains the result of the connection
 * @param deviceInfo contains the device information
 */
-(void)onDeviceArrival:(SKTRESULT)result device:(DeviceInfo*)deviceInfo{
    NSLog(@"onDeviceArrival: %@ Result: %ld", [deviceInfo getName], result);
    NSString* handle = [self addDevice: deviceInfo];
    NSString* name = [deviceInfo getName];
    NSNumber* type = [NSNumber numberWithLong:[deviceInfo getType]];
    NSDictionary* deviceArrival=[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"deviceArrival", @"type",
                                 name, @"deviceName",
                                 type, @"deviceType",
                                 handle, @"deviceHandle",  nil];

    [self sendJsonFromDictionary:deviceArrival];
}

/**
 * called each time a device disconnect from the host
 * @param deviceRemoved contains the device information
 */
-(void) onDeviceRemoval:(DeviceInfo*) deviceRemoved{
    NSLog(@"onDeviceRemoval %@", [deviceRemoved getName]);
    NSString* handle = [self removeDevice: deviceRemoved];
    NSString* name = [deviceRemoved getName];
    NSNumber* type = [NSNumber numberWithLong:[deviceRemoved getType]];
    NSDictionary* deviceArrival=[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"deviceRemoval", @"type",
                                 name, @"deviceName",
                                 type, @"deviceType",
                                 handle, @"deviceHandle",  nil];

    [self sendJsonFromDictionary:deviceArrival];
}

/**
 * called each time ScanAPI is reporting an error
 * @param result contains the error code
 */
-(void) onError:(SKTRESULT) result{
    NSLog(@"onError result: %ld", result);
    NSNumber* resultObj = [NSNumber numberWithLong:(long)result];
    NSDictionary* error=[NSDictionary dictionaryWithObjectsAndKeys:
                         @"error", @"type",
                         @"onError", @"name",
                         resultObj, @"result",  nil];

    [self sendJsonFromDictionary:error];
}

/**
 * called when ScanAPI initialization has been completed
 * @param result contains the initialization result
 */
-(void) onScanApiInitializeComplete:(SKTRESULT) result{
    NSLog(@"onScanApiInitializeComplete result: %ld", result);
    NSNumber* resultObj = [NSNumber numberWithLong:(long)result];
    NSDictionary* initComplete=[NSDictionary dictionaryWithObjectsAndKeys:
                                @"initializeComplete", @"type",
                                resultObj, @"result",  nil];

    [self sendJsonFromDictionary:initComplete];
}

/**
 * called when ScanAPI has been terminated. This will be
 * the last message received from ScanAPI
 */
-(void) onScanApiTerminated{
    NSLog(@"onScanApiTerminated");
    NSDictionary* scanApiTerminated=[NSDictionary dictionaryWithObjectsAndKeys:
                                     @"scanApiTerminated", @"type",  nil];

    [self sendJsonFromDictionary:scanApiTerminated];
}

/**
 * called when an error occurs during the retrieval
 * of a ScanObject from ScanAPI.
 * @param result contains the retrieval error code
 */
-(void) onErrorRetrievingScanObject:(SKTRESULT) result{
    NSLog(@"onErrorRetrievingScanObject result: %ld", result);
    NSNumber* resultObj = [NSNumber numberWithLong:(long)result];
    NSDictionary* error=[NSDictionary dictionaryWithObjectsAndKeys:
                         @"error", @"type",
                         @"errorRetrieveScanObject", @"name",
                         resultObj, @"result",  nil];

    [self sendJsonFromDictionary:error];
}

/**
 * called each time ScanAPI receives decoded data from scanner
 * @param result is ESKT_NOERROR when decodedData contains actual
 * decoded data. The result can be set to ESKT_CANCEL when the
 * end-user cancels a SoftScan operation
 * @param device contains the device information from which
 * the data has been decoded
 * @param decodedData contains the decoded data information
 */
-(void) onDecodedDataResult:(long) result device:(DeviceInfo*) device decodedData:(ISktScanDecodedData*) decodedData{
    NSString* handle = [ScanApiCordova getHandleFromDevice: device];
    NSNumber* deviceType = [NSNumber numberWithLong:[device getType]];
    NSInteger len = (int)[decodedData getDataSize];
    const unsigned char* pData = [decodedData getData];
    NSMutableArray* dataArray = [[NSMutableArray alloc]initWithCapacity:len];
    for(int i = 0; i< len; i++){
        NSNumber* num = [NSNumber numberWithUnsignedChar:(unsigned char)pData[i]];
        [dataArray addObject:num];
    }
    NSNumber* symbologyId = [NSNumber numberWithInt:(int)[decodedData ID]];
    NSDictionary* decodedDataDictionary=[NSDictionary dictionaryWithObjectsAndKeys:
                                         @"decodedData", @"type",
                                         [device getName], @"deviceName",
                                         deviceType, @"deviceType",
                                         handle, @"deviceHandle",
                                         dataArray, @"decodedData",
                                         symbologyId, @"symbologyId",
                                         [decodedData Name], @"symbologyName",
                                         handle, @"deviceHandle",  nil];

    [self sendJsonFromDictionary:decodedDataDictionary];
}


@end
