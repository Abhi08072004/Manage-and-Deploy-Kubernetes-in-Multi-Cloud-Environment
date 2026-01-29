![ARCH](https://github.com/user-attachments/assets/479c07e9-fe07-44b3-9d81-4246a518de25)# Manage and Deploy Kubernetes in Multi-Cloud Environment

This project creates a **multi-cloud Kubernetes cluster using kubeadm** by placing all nodes on the same private network using an **AWS Client VPN endpoint** to secure traffic.

- Control plane (master): AWS EC2  
- Worker nodes: VPN clients (GCP VM and a local machine)

---

## The Infrastructure
<p align="center">
  <img src="ARCH.gif" width="600" title="hover text">
</p>

---

## Requirements
1. AWS account (mandatory) to create the Client VPN endpoint  
2. Pre-deployed AWS EC2 instance  
   - `t2.micro` is **not recommended** due to Kubernetes CPU and memory requirements  
   - It can still work using:
     `--ignore-preflight-errors=Mem --ignore-preflight-errors=NumCpu`
3. Pre-deployed GCP instance (optional)  
4. AWS access key and secret access key  
5. OS: Ubuntu 22  

Inside the `scripts` directory, documentation is provided for each command.

## Step 0: Clone the Repository
```  
git clone https://github.com/devops-and-more/multi-cloud-kubernetes-cluster.git
cd multi-cloud-kubernetes-cluster
```

## Step 1: Generate VPN Certificates
Run `script1.sh` to generate server and client certificates.  
The script installs AWS CLI and uploads the certificates.  
Make sure to use the same AWS region as the EC2 instance.
```
chmod +x script1.sh
./script1.sh
```

**Note:**  
`script1.sh` uses a single `find` command that replaces multiple commands mentioned in the documentation.

---

## Step 2: Create AWS Client VPN Endpoint
- Use the VPC of the master (AWS EC2)
- Associate the target network with the subnet CIDR of the master
- Add an authorization rule allowing VPN clients to access the master subnet CIDR
- Enable **split tunnel** to keep internet access while connected

---

## Step 3: Configure VPN Clients
1. Download the VPN configuration file  
2. Move it to:
```
~/custom_folder/client.ovpn
```
3. Add certificate and key paths inside the file:
```
--cert "/home/your_user/custom_folder/client1.domain.tld.crt"
--key "/home/your_user/custom_folder/client1.domain.tld.key"
```
4. Copy the folder to other VPN client machines:
```
scp -r ~/custom_folder abhi@vpn_client:~/custom_folder
```

---

## Step 4: Connect VPN Clients
Install OpenVPN on worker nodes:
```
sudo openvpn --config ~/custom_folder/client.ovpn --daemon
```
`--daemon` runs OpenVPN in the background.

---

## Step 5: Prepare All Nodes
Run `script2.sh` on **all nodes** (master and workers).  
This installs and configures all Kubernetes prerequisites.
```
chmod +x script2.sh
./script2.sh
```

---

## Step 6: Initialize the Cluster
Run on the **master (AWS EC2)**:
```
kubeadm init
--control-plane-endpoint="[MASTER_PRIVATE_IP]:6443"
--upload-certs
--apiserver-advertise-address=[MASTER_PRIVATE_IP]
--pod-network-cidr=10.96.0.0/16
```
Configure kubeconfig:
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Join worker nodes using the `kubeadm join` command from the output.

---

## Step 7: Install Weave CNI
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

---

## Test the Cluster
Deploy an NGINX pod and expose it using a ClusterIP service:
```
kubectl run nginx --image nginx --port 80 --expose
kubectl get svc
```

Open the service IP in a browser to verify the deployment.







