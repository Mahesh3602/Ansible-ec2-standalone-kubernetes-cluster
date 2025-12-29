# This repository is to lauch kubernetes cluster on AWS EC2 instances using Terraform
# Once the instances are launched configure kubernetes standalone cluster using ansible

# Deploy control plane and 2 worker nodes on AWS
cd Ansible
terraform init, plan and apply.

# Launch Kubernetes cluster on the standalone machines
cd k8s-ansible
--  update the inventory.ini file 
ansible-playbook control-plane.yml
ansible-playbook workers.yml

# check the cluster
- login to cp using ssh
- kubectl get nodes 
- kubectl get pods --all-namespaces

# configure cluster to access locally (need correct details)
- On your local machine
scp -i path/to/my-terraform-key ubuntu@<control-plane-ip>:/etc/kubernetes/admin.conf ./kubeconfig
ssh -i my-terraform-key ubuntu@3.95.235.249 'sudo cat /etc/kubernetes/admin.conf' > ./kubeconfig

export KUBECONFIG=$PWD/kubeconfig





