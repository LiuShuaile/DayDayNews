
#import "AVDownloadManager.h"
#import "NSString+Hash.h"

@interface AVDownloadManager()<NSCopying, NSURLSessionDelegate>

/** 保存所有任务(注：用下载地址md5后作为key) */
@property (nonatomic, strong) NSMutableDictionary *tasks;
/** 保存所有下载相关信息 */
@property (nonatomic, strong) NSMutableDictionary *sessionModels;

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation AVDownloadManager

- (NSMutableDictionary *)tasks
{
    if (!_tasks) {
        _tasks = [NSMutableDictionary dictionary];
    }
    return _tasks;
}

- (NSMutableDictionary *)sessionModels
{
    if (!_sessionModels) {
        _sessionModels = [NSMutableDictionary dictionary];
    }
    return _sessionModels;
}

- (NSOperationQueue *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}

static AVDownloadManager *_downloadManager;

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _downloadManager = [super allocWithZone:zone];
    });
    
    return _downloadManager;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    return _downloadManager;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadManager = [[self alloc] init];
    });
    
    return _downloadManager;
}

/**
 *  创建缓存目录文件
 */
- (void)createCacheDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:kDiskCacheDirectory]) {
        [fileManager createDirectoryAtPath:kDiskCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

/**
 *  开启任务下载资源
 */
- (void)download:(NSString *)url progress:(void (^)(NSInteger, NSInteger, CGFloat))progressBlock state:(void (^)(DownloadState))stateBlock
{
    if (!url) return;
    if ([self isCompletion:url]) {
        if (stateBlock) {
            stateBlock(DownloadStateCompleted);
        }
        NSLog(@"----该资源已下载完成");
        return;
    }
    //最大下载数量
    if ([self.tasks allKeys].count >3) {
        NSURLSessionDataTask *task = [self.tasks allValues][0];
        AVSessionModel * sessionModel = [self getSessionModel:task.taskIdentifier];
        [self pause:sessionModel.url];
        return;
    }
    //判断二次点击后状态切换
    if ([self.tasks valueForKey:HSFileName(url)]) {
//        [self handle:url];
        
        NSURLSessionDataTask *task = [self getTask:url];
        if (task.state == NSURLSessionTaskStateRunning) {
            [self pause:url];
        } else {
            [self start:url];
        }
        AVSessionModel * sessionModel = [self getSessionModel:task.taskIdentifier];
        sessionModel.progressBlock = progressBlock;
        sessionModel.stateBlock = stateBlock;
        return;
    }
    
    // 创建缓存目录文件
//    [self createCacheDirectory];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:self.operationQueue];
    
    // 创建流
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:kFileFullpath(url) append:YES];
    
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    // 设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", HSDownloadLength(url)];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    // 创建一个Data任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    NSUInteger taskIdentifier = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));
    [task setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
    
    // 保存任务
    [self.tasks setValue:task forKey:HSFileName(url)];
    
    AVSessionModel *sessionModel = [[AVSessionModel alloc] init];
    sessionModel.url = url;
    sessionModel.progressBlock = progressBlock;
    sessionModel.stateBlock = stateBlock;
    sessionModel.stream = stream;
    sessionModel.title = self.videodata.title;
    [self.sessionModels setValue:sessionModel forKey:@(task.taskIdentifier).stringValue];
    
    [self start:url];
}


- (void)handle:(NSString *)url
{
    NSURLSessionDataTask *task = [self getTask:url];
    if (task.state == NSURLSessionTaskStateRunning) {
        [self pause:url];
    } else {
        [self start:url];
    }
}

/**
 *  开始下载
 */
- (void)start:(NSString *)url
{
    NSURLSessionDataTask *task = [self getTask:url];
    [task resume];
    
    AVSessionModel * sessionModel = [self getSessionModel:task.taskIdentifier];
    if (sessionModel.stateBlock) {
        sessionModel.stateBlock(DownloadStateStart);
    }
}

/**
 *  暂停下载
 */
- (void)pause:(NSString *)url
{
    NSURLSessionDataTask *task = [self getTask:url];
    [task suspend];
    
    AVSessionModel * sessionModel = [self getSessionModel:task.taskIdentifier];
    if (sessionModel.stateBlock) {
        sessionModel.stateBlock(DownloadStateSuspended);
    }
//    [self getSessionModel:task.taskIdentifier].stateBlock(DownloadStateSuspended);
}

/**
 *  根据url获得对应的下载任务
 */
- (NSURLSessionDataTask *)getTask:(NSString *)url
{
    return (NSURLSessionDataTask *)[self.tasks valueForKey:HSFileName(url)];
}

/**
 *  根据url获取对应的下载信息模型
 */
- (AVSessionModel *)getSessionModel:(NSUInteger)taskIdentifier
{
    return (AVSessionModel *)[self.sessionModels valueForKey:@(taskIdentifier).stringValue];
}

/**
 *  判断该文件是否下载完成
 */
- (BOOL)isCompletion:(NSString *)url
{
    if ([self fileTotalLength:url] && HSDownloadLength(url) == [self fileTotalLength:url]) {
        return YES;
    }
    return NO;
}

/**
 *  查询该资源的下载进度值
 */
- (CGFloat)progress:(NSString *)url
{
    return [self fileTotalLength:url] == 0 ? 0.0 : 1.0 * HSDownloadLength(url) /  [self fileTotalLength:url];
}

/**
 *  获取该资源总大小
 */
- (NSInteger)fileTotalLength:(NSString *)url
{
    NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:HSTotalLengthFullpath];
    if (!plistDict) return 1;
    NSDictionary *item = plistDict[HSFileName(url)];
    if (!item || ![item isKindOfClass:[NSDictionary class]]) return 1;
    NSInteger totalLength = [item[@"totalLength"] integerValue];
    return totalLength;
//    return [[NSDictionary dictionaryWithContentsOfFile:HSTotalLengthFullpath][HSFileName(url)] integerValue];
}

#pragma mark - 删除
/**
 *  删除该资源
 */
- (void)deleteFile:(NSString *)url
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:kFileFullpath(url)]) {
        
        // 删除沙盒中的资源
        [fileManager removeItemAtPath:kFileFullpath(url) error:nil];
        // 删除任务
        [self.tasks removeObjectForKey:HSFileName(url)];
        [self.sessionModels removeObjectForKey:@([self getTask:url].taskIdentifier).stringValue];
        // 删除资源总长度
        if ([fileManager fileExistsAtPath:HSTotalLengthFullpath]) {
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:HSTotalLengthFullpath];
            [dict removeObjectForKey:HSFileName(url)];
            [dict writeToFile:HSTotalLengthFullpath atomically:YES];
            
        }
    }
}

