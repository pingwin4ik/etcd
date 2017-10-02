resource "aws_launch_configuration" "coreos_launch_config" {
  associate_public_ip_address = true
  image_id                    = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  name                        = "coreos-example-lc"
  iam_instance_profile        = "${aws_iam_instance_profile.flannel-profile.id}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = 40
  }

  security_groups = ["${aws_security_group.coreos_sg.id}", "${aws_security_group.allow_ssh.id}"]

  user_data = "${data.ignition_config.main.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "coreos_asg" {
  name                 = "coreos-example-asg"
  max_size             = 5
  min_size             = 1
  desired_capacity     = 3
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.coreos_launch_config.name}"
  vpc_zone_identifier  = ["${aws_subnet.coreos.*.id}"]

  lifecycle {
    create_before_destroy = false
  }

  tag {
    key                 = "Name"
    value               = "coreos-asg"
    propagate_at_launch = "true"
  }
}

/*
resource "aws_sqs_queue" "sqs" {
  name                       = "sqs"
  visibility_timeout_seconds = 5
  max_message_size           = 2048
  message_retention_seconds  = 86400
}

resource "aws_autoscaling_lifecycle_hook" "sqs" {
  name                    = "sqs"
  autoscaling_group_name  = "${aws_autoscaling_group.coreos_asg.name}"
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout       = 30
  notification_target_arn = "${aws_sqs_queue.sqs.arn}"
  role_arn                = "${aws_iam_role.lifecycle_role.arn}"
} */

