//
//  ViewController.m
//  Bluetooth_D
//
//  Created by idea on 2018/6/27.
//  Copyright © 2018年 idea. All rights reserved.
//


#import "ViewController.h"
#import "JWBluetoothManage.h"

#define WeakSelf __block __weak typeof(self)weakSelf = self;
@interface ViewController () <UITableViewDataSource,UITableViewDelegate>{
    JWBluetoothManage * manage;
}
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSMutableArray * dataSource; //设备列表
@property (nonatomic, strong) NSMutableArray * rssisArray; //信号强度 可选择性使用

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"蓝牙列表";
    self.dataSource = @[].mutableCopy;
    self.rssisArray = @[].mutableCopy;
    [self _createTableView];
    manage = [JWBluetoothManage sharedInstance];
    WeakSelf
    [manage beginScanPerpheralSuccess:^(NSArray<CBPeripheral *> *peripherals, NSArray<NSNumber *> *rssis) {
        weakSelf.dataSource = [NSMutableArray arrayWithArray:peripherals];
        weakSelf.rssisArray = [NSMutableArray arrayWithArray:rssis];
        [weakSelf.tableView reloadData];
    } failure:^(CBManagerState status) {
        [ProgressShow alertView:self.view Message:[ProgressShow getBluetoothErrorInfo:status] cb:nil];
    }];
    manage.disConnectBlock = ^(CBPeripheral *perpheral, NSError *error) {
        NSLog(@"设备已经断开连接！");
        weakSelf.title = @"蓝牙列表";
    };
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"打印" style:UIBarButtonItemStylePlain target:self action:@selector(printe)];
    
}
- (void)printe{
    if (manage.stage != JWScanStageCharacteristics) {
        [ProgressShow alertView:self.view Message:@"打印机正在准备中..." cb:nil];
        return;
    }
    JWPrinter *printer = [[JWPrinter alloc] init];
    NSString *str1 = @"==============收据=============";
    NSString *title = @"***订单";
    [printer appendText:str1 alignment:HLTextAlignmentCenter];
    [printer appendNewLine];
    [printer appendText:title alignment:HLTextAlignmentCenter fontSize:HLFontSizeTitleMiddle];
    [printer appendNewLine];
    [printer appendSeperatorLine];
    [printer appendTitle:@"数量  产品" value:@"总计"];
    [printer appendSeperatorLine];
    [printer appendNewLine];
    [printer appendTitle:@" 1    南丰蜜桔1kg" value:@"126.80" fontSize:8];
    [printer appendNewLine];
    NSString *str2 = @"总计- - - - - - - - - - - -26.00";
    NSString *str3 = @"============订单明细============";
    [printer appendText:str2 alignment:HLTextAlignmentCenter];
    [printer appendNewLine];
    [printer appendText:str3 alignment:HLTextAlignmentCenter];
    [printer appendNewLine];
    [printer appendTitle:@"支付金额:" value:@"1520.80"];
    [printer appendTitle:@"支付方式:" value:@"微信支付"];
    [printer appendTitle:@"订单编号:" value:@"3180523120800905637" valueOffset:150];
    [printer appendTitle:@"操作员:" value:@"张晓明"];
    [printer appendNewLine];
    [printer appendFooter:@"\n\n欢迎您再次光临!\n\n客服电话:\n\n400-500-600"];
    [printer appendNewLine];
    [printer appendSeperatorLine];
    NSData *mainData = [printer getFinalData];
    [[JWBluetoothManage sharedInstance] sendPrintData:mainData completion:^(BOOL completion, CBPeripheral *connectPerpheral,NSString *error) {
        if (completion) {
            NSLog(@"打印成功");
        }else{
            NSLog(@"写入错误---:%@",error);
        }
    }];
}
-(void)viewWillAppear:(BOOL)animated{
    WeakSelf
    [super viewWillAppear:animated];
    [manage autoConnectLastPeripheralCompletion:^(CBPeripheral *perpheral, NSError *error) {
        if (!error) {
            [ProgressShow alertView:self.view Message:@"连接成功！" cb:nil];
            weakSelf.title = [NSString stringWithFormat:@"已连接-%@",perpheral.name];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }else{
            [ProgressShow alertView:self.view Message:error.domain cb:nil];
        }
    }];
    
}
#pragma mark tableview medthod
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    CBPeripheral *peripherral = [self.dataSource objectAtIndex:indexPath.row];
    if (peripherral.state == CBPeripheralStateConnected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.textLabel.text = [NSString stringWithFormat:@"名称:%@",peripherral.name];
    NSNumber * rssis = self.rssisArray[indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"强度:%@",rssis];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CBPeripheral *peripheral = [self.dataSource objectAtIndex:indexPath.row];
    [manage connectPeripheral:peripheral completion:^(CBPeripheral *perpheral, NSError *error) {
        if (!error) {
            [ProgressShow alertView:self.view Message:@"连接成功！" cb:nil];
            self.title = [NSString stringWithFormat:@"已连接-%@",perpheral.name];
            dispatch_async(dispatch_get_main_queue(), ^{
                [tableView reloadData];
            });
        }else{
            [ProgressShow alertView:self.view Message:error.domain cb:nil];
        }
    }];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (void) _createTableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 64) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.tableFooterView = [UIView new];
        if ([_tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [_tableView setSeparatorInset:UIEdgeInsetsZero];
        }
        if ([_tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [_tableView setLayoutMargins:UIEdgeInsetsZero];
        }
    }
    if (![self.view.subviews containsObject:_tableView]) {
        [self.view addSubview:_tableView];
    }else{
        [_tableView reloadData];
    }
}
@end
