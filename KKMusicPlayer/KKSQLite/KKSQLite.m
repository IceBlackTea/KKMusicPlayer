//
//  WXSqliteDataBase.m
//
//  Created by finger on 17/3/15.
//  Copyright © 2017年 fingerfinger. All rights reserved.
//

#import "KKSQLite.h"
#import <UIKit/UIKit.h>
#import "KKSQLColumnItem.h"
#import "sqlite3.h"

@implementation KKSQLite
{
    sqlite3 *database;
    NSString *dbFilePath;
}

- (id)initDataBaseWithPath:(NSString *)dbPath
{
    self = [super init];
    
    if (self){
        
        dbFilePath = dbPath ;
        
        if([self openDatabase]){
            return self ;
        }
        
    }
    
    return nil;
}

#pragma mark -- 打开数据库

- (bool)openDatabase
{
    if(database){
        return true ;
    }
    
    if(dbFilePath == nil || [dbFilePath isEqualToString:@""]){
        return false ;
    }
    
    if (sqlite3_open([dbFilePath UTF8String] , &database) != SQLITE_OK){
        
        sqlite3_close(database);
        database = nil ;
        
        NSLog(@"Open database error！");
        
        return false;
        
    }
    
    return true ;
}

#pragma mark -- 关闭数据库

- (void)closeDataBase
{
    if(database){
        sqlite3_close(database);
        database = nil ;
    }
}

#pragma mark -- 创建数据表

