//
//  FMDBTableViewController.m
//  Assemble
//
//  Created by 李丝思 on 16/9/24.
//  Copyright © 2016年 思. All rights reserved.
//

#import "FMDBTableViewController.h"
#import "FMDB.h"
@interface FMDBTableViewController ()
@property(nonatomic,strong) FMDatabase *db;
@property(nonatomic,strong) NSMutableArray *userArray;

@end

@implementation FMDBTableViewController
- (IBAction)addBtn:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"新增用户" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
        textField.placeholder = @"用户名";
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
        textField.placeholder = @"电话";
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction *action) {
        NSLog(@"%@",alertController.textFields[0].text);
        [self addUser:alertController.textFields[0].text iphone:alertController.textFields[1].text];
          [self selectTabel];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction *action) {
        // 点击按钮后的方法直接在这里面写
     
    }];
     
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userArray=[NSMutableArray array];
    //数据的路径，放在沙盒的cache下面
    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [cacheDir stringByAppendingPathComponent:@"user.sqlite"];
    
    //创建并且打开一个数据库
    _db = [FMDatabase databaseWithPath:filePath];
    
    BOOL flag = [_db open];
    if (flag) {
        NSLog(@"数据库打开成功");
    }else{
        NSLog(@"数据库打开失败");
    }
   BOOL user =  [self isTableOK:@"t_User"];
//      [self clearTableData];c
    if (user==YES) {
        NSLog(@"表存在");
//        [self addUser];
        [self selectTabel];
        
    }else{
       NSLog(@"表不存在");
        [self addTabe];
    }
}

/**
 创建表
 */
-(void)addTabe
{
    //创建表
    BOOL create =  [_db executeUpdate:@"create table if not exists t_User(id integer primary key  autoincrement, name text,iphone text)"];
    
    if (create) {
        NSLog(@"创建表成功");
    }else{
        NSLog(@"创建表失败");
    }
    

}
-(void)selectTabel
{
    if ([_db open]) {
    [self.userArray removeAllObjects];
    FMResultSet *set = [_db executeQuery:@"select * from t_User "];
    while ([set next]) {
        NSString *name =  [set stringForColumn:@"name"];
        NSString *iphone=[set stringForColumn:@"iphone"];
        NSDictionary *dic=@{@"name":name,@"iphone":iphone};
        [self.userArray addObject:dic];
        NSLog(@"name : %@",dic);
    }
        [_db close];
    }
    [self.tableView reloadData];
}

/**
 插入数据
  */
-(void)addUser:(NSString *)string iphone:(NSString *)iphone
{
     if ([_db open]) {
    BOOL insert = [_db executeUpdate:@"insert into t_User (name,iphone) values(?,?)",string,iphone];
    if (insert) {
        NSLog(@"插入数据成功");
    }else{
        NSLog(@"插入数据失败");
    }
         [_db close];
     }
}

/**
 修改

 @param string <#string description#>
 */
-(void)updata:(NSString *)string key:(NSString *)key
{
    if ([_db open]) {
        NSString *sql = [NSString stringWithFormat:@"update t_User set iphone = '%@'  where name = '%@'",string,key];
    BOOL update = [_db executeUpdate:sql];
    if (update) {
        NSLog(@"更新数据成功");
    }else{
        NSLog(@"更新数据失败");
    }
        [_db close];
    }

}


/**
 删除

 @param string <#string description#>
 */
-(void)delete:(NSString *)string
{
     if ([_db open]) {
    BOOL delete = [_db executeUpdate:@"delete from t_User where name like ?",string];
    if (delete) {
        NSLog(@"删除数据成功");
    }else{
        NSLog(@"删除数据失败");
    }
    [_db close];
}
}
- (void)clearTableData
{
    if ([_db executeUpdate:@"DELETE FROM t_User"]) {
        NSLog(@"ok clear");
    }else{
        NSLog(@"fail to clear");
    }
}
- (BOOL) isTableOK:(NSString *)tableName
{
    
    FMResultSet *rs = [_db executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", tableName];
    while ([rs next])
    {
        NSInteger count = [rs intForColumn:@"count"];
        if (0 == count)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static  NSString *idef=@"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:idef];
    if (!cell) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:idef];
    }
    NSDictionary *dic=self.userArray[indexPath.row];
    cell.detailTextLabel.text=dic[@"iphone"];
    cell.textLabel.text=dic[@"name"];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        [self delete:self.userArray[indexPath.row]];
        [self selectTabel];
    }
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
     NSDictionary *dic=self.userArray[indexPath.row];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"修改用户" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
        
        textField.text = dic[@"iphone"];
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction *action) {
        NSLog(@"%@",alertController.textFields[0].text);
        [self updata:alertController.textFields[0].text key: dic[@"name"]];
        [self selectTabel];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction *action) {
        // 点击按钮后的方法直接在这里面写
        
    }];
    
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];


}

@end
