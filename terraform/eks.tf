module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    main = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2

      labels = {
        Environment = var.environment
      }

      tags = {
        Project = "observability"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = var.environment
    Project     = "observability"
  }
}
