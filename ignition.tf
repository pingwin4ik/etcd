data "ignition_config" "main" {
  systemd = [
    "${data.ignition_systemd_unit.pingwin.id}",
    "${data.ignition_systemd_unit.etcd3.id}",
    "${data.ignition_systemd_unit.docker.id}",
    "${data.ignition_systemd_unit.flannel.id}",
    "${data.ignition_systemd_unit.origin-master.id}",
  ]
}

data "ignition_systemd_unit" "origin-master" {
  name   = "origin-master.service"
  enable = true

  content = <<EOF
  [Unit]
  After=docker.service
  PartOf=docker.service
  Requires=docker.service coreos-metadata.service
  After=etcd-member.service
  [Service]
EnvironmentFile=/run/metadata/coreos
ExecStart=/usr/bin/docker run --rm --privileged --net=host --name origin-master  -v /var/lib/origin:/var/lib/origin -v /var/run/docker.sock:/var/run/docker.sock -v /etc/origin:/etc/origin --entrypoint /usr/bin/openshift openshift/origin start master --etcd=http://0.0.0.0:2379 --loglevel=4 --public-master=$${COREOS_EC2_IPV4_PUBLIC}:8443
ExecStartPost=/usr/bin/sleep 10
ExecStop=/usr/bin/docker stop origin-master
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target

EOF
}

data "ignition_systemd_unit" "docker" {
  name   = "docker.service"
  enable = true

  dropin = [
    {
      name    = "10-dockeropts.conf"
      content = "[Unit]\nRequires=flanneld.service\nAfter=flanneld.service\n[Service]\nRestart=on-failure\nRestart=always\nEnvironment=\"DOCKER_OPTS=--storage-driver=overlay2\"\n[Install]\nWantedBy=multi-user.target"
    },
  ]
}

data "ignition_systemd_unit" "flannel" {
  name   = "flanneld.service"
  enable = true

  dropin = [
    {
      name = "50-network-config.conf"

      content = <<EOF
      [Unit]

      After=etcd-member.service
      Requires=etcd-member.service

      [Service]
      Type=notify
      Restart=on-failure
      TimeoutStartSec=180
      Environment="TMPDIR=/var/tmp/"
      Environment="FLANNEL_IMAGE_TAG=v0.8.0"
      ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{"Network": "172.32.0.0/16", "Backend": {"Type": "aws-vpc"} }'

      [Install]


      WantedBy=multi-user.target
      RequiredBy=docker.service
EOF
    },
  ]
}

/*
data "ignition_systemd_unit" "mask-etcd" {
  name   = "etcd.service"
  enable = false
  mask   = true
}

data "ignition_systemd_unit" "mask-etcd3" {
  name   = "etcd-member.service"
  enable = false
}

data "ignition_systemd_unit" "mask-etcd2" {
  name   = "etcd2.service"
  enable = false
  mask   = true
} */

data "ignition_systemd_unit" "pingwin" {
  name   = "pingwin.service"
  enable = true

  content = <<EOF
[Unit]
Description=Set etcd2 peers
Before=etcd-member.service

[Service]
Type=oneshot
RemainAfterExit=yes

ExecStartPre=/usr/bin/mkdir -p /etc/sysconfig
ExecStart=/usr/bin/rkt --insecure-options=image run --dns 8.8.8.8 --net=host --volume data,kind=host,source=/etc/sysconfig/ --mount volume=data,target=/etc/sysconfig/ docker://monsantoco/etcd-aws-cluster

[Install]
WantedBy=multi-user.target
EOF
}

data "ignition_systemd_unit" "etcd3" {
  name   = "etcd-member.service"
  enable = true

  dropin = [
    {
      name = "30-etcd_peers.conf"

      content = <<EOF
  [Unit]
  Requires=pingwin.service coreos-metadata.service
  After=pingwin.service coreos-metadata.service
  Wants=network.target
  Conflicts=etcd.service
  Conflicts=etcd2.service
  [Service]
  Type=notify
  Restart=on-failure
  RestartSec=10s
  TimeoutStartSec=0
  LimitNOFILE=40000

  Environment="ETCD_IMAGE_TAG=latest"

  EnvironmentFile=/etc/sysconfig/etcd-peers
  EnvironmentFile=/run/metadata/coreos
  ExecStart=
  ExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \
  --advertise-client-urls=http://$${COREOS_EC2_IPV4_LOCAL}:2379 \
  --initial-advertise-peer-urls=http://$${COREOS_EC2_IPV4_LOCAL}:2380 \
  --listen-client-urls=http://0.0.0.0:2379 \
  --listen-peer-urls=http://0.0.0.0:2380 \
  --election-timeout 15000 \
  --heartbeat-interval 300

  [Install]
  WantedBy=multi-user.target
EOF
    },
  ]
}
