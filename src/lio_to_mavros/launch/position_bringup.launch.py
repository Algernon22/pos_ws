from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription, TimerAction
from launch.conditions import IfCondition
from launch.launch_description_sources import AnyLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    start_mavros = LaunchConfiguration("start_mavros")
    fcu_url = LaunchConfiguration("fcu_url")
    tgt_system = LaunchConfiguration("tgt_system")
    mavros_namespace = LaunchConfiguration("mavros_namespace")
    livox_publish_freq = LaunchConfiguration("livox_publish_freq")
    lidar_frame_id = LaunchConfiguration("lidar_frame_id")
    fastlio_config_file = LaunchConfiguration("fastlio_config_file")
    use_fastlio_rviz = LaunchConfiguration("use_fastlio_rviz")
    odom_topic = LaunchConfiguration("odom_topic")
    vision_topic = LaunchConfiguration("vision_topic")
    odom_out_topic = LaunchConfiguration("odom_out_topic")
    publish_odom = LaunchConfiguration("publish_odom")

    livox_config = PathJoinSubstitution(
        [FindPackageShare("livox_ros_driver2"), "config", "MID360_config.json"]
    )
    mavros_launch = PathJoinSubstitution(
        [FindPackageShare("mavros"), "launch", "px4.launch"]
    )
    fastlio_config = PathJoinSubstitution(
        [FindPackageShare("fast_lio"), "config", fastlio_config_file]
    )
    fastlio_rviz = PathJoinSubstitution(
        [FindPackageShare("fast_lio"), "rviz", "fastlio.rviz"]
    )

    mavros_node = IncludeLaunchDescription(
        AnyLaunchDescriptionSource(mavros_launch),
        condition=IfCondition(start_mavros),
        launch_arguments={
            "fcu_url": fcu_url,
            "tgt_system": tgt_system,
            "namespace": mavros_namespace,
        }.items(),
    )

    livox_node = Node(
        package="livox_ros_driver2",
        executable="livox_ros_driver2_node",
        name="livox_lidar_publisher",
        output="screen",
        parameters=[
            {"xfer_format": 0},
            {"multi_topic": 0},
            {"data_src": 0},
            {"publish_freq": ParameterValue(livox_publish_freq, value_type=float)},
            {"output_data_type": 0},
            {"frame_id": lidar_frame_id},
            {"user_config_path": livox_config},
            {"lvx_file_path": "/tmp/mid360.lvx"},
            {"cmdline_input_bd_code": "livox0000000001"},
        ],
    )

    fastlio_node = Node(
        package="fast_lio",
        executable="fastlio_mapping",
        name="fastlio_mapping",
        output="screen",
        parameters=[fastlio_config],
    )

    bridge_node = Node(
        package="lio_to_mavros",
        executable="lio_to_mavros",
        name="lio_to_mavros",
        output="screen",
        parameters=[
            {
                "odom_topic": odom_topic,
                "vision_topic": vision_topic,
                "odom_out_topic": odom_out_topic,
                "publish_odom": ParameterValue(publish_odom, value_type=bool),
            }
        ],
    )

    rviz_node = Node(
        package="rviz2",
        executable="rviz2",
        name="fastlio_rviz",
        output="screen",
        arguments=["-d", fastlio_rviz],
        condition=IfCondition(use_fastlio_rviz),
    )

    return LaunchDescription(
        [
            DeclareLaunchArgument("start_mavros", default_value="true"),
            DeclareLaunchArgument("fcu_url", default_value="/dev/ttyACM0"),
            DeclareLaunchArgument("tgt_system", default_value="1"),
            DeclareLaunchArgument("mavros_namespace", default_value="mavros"),
            DeclareLaunchArgument("livox_publish_freq", default_value="10.0"),
            DeclareLaunchArgument("lidar_frame_id", default_value="livox_frame"),
            DeclareLaunchArgument("fastlio_config_file", default_value="mid360.yaml"),
            DeclareLaunchArgument("use_fastlio_rviz", default_value="false"),
            DeclareLaunchArgument("odom_topic", default_value="/Odometry"),
            DeclareLaunchArgument("vision_topic", default_value="/mavros/vision_pose/pose"),
            DeclareLaunchArgument("odom_out_topic", default_value="/mavros/odometry/in"),
            DeclareLaunchArgument("publish_odom", default_value="false"),
            mavros_node,
            livox_node,
            TimerAction(period=3.0, actions=[fastlio_node]),
            TimerAction(period=5.0, actions=[bridge_node]),
            rviz_node,
        ]
    )
