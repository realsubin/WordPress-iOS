#import "ServiceRemoteXMLRPC.h"
#import "WPXMLRPCClient.h"

@interface ServiceRemoteXMLRPC()

@property (nonatomic, strong, readwrite) WPXMLRPCClient *api;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

@end

@implementation ServiceRemoteXMLRPC

- (id)initWithApi:(WPXMLRPCClient *)api username:(NSString *)username password:(NSString *)password
{
    NSParameterAssert(api != nil);
    NSParameterAssert(username != nil);
    NSParameterAssert(password != nil);

    self = [super init];
    if (self) {
        _api = api;
        _username = username;
        _password = password;

        // Convert nil values to empty strings to avoid crashing in production builds
        // This should not happen but it is, and at least prevents crashing
        // https://github.com/wordpress-mobile/WordPress-iOS/issues/5199
        if (_username == nil) {
            _username = @"";
            DDLogError(@"Initialized %@ with a nil username", NSStringFromClass([self class]));
        }

        if (_password == nil) {
            _password = @"";
            DDLogError(@"Initialized %@ with a nil password", NSStringFromClass([self class]));
        }
    }
    return self;
}

/**
 Common XML-RPC arguments to most calls

 Most XML-RPC calls will take blog ID, username, and password as their first arguments.
 Blog ID is unused since the blog is inferred from the XML-RPC endpoint. We send a value of 0
 because the documentation expects an int value, and we have to send something.

 See https://github.com/WordPress/WordPress/blob/master/wp-includes/class-wp-xmlrpc-server.php
 for method documentation.
 */
- (NSArray *)defaultXMLRPCArguments {
    return @[@0, self.username, self.password];
}

- (NSArray *)XMLRPCArgumentsWithExtra:(id)extra {
    NSMutableArray *result = [[self defaultXMLRPCArguments] mutableCopy];
    if ([extra isKindOfClass:[NSArray class]]) {
        [result addObjectsFromArray:extra];
    } else if (extra != nil) {
        [result addObject:extra];
    }
    
    return [NSArray arrayWithArray:result];
}

@end