- (bool)createTableWithName:(NSString*)tbName columns:(NSArray<KKSQLColumnItem*>*)colArray
{
    if(!database){
        return false;
    }
    
    if(!tbName.length || !colArray.count){
        return false ;
    }
    
    //创建数据库表
    NSInteger count = colArray.count ;
    
    NSMutableString *strColumn = [[NSMutableString alloc]init];
    
    for(int i = 0 ; i < count ; i++){
        
        KKSQLColumnItem *item = [colArray objectAtIndex:i];
        
        NSString *colName = item.columnName;
        SQLColumnType columnType = item.columnType;
        
        NSString *colType = [KKSQLColumnItem convertColumnType:columnType];
        
        if(colName.length && colType.length){
            if( i < count -1 ){
                [strColumn appendString:[NSString stringWithFormat:@"%@ %@,",colName,colType]];
            }else{
                [strColumn appendString:[NSString stringWithFormat:@"%@ %@",colName,colType]];
            }
        }
        
    }
    
    char *errorMsg = NULL ;
    
    NSString *createTable =[ NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@);",tbName,strColumn];
    
    if (sqlite3_exec(database, [createTable UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK){
        
        NSLog(@"Create database table error: %s", errorMsg);
        
        return false;
    }
    
    return true ;
}

#pragma mark -- 数据列增删改

- (bool)insertTableColumn:(NSString*)tbName colName:(NSString*)colName cloType:(SQLColumnType)columnType
{
    if(!database){
        return false ;
    }
    
    NSString *colType = [KKSQLColumnItem convertColumnType:columnType];
    
    if(!tbName.length ||
       !colName.length ||
       !colType.length){
        return false ;
    }
    
    NSString *sqlStr = [NSString stringWithFormat:@"alter table %@ add %@ %@", tbName,colName,colType];
    
    sqlite3_stmt *stmt = nil;
    
    if (sqlite3_prepare_v2(database, [sqlStr UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        
        if (sqlite3_step(stmt) == SQLITE_DONE) {
            
            sqlite3_finalize(stmt);
            
            return true;
        }
        
    }
    
    sqlite3_finalize(stmt);
    
    return false;
}

- (bool)deleteTableColumn:(NSString*)tbName colName:(NSString*)colName
{
    if(!database){
        return false ;
    }
    
    if(!tbName.length ||
       !colName.length){
        return false ;
    }
    
    NSString *sqlStr = [NSString stringWithFormat:@"alter table %@ drop column %@", tbName,colName];
    
    sqlite3_stmt *stmt = nil;
    if (sqlite3_prepare_v2(database, [sqlStr UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_DONE) {
            sqlite3_finalize(stmt);
            return true;
        }
    }
    sqlite3_finalize(stmt);
    
    return false;
}

- (bool)alterColumnType:(NSString*)tbName colName:(NSString*)colName colType:(SQLColumnType)newColType
{
    if(!database){
        return false ;
    }
    
    NSString *newType = [KKSQLColumnItem convertColumnType:newColType];
    
    if(!tbName.length ||
       !colName.length ||
       !newType.length){
        return false ;
    }
    
    NSString *sqlStr = [NSString stringWithFormat:@"alter table %@ alter column %@ %@", tbName,colName,newType];
    
    sqlite3_stmt *stmt = nil;
    if (sqlite3_prepare_v2(database, [sqlStr UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_DONE) {
            sqlite3_finalize(stmt);
            return true;
        }
    }
    sqlite3_finalize(stmt);
    
    return false;
}

#pragma mark -- 获取一行数据

- (KKSQLQueryResultSet *)queryOneRowWithTableName:(NSString *)tbName
                                           columnName:(NSString *)columnName
                                          columnValue:(NSString *)columnValue
{
    if(!database){
        return nil;
    }
    
    if(!tbName.length){
        return nil ;
    }
    
    KKSQLQueryResultSet *resultSet = [[KKSQLQueryResultSet alloc]init];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %@ ;", tbName , columnName , columnValue];
    
    sqlite3_stmt *statement = nil ;
    
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
        
        while (sqlite3_step(statement) == SQLITE_ROW){
            
            NSInteger colCount = sqlite3_column_count(statement);
            
            KKSQLQueryResult *result = [[KKSQLQueryResult alloc]init];
            
            for(int i = 0 ; i < colCount ; i++){
                
                KKSQLColumnItem *item = [[KKSQLColumnItem alloc]init];
                
                NSString *colName = [NSString stringWithUTF8String:(char*)sqlite3_column_name(statement,i)];
                NSInteger colType = sqlite3_column_type(statement,i) ;
                
                if(SQLITE_INTEGER == colType){
                    
                    NSInteger value = sqlite3_column_int(statement, i);
                    item.columnName = colName;
                    item.columnType = SQLColumnTypeInteger;
                    item.columnValue = [NSNumber numberWithInteger:value];
                    
                }
                
                if(SQLITE_FLOAT == colType){
                    
                    double value = sqlite3_column_double(statement, i);
                    item.columnName = colName;
                    item.columnType = SQLColumnTypeFolat;
                    item.columnValue = [NSNumber numberWithDouble:value];
                    
                }
                
                if(SQLITE_TEXT ==  colType){
                    
                    NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)];
                    item.columnName = colName;
                    item.columnType = SQLColumnTypeText;
                    item.columnValue = value;
                    
                }
                
                if(SQLITE_BLOB == colType){
                    
                    item.columnName = colName;
                    item.columnType = SQLColumnTypeBlob;
                    
                    NSInteger length = sqlite3_column_bytes(statement, i);
                    const void *blobData = sqlite3_column_blob(statement, i);
                    NSData *data = [NSData dataWithBytes:blobData length:length];
                    item.columnValue = data;
                    
                }
                
                [result addColumnResult:item];
                
            }
            
            [resultSet addQueryResult:result];
            
        }
    }
    
    sqlite3_finalize(statement);
    
    return resultSet ;
}

#pragma mark -- 获取表的所有数据

- (KKSQLQueryResultSet *)loadAllDataWithTableName:(NSString*)tbName
{
    if(!database){
        return nil;
    }
    
    if(!tbName.length){
        return nil ;
    }
    
    KKSQLQueryResultSet *resultSet = [[KKSQLQueryResultSet alloc]init];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@;", tbName];
    
    sqlite3_stmt *statement = nil ;
    
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
        
        while (sqlite3_step(statement) == SQLITE_ROW){
            
            KKSQLQueryResult *result = [[KKSQLQueryResult alloc]init];
            
            NSInteger colCount = sqlite3_column_count(statement);
            
            for(int i = 0 ; i < colCount ; i++){
                
                KKSQLColumnItem *item = [[KKSQLColumnItem alloc]init];
                
                NSString *colName = [NSString stringWithUTF8String:(char*)sqlite3_column_name(statement,i)];
                NSInteger colType = sqlite3_column_type(statement,i) ;
                
                if(SQLITE_INTEGER == colType){
                    
                    NSInteger value = sqlite3_column_int(statement, i);
                    item.columnName = colName;
                    item.columnType = SQLColumnTypeInteger;
                    item.columnValue = [NSNumber numberWithInteger:value];
                    
                }
                
                if(SQLITE_FLOAT == colType){
                    
                    double value = sqlite3_column_double(statement, i);
                    item.columnName = colName;
                    item.columnType = SQLColumnTypeFolat;
                    item.columnValue = [NSNumber numberWithDouble:value];
                    
                }
                
                if(SQLITE_TEXT == colType){
                    
                    NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)];
                    item.columnName = colName;
                    item.columnType = SQLColumnTypeText;
                    item.columnValue = value;
                    
                }
                
                if(SQLITE_BLOB == colType){
                    
                    item.columnName = colName;
                    item.columnType = SQLColumnTypeBlob;
                    
                    NSInteger length = sqlite3_column_bytes(statement, i);
                    const void *blobData = sqlite3_column_blob(statement, i);
                    NSData *data = [NSData dataWithBytes:blobData length:length];
                    item.columnValue = data;
                    
                }
                
                [result addColumnResult:item];
            }
            
            [resultSet addQueryResult:result];
        }
    }
    
    sqlite3_finalize(statement);
    
    return resultSet ;
}

