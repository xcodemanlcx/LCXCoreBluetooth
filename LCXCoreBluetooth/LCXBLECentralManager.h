//
//  LCXBLECentralManager.h
//  LCXCoreBluetooth
//
//  Created by lcx on 2019/12/5.
//  Copyright © 2019 lcx. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCXBLECentralManager : NSObject

+ (instancetype)sharedManager;
// 1 开始扫描
- (void)scanDevice;
// 2 发送检查蓝牙命令
- (void)writeCheckBleData;
// 3 断开连接
- (void)disconnectPeripheral;

#pragma mark - block:delegate

// 1 发现外设列表
@property (nonatomic ,copy) void (^discoverPeripheral)(NSMutableDictionary *peripheralDic);
//2 连接外设-成功
@property (nonatomic ,copy) dispatch_block_t didConnectBle;
//3 数据读取成功
@property (nonatomic ,copy) void (^didReadSucess)(NSDictionary * dataDic);
//4 数据写入成功
@property (nonatomic ,copy) void (^didWriteSucess)(NSInteger style);

@end

NS_ASSUME_NONNULL_END
