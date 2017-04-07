//
//  WXQueryResultSet.m
//  WXCommonTools
//
//  Created by wangxutech on 17/3/16.
//  Copyright © 2017年 fingerfinger. All rights reserved.
//

#import "KKSQLQueryResultSet.h"
#import <UIKit/UIKit.h>
#import "KKSQLColumnItem.h"

@implementation KKSQLQueryResult
{
    NSMutableArray<KKSQLColumnItem*>* resultArray;
}

- (id)init
{
    self = [super init];
    if(self){
        resultArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [self freeResult];
}

#pragma mark -- 添加一个列对象

- (void)addColumnResult:(KKSQLColumnItem *)item
{
    [resultArray addObject:item];
}

#pragma mark -- 根据列名来获取相应的列值

- (NSString *)stringValueWithColumnName:(NSString *)colName
{
    for (KKSQLColumnItem *item in resultArray) {
        if([item.columnName isEqualToString:colName]){
            return item.columnValue ;
        }
    }
    
    return @"";
}

- (NSInteger)intValueWithColumnName:(NSString *)colName
{
    for (KKSQLColumnItem *item in resultArray) {
        if([item.columnName isEqualToString:colName]){
            return [item.columnValue integerValue];
        }
    }
    
    return 0;
}

- (CGFloat)floatValueWithColumnName:(NSString *)colName
{
    for (KKSQLColumnItem *item in resultArray) {
        if([item.columnName isEqualToString:colName]){
            return [item.columnValue doubleValue];
        }
    }
    
    return 0;
}

- (NSData *)dataValueWithColumnName:(NSString *)colName
{
    for (KKSQLColumnItem *item in resultArray) {
        if([item.columnName isEqualToString:colName]){
            return item.columnValue;
        }
    }
    
    return nil;
}

- (BOOL)boolValueWithColumnName:(NSString *)colName
{
    for (KKSQLColumnItem *item in resultArray) {
        if([item.columnName isEqualToString:colName]){
            return [item.columnValue boolValue];
        }
    }
    
    return NO;
}

#pragma mark -- 根据列的索引获取相应的列值

- (NSString *)stringValueWithColumnIndex:(NSInteger)index
{
    if(index >= resultArray.count){
        return @"";
    }
    
    KKSQLColumnItem *item = [resultArray objectAtIndex:index];
    
    return item.columnValue;
}

- (NSInteger)intValueWithColumnIndex:(NSInteger)index
{
    if(index >= resultArray.count){
        return 0;
    }
    
    KKSQLColumnItem *item = [resultArray objectAtIndex:index];
    
    return [item.columnValue integerValue];
}

- (CGFloat)floatValueWithColumnIndex:(NSInteger)index
{
    if(index >= resultArray.count){
        return 0;
    }
    
    KKSQLColumnItem *item = [resultArray objectAtIndex:index];
    
    return [item.columnValue doubleValue];
}

- (NSData *)dataValueWithColumnIndex:(NSInteger)index
{
    if(index >= resultArray.count){
        return nil;
    }
    
    KKSQLColumnItem *item = [resultArray objectAtIndex:index];
    
    return item.columnValue;
}

- (BOOL)boolValueWithColumnIndex:(NSInteger)index
{
    if(index >= resultArray.count){
        return false;
    }
    
    KKSQLColumnItem *item = [resultArray objectAtIndex:index];
    
    return [item.columnValue boolValue];
}

#pragma mark -- 根据列索引来获取列名

- (NSString *)columnNameAtIndex:(NSInteger)index
{
    if(index >= resultArray.count){
        return @"";
    }
    
    KKSQLColumnItem *item = [resultArray objectAtIndex:index];
    
    return item.columnName;
}

#pragma mark -- 根据列索引来获取列的数据类型

- (SQLColumnType)columnTypeAtIndex:(NSInteger)index
{
    if(index >= resultArray.count){
        return SQLColumnTypeUnknown;
    }
    
    KKSQLColumnItem *item = [resultArray objectAtIndex:index];
    
    return item.columnType;
}

#pragma mark -- 根据列名来获取列的数据类型

- (SQLColumnType)columnTypeWithColumnName:(NSString *)colName
{
    for (KKSQLColumnItem *item in resultArray) {
        if([item.columnName isEqualToString:colName]){
            return item.columnType;
        }
    }
    
    return SQLColumnTypeUnknown;
}

#pragma mark -- 本条查询结果中的总列数

- (NSInteger)numberOfColumnInResult
{
    return resultArray.count;
}

#pragma mark -- 清空结果

- (void)freeResult
{
    [resultArray removeAllObjects];
}

@end








@implementation KKSQLQueryResultSet
{
    NSInteger fetchIndex;
    NSMutableArray<KKSQLQueryResult*>* queryRstSet;
}

- (instancetype)init
{
    self = [super init];
    if(self){
        fetchIndex = 0 ;
        queryRstSet = [[NSMutableArray alloc]init];
    }
    return self ;
}

- (void)dealloc
{
    [self freeResultSet];
}

#pragma mark -- 本次查询的结果条数

- (NSInteger)numberOfResultInSet
{
    return queryRstSet.count ;
}

#pragma mark -- 添加一列记录

- (void)addQueryResult:(KKSQLQueryResult *)result
{
    [queryRstSet addObject:result];
}

#pragma mark -- 是否还有记录

- (BOOL)next
{
    BOOL bNextResult = false ;
    
    if(fetchIndex < queryRstSet.count){
        bNextResult = true ;
        fetchIndex ++;
    }
    
    return bNextResult;
}

- (void)seekToBegin
{
    fetchIndex = 0;
}

- (void)seekToEnd
{
    fetchIndex = queryRstSet.count;
}

/**
 跳转到第index条记录

 @param index 从1开始
 */
- (void)seekToIndex:(NSInteger)index
{
    if(index >= queryRstSet.count){
        index = queryRstSet.count + 1;
    }
    
    if(index <= 0){
        index = 1 ;
    }
    
    fetchIndex = index - 1 ;
}

#pragma mark -- 根据列名来获取相应的列值

- (NSString *)stringValueWithColumnName:(NSString *)colName
{
    if(fetchIndex > queryRstSet.count){
        return @"";
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result stringValueWithColumnName:colName];
    
}

- (NSInteger)intValueWithColumnName:(NSString *)colName
{
    if(fetchIndex > queryRstSet.count){
        return 0;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result intValueWithColumnName:colName];
}

- (CGFloat)floatValueWithColumnName:(NSString *)colName
{
    if(fetchIndex > queryRstSet.count){
        return 0;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result floatValueWithColumnName:colName];
}

- (NSData *)dataValueWithColumnName:(NSString *)colName
{
    if(fetchIndex > queryRstSet.count){
        return nil;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result dataValueWithColumnName:colName];
}

- (BOOL)boolValueWithColumnName:(NSString *)colName
{
    if(fetchIndex > queryRstSet.count){
        return false;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result boolValueWithColumnName:colName];
}

#pragma mark -- 根据列的索引获取相应的列值

- (NSString *)stringValueWithColumnIndex:(NSInteger)index
{
    if(fetchIndex > queryRstSet.count){
        return @"";
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result stringValueWithColumnIndex:index];
}

- (NSInteger)intValueWithColumnIndex:(NSInteger)index
{
    if(fetchIndex > queryRstSet.count){
        return 0;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result intValueWithColumnIndex:index];
}

- (CGFloat)floatValueWithColumnIndex:(NSInteger)index
{
    if(fetchIndex > queryRstSet.count){
        return 0;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result floatValueWithColumnIndex:index];
}

- (NSData *)dataValueWithColumnIndex:(NSInteger)index
{
    if(fetchIndex > queryRstSet.count){
        return nil;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result dataValueWithColumnIndex:index];
}

- (BOOL)boolValueWithColumnIndex:(NSInteger)index
{
    if(fetchIndex > queryRstSet.count){
        return false;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result boolValueWithColumnIndex:index];
}

#pragma mark -- 根据列索引来获取列名

- (NSString *)columnNameAtIndex:(NSInteger)index
{
    if(fetchIndex > queryRstSet.count){
        return false;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result columnNameAtIndex:index];
}

#pragma mark -- 根据列索引来获取列的数据类型

- (SQLColumnType)columnTypeAtIndex:(NSInteger)index
{
    if(fetchIndex > queryRstSet.count){
        return false;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result columnTypeAtIndex:index];
}

#pragma mark -- 根据列名来获取列的数据类型

- (SQLColumnType)columnTypeWithColumnName:(NSString *)colName
{
    if(fetchIndex > queryRstSet.count){
        return false;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result columnTypeWithColumnName:colName];
}

#pragma mark -- 本条查询结果中列的总数

- (NSInteger)numberOfColumnInResult
{
    if(fetchIndex > queryRstSet.count){
        return false;
    }
    
    KKSQLQueryResult *result = [queryRstSet objectAtIndex:fetchIndex-1];
    
    return [result numberOfColumnInResult];
}

#pragma mark -- 清空结果集

- (void)freeResultSet
{
    for(KKSQLQueryResult *result in queryRstSet){
        [result freeResult];
    }
    
    [queryRstSet removeAllObjects];
}

@end
