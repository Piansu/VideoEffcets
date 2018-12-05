//
//  NSString+image.m
//  OpenGLDemo_GLK
//
//  Created by suruochang on 2018/12/1.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import "NSString+image.h"
#import <UIKit/UIKit.h>

@implementation NSString (image)

- (UIImage *)imageWithAttributes:(NSDictionary *)attributes
{
    CGSize tsize = [self sizeWithAttributes:attributes];
    
    UIGraphicsBeginImageContextWithOptions(tsize, NO, 0);
    
    [self drawInRect:CGRectMake(0, 0, tsize.width, tsize.height) withAttributes:attributes];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
