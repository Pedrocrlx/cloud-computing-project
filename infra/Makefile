clean:
	rm -rf terraform.tfstate terraform.tfstate.backup terraform.tfstate.d .terraform .terraform.lock.hcl
	minikube delete --all 

up: 
	terraform init
	terraform workspace new airbnb
	terraform plan
	terraform apply -target=minikube_cluster.main -auto-approve
	sleep 5
	terraform apply -auto-approve