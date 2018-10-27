//
//  ObjLoader.cpp
//  OpenGLDemo_GLK
//
//  Created by suruochang on 2018/10/25.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#include <vector>
#include <stdio.h>
#include <string>
#include <cstring>
//#include <map>
//#include <vector>
//#include <functional>
#include <simd/simd.h>

#import "ObjLoader.h"


bool loadOBJ(
             const char * path,
             std::vector<simd::float3> & out_vertices,
             std::vector<simd::float2> & out_uvs,
             std::vector<simd::float3> & out_normals
             ){
    printf("Loading OBJ file %s...\n", path);
    
    std::vector<unsigned int> vertexIndices, uvIndices, normalIndices;
    std::vector<simd::float3> temp_vertices;
    std::vector<simd::float2> temp_uvs;
    std::vector<simd::float3> temp_normals;
    
    
    FILE * file = fopen(path, "r");
    if( file == NULL ){
        printf("Impossible to open the file ! Are you in the right path ? See Tutorial 1 for details\n");
        getchar();
        return false;
    }
    
    while( 1 ){
        
        char lineHeader[128];
        // read the first word of the line
        int res = fscanf(file, "%s", lineHeader);
        if (res == EOF)
            break; // EOF = End Of File. Quit the loop.
        
        // else : parse lineHeader
        
        if ( strcmp( lineHeader, "v" ) == 0 ){
            float x, y, z;
            fscanf(file, "%f %f %f\n", &x, &y, &z );
            simd::float3 vertex = {x, y, z};
            temp_vertices.push_back(vertex);
            
        }else if ( strcmp( lineHeader, "vt" ) == 0 ){
            
            float x, y;
            fscanf(file, "%f %f\n", &x, &y );
            simd::float2 uv = {x, y};
            uv.y = -uv.y; // Invert V coordinate since we will only use DDS texture, which are inverted. Remove if you want to use TGA or BMP loaders.
            temp_uvs.push_back(uv);
            
        }else if ( strcmp( lineHeader, "vn" ) == 0 ){
            float x, y, z;
            fscanf(file, "%f %f %f\n", &x, &y, &z );
            simd::float3 normal = {x, y, z};
            temp_normals.push_back(normal);
        }else if ( strcmp( lineHeader, "f" ) == 0 ){

            unsigned int vertexIndex[3], uvIndex[3], normalIndex[3];
            int matches = fscanf(file, "%d/%d/%d %d/%d/%d %d/%d/%d\n",
                                 &vertexIndex[0], &uvIndex[0], &normalIndex[0],
                                 &vertexIndex[1], &uvIndex[1], &normalIndex[1],
                                 &vertexIndex[2], &uvIndex[2], &normalIndex[2] );
            if (matches != 9){
                printf("File can't be read by our simple parser :-( Try exporting with other options\n");
                fclose(file);
                return false;
            }
            vertexIndices.push_back(vertexIndex[0]);
            vertexIndices.push_back(vertexIndex[1]);
            vertexIndices.push_back(vertexIndex[2]);
            uvIndices    .push_back(uvIndex[0]);
            uvIndices    .push_back(uvIndex[1]);
            uvIndices    .push_back(uvIndex[2]);
            normalIndices.push_back(normalIndex[0]);
            normalIndices.push_back(normalIndex[1]);
            normalIndices.push_back(normalIndex[2]);
        }else{
            // Probably a comment, eat up the rest of the line
            char stupidBuffer[1000];
            fgets(stupidBuffer, 1000, file);
        }
        
    }
    
    // For each vertex of each triangle
    for( unsigned int i=0; i<vertexIndices.size(); i++ ){
        
        // Get the indices of its attributes
        unsigned int vertexIndex = vertexIndices[i];
        unsigned int uvIndex = uvIndices[i];
        unsigned int normalIndex = normalIndices[i];
        
        // Get the attributes thanks to the index
        simd::float3 vertex = temp_vertices[ vertexIndex-1 ];
        simd::float2 uv = temp_uvs[ uvIndex-1 ];
        simd::float3 normal = temp_normals[ normalIndex-1 ];
        
        // Put the attributes in buffers
        out_vertices.push_back(vertex);
        out_uvs     .push_back(uv);
        out_normals .push_back(normal);
        
    }
    fclose(file);
    return true;
}

@implementation OBJModel

- (instancetype)initWithResourcePath:(NSString *)path;
{
    std::vector<simd::float3> out_vertices;
    std::vector<simd::float2> out_uvs;
    std::vector<simd::float3> out_normals;
    
    self = [super init];
    if (self) {
        
        bool result = loadOBJ(path.UTF8String, out_vertices, out_uvs, out_normals);
        if (result == true)
        {
            _size = out_vertices.size();
            
            NSData *vertexData = [NSData dataWithBytes:&out_vertices[0] length:sizeof(simd::float3) * out_vertices.size()];
            _vertexData = vertexData;
            
            NSData *uvData = [NSData dataWithBytes:&out_uvs[0] length:sizeof(simd::float2) * out_uvs.size()];
            _uvCoordinateData = uvData;
            
            NSData *normalData = [NSData dataWithBytes:&out_normals[0] length:sizeof(simd::float3) * out_normals.size()];
            _normalData = normalData;
            
        }
    }
    
    return self;
}

@end



