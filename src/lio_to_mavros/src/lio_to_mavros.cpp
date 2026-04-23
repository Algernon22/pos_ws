#include <rclcpp/rclcpp.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>
#include <nav_msgs/msg/odometry.hpp>

class LIOToMavros : public rclcpp::Node
{
public:
    LIOToMavros() : Node("lio_to_mavros")
    {
        this->declare_parameter<std::string>("odom_topic", "/Odometry");
        this->declare_parameter<std::string>("vision_topic", "/mavros/vision_pose/pose");
        this->declare_parameter<std::string>("odom_out_topic", "/mavros/odometry/in");
        this->declare_parameter<bool>("publish_odom", false);
        
        std::string odom_topic = this->get_parameter("odom_topic").as_string();
        std::string vision_topic = this->get_parameter("vision_topic").as_string();
        std::string odom_out_topic = this->get_parameter("odom_out_topic").as_string();
        bool publish_odom = this->get_parameter("publish_odom").as_bool();
        
        odom_sub_ = this->create_subscription<nav_msgs::msg::Odometry>(
            odom_topic, 10,
            std::bind(&LIOToMavros::odom_callback, this, std::placeholders::_1));
        
        vision_pub_ = this->create_publisher<geometry_msgs::msg::PoseStamped>(
            vision_topic, 10);
        
        if (publish_odom) {
            odom_pub_ = this->create_publisher<nav_msgs::msg::Odometry>(
                odom_out_topic, 10);
        }
    }

private:
    void odom_callback(const nav_msgs::msg::Odometry::SharedPtr msg)
    {
        // 发布vision pose
        auto vision_pose = geometry_msgs::msg::PoseStamped();
        vision_pose.header = msg->header;
        vision_pose.pose = msg->pose.pose;
        vision_pub_->publish(vision_pose);
        
        // 如果需要，发布原始odometry
        if (odom_pub_) {
            odom_pub_->publish(*msg);
        }
    }
    
    rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr odom_sub_;
    rclcpp::Publisher<geometry_msgs::msg::PoseStamped>::SharedPtr vision_pub_;
    rclcpp::Publisher<nav_msgs::msg::Odometry>::SharedPtr odom_pub_;
};

int main(int argc, char **argv)
{
    rclcpp::init(argc, argv);
    auto node = std::make_shared<LIOToMavros>();
    rclcpp::spin(node);
    rclcpp::shutdown();
    return 0;
}