#pragma mark -- 添加一列数据

- (bool)addOneRowDataToTable:(NSString*)tbName data:(NSArray<KKSQLColumnItem *>*)dataArray
{
    if(!database){
        return false;
    }
    
    if(!tbName.length){
        return false ;
    }
    
    if(!dataArray.count){
        return false ;
    }
    
    NSInteger colCount = dataArray.count ;
    
    NSString *strAdd = @"";
    NSMutableString *strCol = [[NSMutableString alloc]init];
    NSMutableString *strValue = [[NSMutableString alloc]init];
    
    //拼接sql语句
    for(int i = 0 ; i < colCount ; i++){
        
        KKSQLColumnItem *item = [dataArray objectAtIndex:i];
        
        if( i < colCount - 1){
            [strCol appendString:[NSString stringWithFormat:@"%@,",item.columnName]];
            [strValue appendString:[NSString stringWithFormat:@"%@,",@"?"]];
        }else{
            [strCol appendString:[NSString stringWithFormat:@"%@",item.columnName]];
            [strValue appendString:@"?"];
        }
        
    }
    strAdd = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@) VALUES(%@);",tbName,strCol,strValue];
    
    sqlite3_stmt *stmt = nil ;
    
    if (sqlite3_prepare_v2(database, [strAdd UTF8String], -1, &stmt, nil) == SQLITE_OK){
        
        //绑定列值并入库
        for(int i = 1 ; i < colCount + 1; i++){
            
            KKSQLColumnItem *item = [dataArray objectAtIndex:i-1];
            
            SQLColumnType colType = item.columnType ;
            
            if(SQLColumnTypeInteger ==  colType){
                int value = [item.columnValue intValue];
                sqlite3_bind_int(stmt, i, value);
                continue ;
            }
            
            if(SQLColumnTypeFolat ==  colType){
                double value = [item.columnValue doubleValue];
                sqlite3_bind_double(stmt, i, value);
                continue ;
            }
            
            if(SQLColumnTypeText ==  colType){
                NSString *value = item.columnValue;
                sqlite3_bind_text(stmt, i, [value UTF8String], -1, NULL);
                continue ;
            }
            
            if(SQLColumnTypeBlob ==  colType){
                NSData *value = item.columnValue;
                sqlite3_bind_blob(stmt, i, [value bytes],(int)[value length], NULL);
                continue ;
            }
            
        }
        
        if (sqlite3_step(stmt) != SQLITE_DONE){
            sqlite3_finalize(stmt);
            return false;
        }
    }
    
    sqlite3_finalize(stmt);
    
    return true;
}

#pragma mark -- 更新某一条数据

