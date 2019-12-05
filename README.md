# LCXCoreBluetooth
蓝牙中心模式封装与概念、流程说明

#### 概念
* 中心和外设（peripheral和central）
* 服务和特征、描述(service and characteristic，Descriptor)

#### 中心模式基本流程

* 创建中心管理者；
* 扫描外设；
* 连接外设；
* 获取外设服务；
* 获取服务特征；
* 读取外设数据（单次读取或订阅通知）；
* 给外设发送数据；

#### 说明
* ios每次可接受90个字节, 安卓每次可接收20个字节, 具体数字应该是与蓝牙模块有关；
* 一个peripheral有多个service；
* 一个service有多个characteristic；
* 每个characteristic有属性Descriptor；

#### 参考
* [代码参考](https://www.jianshu.com/p/0c31487bb7c5);
* [流程图和概念参考](https://blog.csdn.net/aluoshiyi/article/details/82870289)；
