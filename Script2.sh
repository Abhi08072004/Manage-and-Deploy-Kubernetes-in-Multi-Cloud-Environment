#node creation
###  ssh to all future nodes to start botstraping your cluster
{
 # 1 disable swap and ufw
 sudo swapoff -a; 
 sudo sed -i '/swap/d' /etc/fstab 
 #Swap disabled. You MUST disable swap in order for the kubelet to work properly see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/


#2
##SIMPLE WAY TO INSTALL DOCKER/CONTAINERD: using a script provided in the Docker website https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script
{
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh 
}




#3 IMPORTANT: configuration of the containerd: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
# use either:
# enable the CRI on the containerd configuration file
#vi /etc/containerd/config.toml
# and then comment the line for disabled plugins =[cri]
#systemctl restart containerd
# or
###better way######
{
containerd config default | sudo tee /etc/containerd/config.toml;  #load the default configurations for containerd
sudo sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml; # set the Cgroup driver as systemd
sudo systemctl restart containerd
}
 #4 Forwarding IPv4 and letting iptables see bridged traffic https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic

{
{
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
}
{
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
}
}
#5 Installing kubeadm, kubelet and kubectl https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
{
sudo apt-get update;

sudo apt-get install -y apt-transport-https ca-certificates curl;

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg;

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update;

sudo apt-get install -y kubelet kubeadm kubectl;

sudo apt-mark hold kubelet kubeadm kubectl
}

}