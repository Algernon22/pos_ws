from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration

def generate_launch_description():
    return LaunchDescription([
        DeclareLaunchArgument(
            'odom_topic',
            default_value='/Odometry',
            description='LIO odometry topic name'
        ),
        DeclareLaunchArgument(
            'vision_topic',
            default_value='/mavros/vision_pose/pose',
            description='Mavros vision pose topic'
        ),
        DeclareLaunchArgument(
            'odom_out_topic',
            default_value='/mavros/odometry/in',
            description='MAVROS odometry input topic (optional)'
        ),
        DeclareLaunchArgument(
            'publish_odom',
            default_value='false',
            description='Whether to also publish odometry'
        ),
        
        Node(
            package='lio_to_mavros',
            executable='lio_to_mavros',
            name='lio_to_mavros',
            output='screen',
            parameters=[{
                'odom_topic': LaunchConfiguration('odom_topic'),
                'vision_topic': LaunchConfiguration('vision_topic'),
                'odom_out_topic': LaunchConfiguration('odom_out_topic'),
                'publish_odom': LaunchConfiguration('publish_odom'),
            }]
        ),
    ])
