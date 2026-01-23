# cloud-computing-project


kubectl config get-contexts - all clusters created

kubectl config use-context airbnb-dev - change for especific cluster

---------------

terraform workspace list

terraform workspace new airbnb 

terraform apply -target=minikube_cluster.main -auto-approve - first will create the cluster then:

terraform apply -auto-approve

minikube -p airbnb kubectl -- get pods -A : show on that specific profile all pods

minikube -p airbnb ip - get on that specific profile the IP and then:

sudo nano /etc/hosts - minikube ip  odoo.dev.airbnb.local odoo.prod.airbnb.local

curl -kI https://odoo.dev.airbnb.local