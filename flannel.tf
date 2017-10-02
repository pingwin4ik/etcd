resource "aws_iam_instance_profile" "flannel-profile" {
  name = "Flannel"
  role = "${aws_iam_role.flannel-role.name}"
}

resource "aws_iam_role" "flannel-role" {
  name = "Flannel"
  path = "/terraform/"

  description = "Role used by Flannel to manage VPC"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "route-table-policy" {
  name = "route-table-policy"
  role = "${aws_iam_role.flannel-role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
          "Effect": "Allow",
          "Action":
              "*",
          "Resource":
              "*"

    }

  ]
}
EOF
}

/*
resource "aws_iam_instance_profile" "lifecycle-hooks-profile" {
  name = "lifecycle-hooks-policy"
  role = "${aws_iam_role.lifecycle_role.name}"
}

# Autoscaling lifecycle hook role
# Allows lifecycle hooks to add messages to the SQS queue
resource "aws_iam_role" "lifecycle_role" {
  name = "lifecycle-hooks"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Attach policy document for access to the sqs queue
resource "aws_iam_role_policy" "lifecycle_role_policy" {
  name = "lifecycle-hooks-policy"
  role = "${aws_iam_role.lifecycle_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
    "Effect": "Allow",
    "Resource": "*",
    "Action": [
      "sqs:SendMessage",
      "sqs:GetQueueUrl",
      "sns:Publish"
    ]
  }
]
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}
 */

