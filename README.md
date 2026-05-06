# pos_ws

`pos_ws` 是一个基于 ROS 2 的定位工作空间，用于将 Livox LiDAR 数据接入定位链路，并将定位结果通过 `MAVROS` 输出至飞控系统。

## 前提条件

在运行本项目之前，请确保以下环境和依赖已经正确安装并配置完成：

- `Livox SDK2`
- `livox_ros_driver2`

## 构建项目

```bash
./build_pos_ws.sh
```

## 快速启动

```bash
./start_position_stack.sh
```

### 监视程序状态

```bash
./monitor_position_stack.sh
```

## 调试模式

当定位启动失败、结果异常或需要分模块排查问题时，可使用调试脚本启动各模块：

```bash
./start_position_debug.sh
```

该脚本基于 `tmux` 启动多窗口调试会话，并将日志保存到 `log/debug/<timestamp>/` 目录下。因此，在使用调试模式前，请确保系统已安装 `tmux`。

## 定位链路说明

完整定位数据流如下：

`Livox LiDAR -> Fast-LIO -> lio_to_mavros -> MAVROS -> 飞控`

1. `Livox LiDAR` 输出点云数据。
2. `Fast-LIO` 对激光雷达数据进行里程计与状态估计。
3. `lio_to_mavros` 将定位结果转换为 `MAVROS` 可接收的数据格式。
4. `MAVROS` 将定位信息转发至飞控。
5. 飞控使用外部定位结果参与状态估计或控制。
