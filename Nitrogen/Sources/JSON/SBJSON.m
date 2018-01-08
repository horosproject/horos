/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/
/*
 Copyright (C) 2007-2009 Stig Brautaset. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SBJSON.h"

@implementation SBJSON

- (id)init {
    self = [super init];
    if (self) {
        jsonWriter = [SBJsonWriter new];
        jsonParser = [SBJsonParser new];
        [self setMaxDepth:512];

    }
    return self;
}

- (void)dealloc {
    [jsonWriter release];
    [jsonParser release];
    [super dealloc];
}

#pragma mark Writer 


- (NSString *)stringWithObject:(id)obj {
    NSString *repr = [jsonWriter stringWithObject:obj];
    if (repr)
        return repr;
    
    [errorTrace release];
    errorTrace = [[jsonWriter errorTrace] mutableCopy];
    return nil;
}

/**
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p *error can be interrogated to find the cause of the error.
 
 @param value any instance that can be represented as a JSON fragment
 @param allowScalar wether to return json fragments for scalar objects
 @param error used to return an error by reference (pass NULL if this is not desired)
 
@deprecated Given we bill ourselves as a "strict" JSON library, this method should be removed.
 */
- (NSString*)stringWithObject:(id)value allowScalar:(BOOL)allowScalar error:(NSError**)error {
    
    NSString *json = allowScalar ? [jsonWriter stringWithFragment:value] : [jsonWriter stringWithObject:value];
    if (json)
        return json;

    [errorTrace release];
    errorTrace = [[jsonWriter errorTrace] mutableCopy];
    
    if (error)
        *error = [errorTrace lastObject];
    return nil;
}

/**
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p error can be interrogated to find the cause of the error.
 
 @param value any instance that can be represented as a JSON fragment
 @param error used to return an error by reference (pass NULL if this is not desired)
 
 @deprecated Given we bill ourselves as a "strict" JSON library, this method should be removed.
 */
- (NSString*)stringWithFragment:(id)value error:(NSError**)error {
    return [self stringWithObject:value
                      allowScalar:YES
                            error:error];
}

/**
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p error can be interrogated to find the cause of the error.
 
 @param value a NSDictionary or NSArray instance
 @param error used to return an error by reference (pass NULL if this is not desired)
 */
- (NSString*)stringWithObject:(id)value error:(NSError**)error {
    return [self stringWithObject:value
                      allowScalar:NO
                            error:error];
}

#pragma mark Parsing

- (id)objectWithString:(NSString *)repr {
    id obj = [jsonParser objectWithString:repr];
    if (obj)
        return obj;

    [errorTrace release];
    errorTrace = [[jsonParser errorTrace] mutableCopy];
    
    return nil;
}

/**
 Returns the object represented by the passed-in string or nil on error. The returned object can be
 a string, number, boolean, null, array or dictionary.
 
 @param value the json string to parse
 @param allowScalar whether to return objects for JSON fragments
 @param error used to return an error by reference (pass NULL if this is not desired)
 
 @deprecated Given we bill ourselves as a "strict" JSON library, this method should be removed.
 */
- (id)objectWithString:(id)value allowScalar:(BOOL)allowScalar error:(NSError**)error {

    id obj = allowScalar ? [jsonParser fragmentWithString:value] : [jsonParser objectWithString:value];
    if (obj)
        return obj;
    
    [errorTrace release];
    errorTrace = [[jsonParser errorTrace] mutableCopy];

    if (error)
        *error = [errorTrace lastObject];
    return nil;
}

/**
 Returns the object represented by the passed-in string or nil on error. The returned object can be
 a string, number, boolean, null, array or dictionary.
 
 @param repr the json string to parse
 @param error used to return an error by reference (pass NULL if this is not desired)
 
 @deprecated Given we bill ourselves as a "strict" JSON library, this method should be removed. 
 */
- (id)fragmentWithString:(NSString*)repr error:(NSError**)error {
    return [self objectWithString:repr
                      allowScalar:YES
                            error:error];
}

/**
 Returns the object represented by the passed-in string or nil on error. The returned object
 will be either a dictionary or an array.
 
 @param repr the json string to parse
 @param error used to return an error by reference (pass NULL if this is not desired)
 */
- (id)objectWithString:(NSString*)repr error:(NSError**)error {
    return [self objectWithString:repr
                      allowScalar:NO
                            error:error];
}



#pragma mark Properties - parsing

- (NSUInteger)maxDepth {
    return jsonParser.maxDepth;
}

- (void)setMaxDepth:(NSUInteger)d {
     jsonWriter.maxDepth = jsonParser.maxDepth = d;
}


#pragma mark Properties - writing

- (BOOL)humanReadable {
    return jsonWriter.humanReadable;
}

- (void)setHumanReadable:(BOOL)x {
    jsonWriter.humanReadable = x;
}

- (BOOL)sortKeys {
    return jsonWriter.sortKeys;
}

- (void)setSortKeys:(BOOL)x {
    jsonWriter.sortKeys = x;
}

@end
