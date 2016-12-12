/********* CDVp2pkit.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <P2PKit/P2Pkit.h>

@interface p2pkit : CDVPlugin <PPKControllerDelegate> {
  // Member variables go here.
    NSString *discoveryListenerCallbackId;
    NSString *initializedCallbackId;
}
@end

@implementation p2pkit

- (void)enableP2PKit:(CDVInvokedUrlCommand*)command
{
    NSString* apikey = [command.arguments objectAtIndex:0];
    
    initializedCallbackId = command.callbackId;
    NSLog(@"Doing app key %@", apikey);
    [PPKController enableWithConfiguration:apikey observer:self];
}

- (void)createP2pDiscoveryListener:(CDVInvokedUrlCommand*)command
{
    discoveryListenerCallbackId = command.callbackId;
    CDVPluginResult* pluginResult = nil;
    
    [PPKController startP2PDiscoveryWithDiscoveryInfo:nil];
    [PPKController enableProximityRanging];
    
    pluginResult =[CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

#pragma mark - PPKControllerDelegate

-(void)PPKControllerInitialized {
    NSLog(@"Controller initialized");
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:initializedCallbackId];
}

-(void)PPKControllerFailedWithError:(NSError *)error {
    
    NSString *description;
    switch ((PPKErrorCode) error.code) {
        case PPKErrorAppKeyInvalid:
            description = @"Invalid app key";
            break;
        case PPKErrorOnlineAppKeyExpired:
            description = @"Online app key expired";
            break;
        case PPKErrorAppKeyExpired:
            description = @"App key expired";
            break;
        case PPKErrorOnlineAppKeyInvalid:
            description = @"Online app key invalid";
            break;
        case PPKErrorOnlineProtocolVersionNotSupported:
            description = @"Server protocol mismatch";
            break;
        default:
            description = @"Unknown error";
            break;
    }
    
    NSLog(@"Error: %@", description);
}

-(void)p2pPeerDiscovered:(PPKPeer *)peer {
    NSString *jsonString = [self buildJsonForPeer:peer type: @"onPeerDiscovered"];
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:result callbackId:discoveryListenerCallbackId];
}

-(void)p2pPeerLost:(PPKPeer *)peer {
    NSString *jsonString = [self buildJsonForPeer:peer type: @"onPeerLost"];
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:result callbackId:discoveryListenerCallbackId];
}

-(void)discoveryInfoUpdatedForPeer:(PPKPeer *)peer {
    NSString *jsonString = [self buildJsonForPeer:peer type: @"onPeerUpdatedDiscoveryInfo"];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:result callbackId:discoveryListenerCallbackId];
}

-(void)proximityStrengthChangedForPeer:(PPKPeer *)peer {
    NSString *jsonString = [self buildJsonForPeer:peer type: @"onProximityStrengthChanged"];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:result callbackId:discoveryListenerCallbackId];
}

-(void)p2pDiscoveryStateChanged:(PPKPeer2PeerDiscoveryState)state {
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"type", @"onP2PStateChanged",
                              @"state", state,
                              nil];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:result callbackId:discoveryListenerCallbackId];
    
}

-(NSString*)buildJsonForPeer:(PPKPeer*)peer type:(NSString*) type {
    NSDictionary *peerDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"uuid", peer.peerID,
                              @"proximity", peer.proximityStrength,
                              nil];
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"type", type,
                              @"peer", peerDict,
                              nil];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

@end