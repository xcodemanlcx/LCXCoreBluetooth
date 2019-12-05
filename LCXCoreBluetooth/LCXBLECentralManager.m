//
//  LCXBLECentralManager.m
//  LCXCoreBluetooth
//
//  Created by lcx on 2019/12/5.
//  Copyright © 2019 lcx. All rights reserved.
//

#import "LCXBLECentralManager.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSMutableDictionary *_deviceDic;

@interface LCXBLECentralManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>

//中心管理者
@property (nonatomic ,strong) CBCentralManager *centralManager;
//外设
@property (nonatomic ,strong) CBPeripheral *peripheral;
//特征
@property (nonatomic ,strong)CBCharacteristic *characteristic;

@property (nonatomic ,assign) NSInteger style;

@end

@implementation LCXBLECentralManager

+ (instancetype)sharedManager {
    static LCXBLECentralManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        _deviceDic = @{}.mutableCopy;
    });
    return sharedManager;
}

#pragma mark - 一 外部调用

#pragma mark  1. 初始化
- (void)scanDevice
{
    if (_centralManager == nil) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }else{
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        [_deviceDic removeAllObjects];
    }
}

// 上文中发现特征之后, 发送下行指令的时候其实就是向蓝牙中写入数据
// 例:
// 发送检查蓝牙命令
- (void)writeCheckBleData
{
    _style = 1;
    // 发送下行指令(发送一条)
    NSData *data = [@"硬件工程师提供给你的指令, 类似于5E16010203...这种很长一串" dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

// 断开连接
- (void)disconnectPeripheral{
    /**
     -- 断开连接后回调didDisconnectPeripheral
     -- 注意断开后如果要重新扫描这个外设，需要重新调用[self.centralManager scanForPeripheralsWithServices:nil options:nil];
     */
    [self.centralManager cancelPeripheralConnection:self.peripheral];
}

#pragma mark - 二 CBCentralManagerDelegate

#pragma mark 2.搜索扫描外围设备
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            //未知
            NSLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            //重新设置
            NSLog(@">>>CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            //不支持
            NSLog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            //未授权
            NSLog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            //断电
            NSLog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
        {
            // 开始扫描周围的外设
            NSLog(@">>>CBCentralManagerStatePoweredOn");
            
            /*
             1 两个参数为Nil表示默认扫描所有可见蓝牙设备。
             -- 注意：第一个参数是用来扫描有指定服务的外设。然后有些外设的服务是相同的，比如都有FFF5服务，那么都会发现；而有些外设的服务是不可见的，就会扫描不到设备。
             -- 成功扫描到外设后调用didDiscoverPeripheral
             */
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        }
            break;
        default:
            break;
    }
}

// 发现外设
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    
    /**/
    NSLog(@"Find device:%@", peripheral.name);
    if (peripheral.name&&peripheral){
        if (!_deviceDic[peripheral.name]) {
            if([peripheral.name hasPrefix:@"根据设备名过滤"]){
                //添加设备
                [_deviceDic setObject:peripheral forKey:peripheral.name];
                //停止扫描
                [_centralManager stopScan];
                // 将设备信息传到外面的页面(VC), 构成扫描到的设备列表
                if (_discoverPeripheral) {
                    _discoverPeripheral(_deviceDic);
                }
            }
        }
    }
}

#pragma mark 3.连接外围设备:点击连接按钮调用
- (void)connectDeviceWithPeripheral:(CBPeripheral *)peripheral
{
    [self.centralManager connectPeripheral:peripheral options:nil];
}

// 连接外设--成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    //连接成功后停止扫描，节省内存
    [central stopScan];
    self.peripheral = peripheral;
    // 1 注意：要先设置代理，
    peripheral.delegate = self;
    // 2 寻找指定UUID的服务，参数为nil表示扫描所有服务；成功发现服务，回调didDiscoverServices；比如我关心的是"FFE0",参数就可以为@[[CBUUID UUIDWithString:@"FFE0"]];
    [peripheral discoverServices:@[[CBUUID UUIDWithString:@"你要用的服务UUID"]]];
    if (_didConnectBle) {
        _didConnectBle();
    }
}

//连接外设——失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%@", error);
}

//取消与外设的连接回调
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%@", peripheral);
}

#pragma mark - 三 CBPeripheralDelegate

#pragma mark 4. 获得外围设备的服务

//发现服务回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    //NSLog(@"didDiscoverServices,Error:%@",error);
    for (CBService *service in peripheral.services)
    {
        //NSLog(@"UUID:%@",service.UUID);
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:@"你要用的服务UUID"]])
        {
            NSLog(@"Find Service:%@",service);
            
            //寻找服务的特征
            [peripheral discoverCharacteristics:NULL forService:service];
            break;
        }
    }
}

#pragma mark 5、获得服务的特征；
 //发现特征回调
/**
 --  发现特征后，可以根据特征的properties进行：读readValueForCharacteristic、写writeValue、订阅通知setNotifyValue、扫描特征的描述discoverDescriptorsForCharacteristic。
 **/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"你要用的特征UUID"]]) {

            self.characteristic = characteristic;
           
            /**选择读取一次，或实时订阅
             
             1.接收一次(是读一次信息，还是数据经常变实时接收视情况而定, 再决定使用哪个);
             2.读取成功回调didUpdateValueForCharacteristic;
             */
            BOOL isReadValue = YES;
            if (isReadValue) {
                // 读取
                [peripheral readValueForCharacteristic:characteristic];

            }else{
                // 订阅通知, 实时接收
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            // 发送下行指令(发送一条)
            NSData *data = [@"硬件工程师给我的指令, 发送给蓝牙该指令, 蓝牙会给我返回一条数据" dataUsingEncoding:NSUTF8StringEncoding];
            // 将指令写入蓝牙
                [self.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
        /**
         -- 当发现characteristic有descriptor,回调didDiscoverDescriptorsForCharacteristic
         */
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
}

#pragma mark  6.从外围设备读取数据
 //获取值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    // characteristic.value就是蓝牙给我们的值(我这里是json格式字符串)
    if ([characteristic.value isKindOfClass:NSString.class]) {
            NSData *jsonData = [(NSString *)characteristic.value dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        // 将字典传出去就可以使用了
        if (_didReadSucess) {
            _didReadSucess(dataDic);
        }
    }
}

//中心读取外设实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (characteristic.isNotifying) {
        //继续读取
        [peripheral readValueForCharacteristic:characteristic];
    } else {
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        //取消外设连接
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

//有Descriptors时的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
}

#pragma mark 7. 给外围设备发送（写入）数据

//数据写入成功回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"写入成功");
    if (_didWriteSucess) {
        _didWriteSucess(_style);
    }
}

@end
