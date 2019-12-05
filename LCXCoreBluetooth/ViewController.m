//
//  ViewController.m
//  LCXCoreBluetooth
//
//  Created by lcx on 2019/12/4.
//  Copyright © 2019 lcx. All rights reserved.
//

#import "ViewController.h"
#import "LCXBLECentralManager.h"

@interface ViewController ()

//中心管理者
@property (nonatomic ,strong) LCXBLECentralManager *lcxBLECentralManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /**
    代码参考： https://www.jianshu.com/p/0c31487bb7c5；
    流程图和概念参考：https://blog.csdn.net/aluoshiyi/article/details/82870289；
     */
        
    _lcxBLECentralManager = [LCXBLECentralManager sharedManager];
    [_lcxBLECentralManager scanDevice];
    _lcxBLECentralManager.discoverPeripheral = ^(NSMutableDictionary * _Nonnull peripheralDic) {
        NSLog(@"发现外设列表");
    };
    _lcxBLECentralManager.didConnectBle = ^{
        NSLog(@"连接外设成功");
    };
    _lcxBLECentralManager.didReadSucess = ^(NSDictionary * _Nonnull dataDic) {
        NSLog(@"读取成功");
    };
    _lcxBLECentralManager.didWriteSucess = ^(NSInteger style) {
        NSLog(@"数据写入成功");
    };
    
}

- (IBAction)scanAction:(id)sender {
    [_lcxBLECentralManager scanDevice];
}

- (IBAction)stopAction:(id)sender {
    [_lcxBLECentralManager disconnectPeripheral];
}

@end
