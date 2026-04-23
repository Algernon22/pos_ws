cmake_minimum_required(VERSION 3.8)
project(lio_to_mavros)

set(CMAKE_CXX_STANDARD 14)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)

add_executable(lio_to_mavros src/lio_to_mavros.cpp)

ament_target_dependencies(lio_to_mavros
  rclcpp
  geometry_msgs
  nav_msgs
)

install(TARGETS lio_to_mavros
  DESTINATION lib/${PROJECT_NAME}
)

# 关键部分：正确安装launch文件
install(DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