- (BOOL)updateRowWithTableName:(NSString *)tbName columnName:(NSString *)columnName columnValue:(NSString *)columnValue data:(NSArray<KKSQLColumnItem *>*)dataArray
{
    if(!database){
        return false;
    }
    
    if(!tbName.length){
        return false ;
    }
    
    if(!dataArray.count){
        return false ;
    }
    
    NSInteger colCount = dataArray.count ;
    
    NSString *strUpdate = @"";
    NSMutableString *strCol = [[NSMutableString alloc]init];
    
    //拼接sql语句
    for(int i = 0 ; i < colCount ; i++){
        
        KKSQLColumnItem *item = [dataArray objectAtIndex:i];
        
        if( i < colCount - 1){
            [strCol appendString:[NSString stringWithFormat:@"%@=?,",item.columnName]];
        }else{
            [strCol appendString:[NSString stringWithFormat:@"%@=?",item.columnName]];
        }
        
    }
    strUpdate = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?;",tbName,strCol,columnName];
    
    sqlite3_stmt *stmt = nil ;
    
    if (sqlite3_prepare_v2(database, [strUpdate UTF8String], -1, &stmt, nil) == SQLITE_OK){
        
        //绑定列值并入库
        for(int i = 1 ; i < colCount + 1; i++){
            
            KKSQLColumnItem *item = [dataArray objectAtIndex:i-1];
            
            SQLColumnType colType = item.columnType ;
            
            if(SQLColumnTypeInteger ==  colType){
                int value = [item.columnValue intValue];
                sqlite3_bind_int(stmt, i, value);
                continue ;
            }
            
            if(SQLColumnTypeFolat ==  colType){
                double value = [item.columnValue doubleValue];
                sqlite3_bind_double(stmt, i, value);
                continue ;
            }
            
            if(SQLColumnTypeText ==  colType){
                NSString *value = [item.columnValue stringValue];
                sqlite3_bind_text(stmt, i, [value UTF8String], -1, NULL);
                continue ;
            }
            
            if(SQLColumnTypeBlob ==  colType){
                NSData *value = item.columnValue;
                sqlite3_bind_blob(stmt, i, [value bytes],(int)[value length], NULL);
                continue ;
            }
            
        }
        
        //绑定条件
        sqlite3_bind_text(stmt, colCount + 1, [columnValue UTF8String], -1, NULL);
        
        if (sqlite3_step(stmt) != SQLITE_DONE){
            sqlite3_finalize(stmt);
            return false;
        }
    }
    
    sqlite3_finalize(stmt);
    
    return true;
}

#pragma mark -- 删除一行数据

- (bool)deleteDataFromTable:(NSString*)tbName columnName:(NSString *)columnName columnValue:(NSString*)columnValue
{
    if(!database){
        return false;
    }
    
    if(!tbName.length){
        return false ;
    }
    
    NSString *strDel = [NSString stringWithFormat:@"delete from %@ where %@ = ?;",tbName,columnName];
    
    sqlite3_stmt *stmt = nil ;
    if (sqlite3_prepare_v2(database, [strDel UTF8String], -1, &stmt, nil) == SQLITE_OK){
        sqlite3_bind_text(stmt, 1, [columnValue UTF8String], -1, NULL);
        if (sqlite3_step(stmt) != SQLITE_DONE){
            sqlite3_finalize(stmt);
            return false;
        }
    }
    sqlite3_finalize(stmt);
    
    return  true;
}

#pragma mark -- 清空数据

- (bool)clearTable:(NSString*)tbName
{
    if(!database){
        return false;
    }
    
    if(!tbName.length){
        return false ;
    }
    
    NSString *strDel = [NSString stringWithFormat:@"DELETE FROM %@ ;",tbName];
    
    sqlite3_stmt *stmt = nil ;
    if (sqlite3_prepare_v2(database, [strDel UTF8String], -1, &stmt, nil) == SQLITE_OK){
        if (sqlite3_step(stmt) != SQLITE_DONE){
            sqlite3_finalize(stmt);
            return false;
        }
    }
    sqlite3_finalize(stmt);
    
    return  true;
}

#pragma mark -- 获取表的所有列数

-(int)tableCloumnCount:(NSString*)strTableName
{
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ ;", strTableName];
    
    sqlite3_stmt *stmt = nil;
    
    if(sqlite3_prepare_v2(database, [query UTF8String], -1, &stmt, nil) != SQLITE_OK){
        sqlite3_finalize(stmt);
        return -1;
    }
    
    int col_count = sqlite3_column_count(stmt);
    
    sqlite3_finalize(stmt);
    
    return col_count;
}

#pragma mark -- 获取表的行数

