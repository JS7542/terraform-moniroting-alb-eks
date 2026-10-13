output "name" { value = var.name }
output "region" { value = "eu-north-1" }
output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "cluster_ca" { value = aws_eks_cluster.this.certificate_authority[0].data }
output "node_security_group_id" { value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id }
output "node_asg_name" { value = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name }
output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region eu-north-1 --name ${aws_eks_cluster.this.name}"
}
