//
//  KKColumnItem.h
//  KKCommonTools
//
//  Created by finger on 17/3/15.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,SQLColumnType) {
    SQLColumnTypeInteger,
    SQLColumnTypeText,
    SQLColumnTypeFolat,
    SQLColumnTypeBlob,
    SQLColumnTypeUnknown
};

@interface KKSQLColumnItem : NSObject

@property(nonatomic)NSString *columnName;

@property(nonatomic)SQLColumnType columnType;

@property(nonatomic)id columnValue;

- (instancetype)initWithColName:(NSString *)colName colType:(SQLColumnType)colType colValue:(id)colValue;

#pragma mark -- 将列类型转换成sqlite数据支持的列类型

+ (NSString *)convertColumnType:(SQLColumnType)colType;

@end
