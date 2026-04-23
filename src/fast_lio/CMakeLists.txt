cmake_minimum_required(VERSION 3.8)
project(fast_lio)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 编译选项
add_compile_options(-std=c++17 -O3 -pthread -fexceptions)

# 根目录定义
add_definitions(-DROOT_DIR=\"${CMAKE_CURRENT_SOURCE_DIR}/\")

# CPU架构检测
message("Current CPU archtecture: ${CMAKE_SYSTEM_PROCESSOR}")
if(CMAKE_SYSTEM_PROCESSOR MATCHES "(x86)|(X86)|(amd64)|(AMD64)")
  include(ProcessorCount)
  ProcessorCount(N)
  message("Processer number: ${N}")
  if(N GREATER 4)
    add_definitions(-DMP_EN -DMP_PROC_NUM=3)
    message("core for MP: 3")
  elseif(N GREATER 3)
    add_definitions(-DMP_EN -DMP_PROC_NUM=2)
    message("core for MP: 2")
  else()
    add_definitions(-DMP_PROC_NUM=1)
  endif()
else()
  add_definitions(-DMP_PROC_NUM=1)
endif()

# OpenMP
find_package(OpenMP QUIET)
if(OpenMP_FOUND)
  add_compile_options(${OpenMP_CXX_FLAGS})
  # 添加链接选项
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
endif()

# Python开发包
find_package(Python3 REQUIRED COMPONENTS Development)

# ROS2依赖
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(std_msgs REQUIRED)
find_package(std_srvs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2 REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(rosidl_default_generators REQUIRED)  # 添加这个，用于消息生成

# PCL和Eigen
find_package(PCL REQUIRED COMPONENTS common io filters)
find_package(Eigen3 REQUIRED)

# ========== 消息生成部分 ==========
# 定义消息文件
set(msg_files
  "msg/Pose6D.msg"
  "msg/CustomPoint.msg"
  "msg/CustomMsg.msg"
)

# 生成消息接口
rosidl_generate_interfaces(${PROJECT_NAME}
  ${msg_files}
  DEPENDENCIES geometry_msgs std_msgs
)

# 导出消息运行时依赖
ament_export_dependencies(rosidl_default_runtime)
# ==================================

# 创建可执行文件
add_executable(fastlio_mapping 
  src/laserMapping.cpp 
  include/ikd-Tree/ikd_Tree.cpp 
  src/preprocess.cpp
)

# 包含目录 - 必须包含生成消息的目录
target_include_directories(fastlio_mapping PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_cpp  # 生成的消息头文件在这里
  ${PCL_INCLUDE_DIRS}
  ${EIGEN3_INCLUDE_DIRS}
  ${Python3_INCLUDE_DIRS}
)

# 链接库
target_link_libraries(fastlio_mapping
  ${PCL_LIBRARIES}
  ${Python3_LIBRARIES}
  OpenMP::OpenMP_CXX
)

# ROS2依赖
ament_target_dependencies(fastlio_mapping
  rclcpp
  sensor_msgs
  nav_msgs
  geometry_msgs
  std_msgs
  std_srvs
  visualization_msgs
  tf2_ros
  tf2
  pcl_conversions
)

# 链接生成的消息类型支持（关键！）
rosidl_target_interfaces(fastlio_mapping
  ${PROJECT_NAME} "rosidl_typesupport_cpp")

# 安装
install(TARGETS fastlio_mapping
  DESTINATION lib/${PROJECT_NAME}
)

install(DIRECTORY config launch rviz
  DESTINATION share/${PROJECT_NAME}
)

ament_package()