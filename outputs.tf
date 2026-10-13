output "ec2_nginx_url" { value = module.ec2.nginx_url }
output "eks_nginx_url" { value = module.eks_app.nginx_url }
output "ec2_target_group_arn" { value = module.ec2.target_group_arn }
output "eks_target_group_arn" { value = module.eks_app.target_group_arn }
output "kubeconfig_command" { value = module.eks.kubeconfig_command }
