
resource "aws_security_group" "masters" {
    vpc_id = "${aws_vpc.main.id}"
    name = "kubernetes-master-${var.cluster_name}"
    description = "Kubernetes security group applied to master nodes"

    tags {
        KubernetesCluster = "${var.cluster_name}"
    }
}

resource "aws_security_group_rule" "masters-allow-elb" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "ingress"
    source_security_group_id = "${aws_elb.master.source_security_group_id}"
    from_port = 443
    to_port = 443
    protocol = "tcp"
}

resource "aws_security_group_rule" "masters-allow-minions" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "ingress"
    source_security_group_id = "${aws_security_group.minions.id}"
    from_port = 0
    to_port = 0
    protocol = "-1"
}

resource "aws_security_group_rule" "masters-allow-masters" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "ingress"
    self = true
    from_port = 0
    to_port = 0
    protocol = "-1"
}

resource "aws_security_group_rule" "masters-allow-ssh" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "masters-allow-https" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "masters-allow-egress" {
    security_group_id = "${aws_security_group.masters.id}"

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "minions" {
    vpc_id = "${aws_vpc.main.id}"
    name = "kubernetes-minion-${var.cluster_name}"
    description = "Kubernetes security group applied to minion nodes"

    tags {
        KubernetesCluster = "${var.cluster_name}"
    }
}

resource "aws_security_group_rule" "minions-allow-minions" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    self = true
    from_port = 0
    to_port = 0
    protocol = "-1"
}

resource "aws_security_group_rule" "minions-allow-masters" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    source_security_group_id = "${aws_security_group.masters.id}"
    from_port = 0
    to_port = 0
    protocol = "-1"
}

resource "aws_security_group_rule" "minions-allow-ssh" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "minions-allow-egress" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "minions-allow-http" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    from_port = 30080  // Defined in default/frontend-svc.yaml
    to_port = 30080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "minions-allow-https" {
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    from_port = 30443 // Defined in default/frontend-svc.yaml
    to_port = 30443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "minions-allow-extra" {
    count = "${var.enable_extra_minion_security_group}"
    security_group_id = "${aws_security_group.minions.id}"

    type = "ingress"
    source_security_group_id = "${var.extra_minion_security_group}"
    from_port = "${var.extra_minion_security_group_port}"
    to_port = "${var.extra_minion_security_group_port}"
    protocol = "tcp"
}

resource "aws_security_group" "frontend-elb" {
    count = "${var.enable_frontend_elb}"
    vpc_id = "${aws_vpc.main.id}"
    name = "k8s-elb-${var.elb_name}"
    description = "Security group for Kubernetes ELB ${var.elb_name} (default/frontend)"

    tags {
        KubernetesCluster = "${var.cluster_name}"
    }
}

resource "aws_security_group_rule" "frontend-elb-allow-http" {
    count = "${var.enable_frontend_elb}"
    security_group_id = "${aws_security_group.frontend-elb.id}"

    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "frontend-elb-allow-https" {
    count = "${var.enable_frontend_elb}"
    security_group_id = "${aws_security_group.frontend-elb.id}"

    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "frontend-elb-allow-icmp" {
    count = "${var.enable_frontend_elb}"
    security_group_id = "${aws_security_group.frontend-elb.id}"

    type = "ingress"
    from_port = 3
    to_port = 4
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "frontend-elb-allow-egress" {
    count = "${var.enable_frontend_elb}"
    security_group_id = "${aws_security_group.frontend-elb.id}"

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "master-elb" {
    vpc_id = "${aws_vpc.main.id}"
    name = "kubernetes-master-elb-${var.cluster_name}"
    description = "Kubernetes security group for master API ELB"

    tags {
        KubernetesCluster = "${var.cluster_name}"
    }
}

resource "aws_security_group_rule" "master-elb-allow-https" {
    security_group_id = "${aws_security_group.master-elb.id}"

    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "master-elb-allow-egress" {
    security_group_id = "${aws_security_group.master-elb.id}"

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}