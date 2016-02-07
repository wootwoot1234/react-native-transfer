#import "Transfer.h"

@implementation Transfer

NSMapTable *_successCallbacks;
NSMapTable *_errorCallbacks;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(Upload:(NSDictionary *)obj successCallback:(RCTResponseSenderBlock)successCallback errorCallback:(RCTResponseErrorBlock)errorCallback)
{
    if (!_successCallbacks) {
        _successCallbacks = [NSMapTable strongToStrongObjectsMapTable];
    }
    if (!_errorCallbacks) {
        _errorCallbacks = [NSMapTable strongToStrongObjectsMapTable];
    }

    NSString *uploadUrl = obj[@"uploadUrl"];
    NSDictionary *headers = obj[@"headers"];
    NSDictionary *fields = obj[@"fields"];
    NSArray *files = obj[@"files"];
    NSString *method = obj[@"method"];

    if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {
    } else {
        method = @"POST";
    }

    NSURL *url = [NSURL URLWithString:uploadUrl];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:method];

    // set headers
    NSString *formBoundaryString = [self generateBoundaryString];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", formBoundaryString];
    [req setValue:contentType forHTTPHeaderField:@"Content-Type"];
    for (NSString *key in headers) {
        id val = [headers objectForKey:key];
        if ([val respondsToSelector:@selector(stringValue)]) {
            val = [val stringValue];
        }
        if (![val isKindOfClass:[NSString class]]) {
            continue;
        }
        [req setValue:val forHTTPHeaderField:key];
    }


    NSData *formBoundaryData = [[NSString stringWithFormat:@"--%@\r\n", formBoundaryString] dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData* reqBody = [NSMutableData data];

    // add fields
    for (NSString *key in fields) {
        id val = [fields objectForKey:key];
        if ([val respondsToSelector:@selector(stringValue)]) {
            val = [val stringValue];
        }
        if (![val isKindOfClass:[NSString class]]) {
            continue;
        }

        [reqBody appendData:formBoundaryData];
        [reqBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [reqBody appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
        [reqBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    // add files
    for (NSDictionary *file in files) {
        NSString *name = file[@"name"];
        NSString *filename = file[@"filename"];
        NSString *filepath = file[@"filepath"];
        NSString *filetype = file[@"filetype"];

        NSData *fileData = nil;

        NSLog(@"filepath: %@", filepath);
        if ([filepath hasPrefix:@"assets-library:"]) {
            fileData = [self fileFromAssetsLibrary:filepath];
        } else if ([filepath hasPrefix:@"data:"] || [filepath hasPrefix:@"file:"]) {
            [self fileFromUrl:filepath];
        } else {
            fileData = [NSData dataWithContentsOfFile:filepath];
        }

        [reqBody appendData:formBoundaryData];
        [reqBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name.length ? name : filename, filename] dataUsingEncoding:NSUTF8StringEncoding]];

        if (filetype) {
            [reqBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", filetype] dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            [reqBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", [self mimeTypeForPath:filename]] dataUsingEncoding:NSUTF8StringEncoding]];
        }

        [reqBody appendData:[[NSString stringWithFormat:@"Content-Length: %ld\r\n\r\n", (long)[fileData length]] dataUsingEncoding:NSUTF8StringEncoding]];
        [reqBody appendData:fileData];
        [reqBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    // add end boundary
    NSData* end = [[NSString stringWithFormat:@"--%@--\r\n", formBoundaryString] dataUsingEncoding:NSUTF8StringEncoding];
    [reqBody appendData:end];

    // send request
    [req setHTTPBody:reqBody];

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:(id)self delegateQueue:[NSOperationQueue mainQueue]];
    [_successCallbacks setObject:successCallback forKey:session];
    [_errorCallbacks setObject:errorCallback forKey:session];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:req];

    [task resume];
}

- (NSData *)fileFromAssetsLibrary: (NSString *)filepath
{
    __block NSData * tempData = nil;

    NSURL *assetUrl = [[NSURL alloc] initWithString:filepath];
    PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:@[assetUrl] options:nil];
    PHAsset *asset = result.firstObject;
    if (asset)
    {
        PHCachingImageManager *imageManager = [[PHCachingImageManager alloc] init];
        // Request an image for the asset from the PHCachingImageManager.
        [imageManager requestImageForAsset:asset targetSize:CGSizeMake(100.0f, 100.0f) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *image, NSDictionary *info)
         {
             NSLog(@"IMAGE: %@", image);
             tempData = UIImagePNGRepresentation(image);
         }];
    }
    return tempData;
}

- (NSData *)fileFromUrl: (NSString *)filepath
{
    NSURL *fileUrl = [[NSURL alloc] initWithString:filepath];
    return [NSData dataWithContentsOfURL: fileUrl];
}

- (NSString *)generateBoundaryString
{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    return [NSString stringWithFormat:@"----%@", uuid];
}

- (NSString *)mimeTypeForPath:(NSString *)filepath
{
    NSString *fileExtension = [filepath pathExtension];
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);

    if (contentType) {
        return contentType;
    }
    return @"application/octet-stream";
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
    NSLog(@"didReceiveResponse");
    RCTResponseSenderBlock successCallback = [_successCallbacks objectForKey:session];
    if (successCallback) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        NSLog(@"response status code: %ld", (long)[httpResponse statusCode]);
        successCallback(@[[NSString stringWithFormat:@"%ld", (long)[httpResponse statusCode]]]);
        [_successCallbacks removeObjectForKey:session];
    } else {
        RCTLogWarn(@"No callback registered for transfer success");
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if(error != nil) {
        NSLog(@"Error %@",[error userInfo]);
    }

    RCTResponseErrorBlock errorCallback = [_errorCallbacks objectForKey:session];
    if (errorCallback) {
        if(error != nil) {
            errorCallback(error);
            [_errorCallbacks removeObjectForKey:session];
        }
    } else {
        RCTLogWarn(@"No callback registered for transfer error");
    }

}

@synthesize bridge = _bridge;

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    float percentage = (totalBytesSent / (totalBytesExpectedToSend * 1.0f) * 100);
    //NSLog(@"%f%% Uploaded", prog);
    [self.bridge.eventDispatcher sendAppEventWithName:@"transferring" body:@{@"percentage": [NSString stringWithFormat:@"%f", percentage]}];
}

@end