- (int)tableRowCount:(NSString*)strTableName
{
    if(!database){
        return 0;
    }
    
    if(!strTableName.length){
        return 0 ;
    }
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@;", strTableName];
    
    NSInteger rowCount = 0 ;
    sqlite3_stmt *statement = nil ;
    
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
        if(sqlite3_step(statement) == SQLITE_ROW){
            rowCount = sqlite3_column_int(statement, 0);
        }
    }
    
    sqlite3_finalize(statement);
    
    return rowCount ;
}

#pragma mark -- sql语句操作(除查询以外的所有操作)

- (BOOL)executeUpdate:(NSString*)sql,...
{
    va_list args;
    
    va_start(args, sql);
    
    BOOL result = [self executeUpdate:sql argArray:nil argList:args];
    
    va_end(args);
    
    return result;
}

- (BOOL)executeUpdateWithFormat:(NSString*)format, ...
{
    va_list args;
    
    va_start(args, format);
    
    NSMutableString *sqlOutput = [NSMutableString stringWithCapacity:[format length]];
    NSMutableArray *arguments = [NSMutableArray array];
    
    [self extractSQL:format argumentsList:args intoString:sqlOutput arguments:arguments];
    
    va_end(args);
    
    return [self executeUpdate:sqlOutput withArgumentsInArray:arguments];
}

