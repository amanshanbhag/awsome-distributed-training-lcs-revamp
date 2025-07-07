# Configuration Options

The script accepts a JSON configuration file with the following options:

## General Options
- `AUTO_MODE`: Set to "true" to automatically skip interactive prompts (default: "false")
- `remove_and_clone`: Whether to remove and re-clone the repository (default: "no")
- `aws_region`: AWS region where you want to set up your cluster (default: current AWS CLI region)
- `stack_id_vpc`: The name of the SageMaker VPC CloudFormation stack (default: "sagemaker-hyperpod")
- `deployed_observability`: Whether observability stack was deployed (default: "no")
- `configure_users`: Set to "yes" if you want to automatically create POSIX users on the cluster (default: "no")

### User Configuration Options
When `AUTO_MODE` is "true", and `configure_users` is "yes", you can define users using the users array:
```json
"users": [
  {
    "username": "user1",
    "user_id": 2001,
    "iam_username": "iam-user1"
  },
  {
    "username": "user2",
    "user_id": 2002
  }
]
```
Each user object supports:
- `username`: POSIX username for the cluster user
- `user_id`: User ID for the POSIX user (e.g., 2001)
- `iam_username`: (Optional) IAM username to associate with the POSIX user for SSM Run As support

## Multi-Headnode Options
- `multi_headnode`: Whether to enable multi-headnode feature (default: "no")
- `multi_head_slurm_stack`: Name for the SageMaker HyperPod Multiheadnode stack (default: "sagemaker-hyperpod-mh")
- `email`: Email address for notifications (default: "johndoe@example.com")
- `db_user_name`: Username for SlurmDB (default: "johndoe")

## Instance Options
- `using_neuron`: Whether using Neuron-based instances (default: "no")
- `controller_name`: Name for the controller instance group (default: "controller-machine")
- `controller_type`: Instance type for the controller (default: "ml.m5.12xlarge")
- `add_login_group`: Whether to add a login group (default: "no")
- `login_type`: Instance type for the login group (default: "ml.m5.4xlarge")

### Worker Group Options
When `AUTO_MODE` is "true", you can define multiple worker groups using the `worker_groups` array:
```json
"worker_groups": [
  {
    "instance_type": "ml.c5.4xlarge",
    "instance_count": 4,
    "volume_size_gb": 500,
    "threads_per_core": 1,
    "use_training_plan": "no"
  },
  {
    "instance_type": "ml.g5.2xlarge",
    "instance_count": 2,
    "volume_size_gb": 500,
    "threads_per_core": 2,
    "use_training_plan": "yes",
    "training_plan": "my-training-plan"
  }
]
```
Each worker group object supports:
- `instance_type`: Instance type for the worker group (e.g., "ml.c5.4xlarge")
- `instance_count`: Number of instances in the worker group (e.g., 4)
- `volume_size_gb`: Size of the EBS volume in GB (default: 500)
- `threads_per_core`: Number of threads per core (1 or 2, default: 1)
- `use_training_plan`: Whether to use a training plan (default: "no")
- `training_plan`: Training plan name (required if `use_training_plan` is "yes")

## Cluster Options
- `cluster_name`: Name for the cluster (default: "ml-cluster")
- `configure_users`: Whether to configure users (default: "no")
- `create_cluster`: Whether to create the cluster (default: "yes")
