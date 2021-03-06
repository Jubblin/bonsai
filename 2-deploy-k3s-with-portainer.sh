#!/bin/bash

# Deploy k3s master on node1
multipass exec node1 -- /bin/bash -c "curl -sfL https://get.k3s.io | sh -"
# Get the IP of the master node
K3S_NODEIP_MASTER="https://$(multipass info node1 | grep "IPv4" | awk -F' ' '{print $2}'):6443"
# Get the TOKEN from the master node
K3S_TOKEN="$(multipass exec node1 -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"
# Deploy k3s on the worker nodes node2,node3,node4
multipass exec node2 -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -"
multipass exec node3 -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -"
multipass exec node4 -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -"
sleep 10

echo "############################################################################"
# multipass exec node1 -- bash -c "sudo kubectl get nodes"
multipass exec node1 -- bash -c 'sudo cat /etc/rancher/k3s/k3s.yaml' > k3s.yaml
sed -i'.back' -e 's/127.0.0.1/node1/g' k3s.yaml
export KUBECONFIG=`pwd`/k3s.yaml
kubectl taint node node1 node-role.kubernetes.io/master=effect:NoSchedule
kubectl label node node2 node-role.kubernetes.io/node=
kubectl label node node3 node-role.kubernetes.io/node=
kubectl label node node4 node-role.kubernetes.io/node=
# sleep 10
kubectl create -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
kubectl create -f metal-lb-layer2-config.yaml
kubectl rollout status -n metallb-system daemonset speaker
kubectl get all -A
kubectl get nodes
echo "are the nodes ready?"
echo "if you face problems, please open an issue on github"
echo "now deploying portainer"
kubectl create -f addons/portainer/portainer.yaml
kubectl rollout status -n portainer deployment portainer
portainer_ip=`kubectl get svc -n portainer | grep portainer | awk 'NR==1{print $4}'`
open http://$portainer_ip:9000
echo "############################################################################"
