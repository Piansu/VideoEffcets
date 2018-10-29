//
//  ObjLoader.hpp
//  OpenGLDemo_GLK
//
//  Created by suruochang on 2018/10/25.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBJModel : NSObject

@property (nonatomic, assign, readonly) int size;

@property (nonatomic, strong, readonly) NSData *vertexData;
@property (nonatomic, strong, readonly) NSData *uvCoordinateData;
@property (nonatomic, strong, readonly) NSData *normalData;

- (instancetype)initWithResourcePath:(NSString *)path;

@end

