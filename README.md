# This repository is to lauch kubernetes cluster on AWS EC2 instances using Terraform
# Once the instances are launched configure kubernetes standalone cluster using ansible

# Deploy control plane and 2 worker nodes on AWS
cd ./Ansible-ec2-standalone-kubernetes-cluster/
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
- generate certificate with publicIP on control plane
sudo rm /etc/kubernetes/pki/apiserver.{crt,key}
sudo kubeadm init phase certs apiserver --apiserver-cert-extra-sans=<PUBLIC_IP>
- For containerd (standard in newer versions)
sudo crictl ps | grep kube-apiserver | awk '{print $1}' | xargs sudo crictl stop


- On your local machine
  scp -i path/to/my-terraform-key ubuntu@<control-plane-ip>:/etc/kubernetes/admin.conf ./kubeconfig
ssh -i my-terraform-key ubuntu@54.166.5.198 'sudo cat /etc/kubernetes/admin.conf' > ./kubeconfig

- change public IP in ./kubeconfig
export KUBECONFIG=$PWD/kubeconfig

# test cluster
kubectl get nodes