- (BOOL)executeUpdate:(NSString *)sql withArgumentsInArray:(NSArray *)arguments
{
    return [self executeUpdate:sql argArray:arguments argList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql argArray:(NSArray *)arguments argList:(va_list)arglist
{
    if (!database) {
        return false;
    }
    
    if(!sql.length){
        return false ;
    }
    
    sqlite3_stmt *pStmt = nil;
    
    int rc = sqlite3_prepare_v2(database, [sql UTF8String], -1, &pStmt, 0);
    
    if (SQLITE_OK != rc) {
        sqlite3_finalize(pStmt);
        return NO;
    }
    
    id obj;
    int idx = 0;
    int queryCount = sqlite3_bind_parameter_count(pStmt);
    
    while (idx < queryCount) {
        
        if(arglist){
            obj = va_arg(arglist, id);
        }else{
            if (arguments && idx < (int)[arguments count]) {
                obj = [arguments objectAtIndex:(NSUInteger)idx];
            }
        }
        
        idx++;
        
        [self bindObject:obj toColumn:idx inStatement:pStmt];
    }
    
    
    if (idx != queryCount) {
        sqlite3_finalize(pStmt);
        return NO;
    }
    
    if (SQLITE_DONE == sqlite3_step(pStmt)) {
        return true;
    }
    
    return false ;
}

#pragma mark -- sql语句查询

- (KKSQLQueryResultSet *)executeQuery:(NSString*)sql, ...
{
    va_list args;
    
    va_start(args, sql);
    
    KKSQLQueryResultSet *result = [self executeQuery:sql argArray:nil argList:args];
    
    va_end(args);
    
    return result;
}

- (KKSQLQueryResultSet *)executeQueryWithFormat:(NSString*)format, ...
{
    va_list args;
    
    va_start(args, format);
    
    NSMutableString *sqlOutput = [NSMutableString stringWithCapacity:[format length]];
    NSMutableArray *arguments = [NSMutableArray array];
    
    [self extractSQL:format argumentsList:args intoString:sqlOutput arguments:arguments];
    
    va_end(args);
    
    return [self executeQuery:sqlOutput argArray:arguments argList:nil];
}

- (KKSQLQueryResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments
{
    return [self executeQuery:sql argArray:arguments argList:nil];
}

- (KKSQLQueryResultSet *)executeQuery:(NSString*)sql argArray:(NSArray *)arguments argList:(va_list)arglist
{
    if (!database) {
        return nil;
    }
    
    if(!sql.length){
        return nil ;
    }
    
    sqlite3_stmt *pStmt = nil;
    
    int rc = sqlite3_prepare_v2(database, [sql UTF8String], -1, &pStmt, 0);
    
    if (SQLITE_OK != rc) {
        sqlite3_finalize(pStmt);
        return nil;
    }
    
    id obj;
    int idx = 0;
    int queryCount = sqlite3_bind_parameter_count(pStmt);
    
    while (idx < queryCount) {
        
        if(arglist){
            obj = va_arg(arglist, id);
        }else{
            if (arguments && idx < (int)[arguments count]) {
                obj = [arguments objectAtIndex:(NSUInteger)idx];
            }
        }
        
        idx++;
        
        [self bindObject:obj toColumn:idx inStatement:pStmt];
    }
    
    
    if (idx != queryCount) {
        sqlite3_finalize(pStmt);
        return nil;
    }
    
    KKSQLQueryResultSet *resultSet = [[KKSQLQueryResultSet alloc]init];
    
    while (sqlite3_step(pStmt) == SQLITE_ROW){
        
        KKSQLQueryResult *result = [[KKSQLQueryResult alloc]init];
        
        NSInteger colCount = sqlite3_column_count(pStmt);
        
        for(int i = 0 ; i < colCount ; i++){
            
            KKSQLColumnItem *item = [[KKSQLColumnItem alloc]init];
            
            NSString *colName = [NSString stringWithUTF8String:(char*)sqlite3_column_name(pStmt,i)];
            NSInteger colType = sqlite3_column_type(pStmt,i) ;
            
            if(SQLITE_INTEGER == colType){
                
                NSInteger value = sqlite3_column_int(pStmt, i);
                item.columnName = colName;
                item.columnType = SQLColumnTypeInteger;
                item.columnValue = [NSNumber numberWithInteger:value];
                
            }
            
            if(SQLITE_FLOAT == colType){
                
                double value = sqlite3_column_double(pStmt, i);
                item.columnName = colName;
                item.columnType = SQLColumnTypeFolat;
                item.columnValue = [NSNumber numberWithDouble:value];
                
            }
            
            if(SQLITE_TEXT == colType){
                
                NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(pStmt, i)];
                item.columnName = colName;
                item.columnType = SQLColumnTypeText;
                item.columnValue = value;
                
            }
            
            if(SQLITE_BLOB == colType){
                
                item.columnName = colName;
                item.columnType = SQLColumnTypeBlob;
                
                NSInteger length = sqlite3_column_bytes(pStmt, i);
                const void *blobData = sqlite3_column_blob(pStmt, i);
                NSData *data = [NSData dataWithBytes:blobData length:length];
                item.columnValue = data;
                
            }
            
            [result addColumnResult:item];
        }
        
        [resultSet addQueryResult:result];
    }
    
    sqlite3_finalize(pStmt);
    
    return resultSet ;
}

#pragma mark -- 解析sql语句，将可变参数的变量提取出来

- (void)extractSQL:(NSString *)sql argumentsList:(va_list)argList intoString:(NSMutableString *)cleanedSQL arguments:(NSMutableArray *)arguments
{
    NSUInteger length = [sql length];
    
    unichar last = '\0';
    
    for (NSUInteger i = 0; i < length; ++i) {
        
        id argObj = nil;
        
        unichar current = [sql characterAtIndex:i];
        
        unichar add = current;
        
        if (last == '%') {
            
            switch (current)
            {
                case '@':
                {
                    argObj = va_arg(argList, id);
                    break;
                }
                case 'c':
                {
                    argObj = [NSString stringWithFormat:@"%c", va_arg(argList, int)];
                    break;
                }
                case 's':
                {
                    argObj = [NSString stringWithUTF8String:va_arg(argList, char*)];
                    break;
                }
                case 'd':
                case 'D':
                case 'i':
                {
                    argObj = [NSNumber numberWithInt:va_arg(argList, int)];
                    break;
                }
                case 'u':
                case 'U':
                {
                    argObj = [NSNumber numberWithUnsignedInt:va_arg(argList, unsigned int)];
                    break;
                }
                case 'h':
                {
                    i++;
                    if (i < length && [sql characterAtIndex:i] == 'i') {
                        //  warning: second argument to 'va_arg' is of promotable type 'short'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                        argObj = [NSNumber numberWithShort:(short)(va_arg(argList, int))];
                    }else if (i < length && [sql characterAtIndex:i] == 'u') {
                        // warning: second argument to 'va_arg' is of promotable type 'unsigned short'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                        argObj = [NSNumber numberWithUnsignedShort:(unsigned short)(va_arg(argList, uint))];
                    }else {
                        i--;
                    }
                    break;
                }
                case 'q':
                {
                    i++;
                    if (i < length && [sql characterAtIndex:i] == 'i') {
                        argObj = [NSNumber numberWithLongLong:va_arg(argList, long long)];
                    }else if (i < length && [sql characterAtIndex:i] == 'u') {
                        argObj = [NSNumber numberWithUnsignedLongLong:va_arg(argList, unsigned long long)];
                    }else {
                        i--;
                    }
                    break;
                }
                case 'f':
                {
                    argObj = [NSNumber numberWithDouble:va_arg(argList, double)];
                    break;
                }
                case 'g':
                {
                    // warning: second argument to 'va_arg' is of promotable type 'float'; this va_arg has undefined behavior because arguments will be promoted to 'double'
                    argObj = [NSNumber numberWithFloat:(float)(va_arg(argList, double))];
                    break;
                }
                case 'l':
                {
                    i++;
                    
                    if (i < length) {
                        
                        unichar next = [sql characterAtIndex:i];
                        
                        if (next == 'l') {
                            i++;
                            if (i < length && [sql characterAtIndex:i] == 'd') {
                                //%lld
                                argObj = [NSNumber numberWithLongLong:va_arg(argList, long long)];
                            }else if (i < length && [sql characterAtIndex:i] == 'u') {
                                //%llu
                                argObj = [NSNumber numberWithUnsignedLongLong:va_arg(argList, unsigned long long)];
                            }else {
                                i--;
                            }
                        }else if (next == 'd') {
                            //%ld
                            argObj = [NSNumber numberWithLong:va_arg(argList, long)];
                        }else if (next == 'u') {
                            //%lu
                            argObj = [NSNumber numberWithUnsignedLong:va_arg(argList, unsigned long)];
                        }else {
                            i--;
                        }
                    }else {
                        i--;
                    }
                    break;
                }
                default:break;
            }
        }else if (current == '%') {
            add = '\0';
        }
        
        if (argObj != nil) {
            [cleanedSQL appendString:@"?"];
            [arguments addObject:argObj];
        }else if (add == (unichar)'@' && last == (unichar) '%') {
            [cleanedSQL appendFormat:@"NULL"];
        }else if (add != '\0') {
            [cleanedSQL appendFormat:@"%C", add];
        }
        last = current;
    }
}

#pragma mark -- 将具体的值与sql语句中的预定义变量绑定

- (void)bindObject:(id)obj toColumn:(int)idx inStatement:(sqlite3_stmt*)pStmt
{
    if ((!obj) || ((NSNull *)obj == [NSNull null])) {
        
        sqlite3_bind_null(pStmt, idx);
        
    }else if ([obj isKindOfClass:[NSData class]]) {
        
        const void *bytes = [obj bytes];
        if (!bytes) {
            bytes = "";
        }
        sqlite3_bind_blob(pStmt, idx, bytes, (int)[obj length], SQLITE_STATIC);
        
    }else if ([obj isKindOfClass:[NSDate class]]) {
        
//        if (self.hasDateFormatter){
//            sqlite3_bind_text(pStmt, idx, [[self stringFromDate:obj] UTF8String], -1, SQLITE_STATIC);
//        }else{
            sqlite3_bind_double(pStmt, idx, [obj timeIntervalSince1970]);
//        }
        
    }else if ([obj isKindOfClass:[NSNumber class]]) {
        
        if (strcmp([obj objCType], @encode(char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj charValue]);
        }else if (strcmp([obj objCType], @encode(unsigned char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedCharValue]);
        }else if (strcmp([obj objCType], @encode(short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj shortValue]);
        }else if (strcmp([obj objCType], @encode(unsigned short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedShortValue]);
        }else if (strcmp([obj objCType], @encode(int)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj intValue]);
        }else if (strcmp([obj objCType], @encode(unsigned int)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedIntValue]);
        }else if (strcmp([obj objCType], @encode(long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longValue]);
        }else if (strcmp([obj objCType], @encode(unsigned long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongValue]);
        }else if (strcmp([obj objCType], @encode(long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longLongValue]);
        }else if (strcmp([obj objCType], @encode(unsigned long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongLongValue]);
        }else if (strcmp([obj objCType], @encode(float)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj floatValue]);
        }else if (strcmp([obj objCType], @encode(double)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj doubleValue]);
        }else if (strcmp([obj objCType], @encode(BOOL)) == 0) {
            sqlite3_bind_int(pStmt, idx, ([obj boolValue] ? 1 : 0));
        }else {
            sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
        }
    }else {
        sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
    }
}

@end
