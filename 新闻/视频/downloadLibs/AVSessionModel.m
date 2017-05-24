

#import "AVSessionModel.h"

@implementation AVSessionModel

- (NSString *)title {
    NSString *string = @"";
    NSArray *arr = [_title componentsSeparatedByString:@"/"];
    string = [arr lastObject];
    return string;
}

@end
