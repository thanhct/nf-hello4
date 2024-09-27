This document will guide you on how to run a simple Nextflow pipeline on Kubernetes.

### Prerequisites:

- Install Nextflow on your local machine
- Install Docker, kubectl and Minikube on your local environment.


### Clone nf-hello from Github
Clone the "nf-hello" repository to your machine from GitHub - thanhct/nf-hello 

```
git clone git@github.com:thanhct/nf-hello.git
```

### Create PV, PVC, Role and Role Binding
Navigate to the cloned directory in your terminal and run the following commands:
```
kubectl apply -f persistent-volume.yml
kubectl apply -f persistent-volume-claim.yml
kubectl apply -f role.yml
kubectl apply -f rolebinding.yml
```

### Run nextflow on minikube
After successfully applying these files, proceed to run the following command:
```
nextflow kuberun thanhct/nf-hello -r 1019cce -c nextflow.k8s.config
```

### Run on local (without minikube)
If you want to run it on local machine we need to install fastqc 

Ubuntu
```
sudo apt-get update
sudo apt-get install fastqc
```
MacOS

```
brew install fastqc
```

Navigate to project directory (nf-hello) in your terminial and run the following command

```
nextflow run main.nf -c nextflow.local.config -work-dir ./work --debug
```