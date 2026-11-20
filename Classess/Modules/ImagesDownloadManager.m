//
//  ImagesDownloadManager.m
//  OpenWeatherPlus
//
//  Created by he on 2019/10/30.
//  Copyright © 2019 QWeather. All rights reserved.
//

#import "ImagesDownloadManager.h"
#import "SDWebImagePrefetcher.h"
#import "SDImageCache.h"
#import <TBNetworkManager/TBRequestManager.h>
@implementation ImagesDownloadManager


/*
 *  批量下载图片资源
 *  imageURLs 图片地址数组 成员为String类型
 */
+ (void)downloadImagesWithURLs:(NSArray <NSString *> *)imageURLs {
    NSMutableArray *prefetchURLs = [NSMutableArray new];

    for (NSString *urlStr in imageURLs) {
        NSURL *url = [NSURL URLWithString:urlStr];
        if (url) {
            [prefetchURLs addObject:url];
        }
    }
    // 业务边界样本：SDWebImage 内部自建 session，传输层分段拿不到，但「批量预取」
    // 这个业务动作的成败与耗时是可见的。completed 只给完成数/跳过数、没有 NSError，
    // 所以跳过视为部分失败（status=206），全成功记 200——不伪造 HTTP 码。
    NSDate *startedAt = [NSDate date];
    [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:prefetchURLs progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {

    } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
        NSTimeInterval durationMs = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
        NSInteger status = noOfSkippedUrls > 0 ? 206 : 200;
        NSError *error = nil;
        if (noOfSkippedUrls > 0) {
            error = [NSError errorWithDomain:@"sdk://sdwebimage/prefetch"
                                        code:(NSInteger)noOfSkippedUrls
                                    userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"跳过 %lu/%lu", (unsigned long)noOfSkippedUrls, (unsigned long)(noOfFinishedUrls + noOfSkippedUrls)]}];
        }
        [TBBusinessMonitor recordExternalRequest:@"image.prefetch"
                                             url:@"sdk://sdwebimage/prefetch"
                                          status:status
                                      durationMs:durationMs
                                           error:error];
        [imageURLs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [ImagesDownloadManager imageForURL:obj];
        }];
        NSLog(@"安装成功");
    }];
}

//必要实现的协议方法, 不然会崩溃
+(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
   
}
/*
 *  根据图片地址获取图片
 *  imageURL 单个图片地址
 */
+ (UIImage *)imageForURL:(NSString *)imageURL {
    NSURL *url = [NSURL URLWithString:imageURL];
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:key];
//    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    return image;
}
@end