/**
 *  清空所有下载资源
 */
//- (void)deleteAllFile
//{
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if ([fileManager fileExistsAtPath:HSCachesDirectory]) {
//        // 删除沙盒中所有资源
//        [fileManager removeItemAtPath:HSCachesDirectory error:nil];
//        // 删除任务
//        [[self.tasks allValues] makeObjectsPerformSelector:@selector(cancel)];
//        [self.tasks removeAllObjects];
//        
//        for (AVSessionModel *sessionModel in [self.sessionModels allValues]) {
//            [sessionModel.stream close];
//        }
//        [self.sessionModels removeAllObjects];
//        
//        // 删除资源总长度
//        if ([fileManager fileExistsAtPath:HSTotalLengthFullpath]) {
//            [fileManager removeItemAtPath:HSTotalLengthFullpath error:nil];
//        }
//    }
//}

#pragma mark - 代理
#pragma mark NSURLSessionDataDelegate
/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    AVSessionModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    // 打开流
    [sessionModel.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + HSDownloadLength(sessionModel.url);
    sessionModel.totalLength = totalLength;
    
    // 存储总长度
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:HSTotalLengthFullpath];
    if (dict == nil) dict = [NSMutableDictionary dictionary];
    
//    dict[HSFileName(sessionModel.url)] = @(totalLength);
    NSDictionary *itemInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              sessionModel.title,@"title",
                              @(totalLength),@"totalLength",
                              sessionModel.url,@"url",
                              nil];
    [dict setValue:itemInfo forKey:HSFileName(sessionModel.url)];
    [dict writeToFile:HSTotalLengthFullpath atomically:YES];
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

- (void)saveDownloadItemToPlist {
    //取得plist内容
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:HSTotalLengthFullpath];
    if (dict == nil) dict = [NSMutableDictionary dictionary];
    
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    AVSessionModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 写入数据
    [sessionModel.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSUInteger receivedSize = HSDownloadLength(sessionModel.url);
    NSUInteger expectedSize = sessionModel.totalLength;
    CGFloat progress = 1.0 * receivedSize / expectedSize;
    
    if (sessionModel.progressBlock) {
        sessionModel.progressBlock(receivedSize, expectedSize, progress);
    }
}

/**
 * 请求完毕（成功|失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    AVSessionModel *sessionModel = [self getSessionModel:task.taskIdentifier];
    if (!sessionModel) return;
    
    if ([self isCompletion:sessionModel.url]) {
        // 下载完成
        if (sessionModel.stateBlock) {
            sessionModel.stateBlock(DownloadStateCompleted);
        }
    } else if (error){
        // 下载失败
        if (sessionModel.stateBlock) {
            sessionModel.stateBlock(DownloadStateFailed);
        }
    }
    
    // 关闭流
    [sessionModel.stream close];
    sessionModel.stream = nil;
    
    // 清除任务
    [self.tasks removeObjectForKey:HSFileName(sessionModel.url)];
    [self.sessionModels removeObjectForKey:@(task.taskIdentifier).stringValue];
}

@end
