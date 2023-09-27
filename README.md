# Deploy Counter-app on EKS Cluster with mysql Database and Monitor using Prometheus and Grafana using Terraform

### Pre-requisite:
**Verify below apps installed on your PC:**

AWS Cli

Terraform

Kubectl

Helm

### Step 1: Copy VPC ID
Login to aws concole and Goto to VPC 

Copy the default VPC ID and update in the file vars.tf from the folder EKS-AD (line no. 7)

### step 2: Create EKS cluster
Goto the folder EKS-AD and run below commands:
```
$  aws configure 
$  terraform init
$  terraform plan
$  terraform apply
```
### step 3: Connect to EKS cluster
Goto the folder EKS-Deployments and run below commands to connect to EKS cluster and check resources
```
$  aws eks update-kubeconfig --name myekstest-cluster-01
$  kubectl get svc
$  kubectl get nodes
```
### Step 4: Deploy Test Application - NGNIX
Run below commands to install NGNIX pod:
```
$  kubectl apply -f deploy.yml
$  kubectl apply -f deploy-svc.yml
```
### Step 5: Deploy Application - Counter-app
Run below commands to install Counter-app pod:
```
$  kubectl apply -f counter-app.yml
$  kubectl apply -f counter-app-svc.yml
```
### Step 6: Deploy mysql DB
Run below commands to install mysql-db pod:
```
$  kubectl apply -f mysql-secret.yml
$  kubectl apply -f mysql-pvc.yml
$  kubectl apply -f mysql.yml
$  kubectl apply -f mysql-svc.yml
```
### Step 7: Deploy Prometheus and Grafana
Run below commands to install Prometheus and Grafana:
```
Add the Helm Stable Charts for your local client:
$  helm repo add stable https://charts.helm.sh/stable

Add prometheus Helm repo
$  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

Create Prometheus namespace
$  kubectl create namespace prometheus

Install kube-prometheus-stack
$  helm install stable prometheus-community/kube-prometheus-stack -n prometheus

Check if prometheus and grafana pods are running 
$  kubectl get pods -n prometheus
$  kubectl get svc -n prometheus

Edit Prometheus Service (replace third last line with "type: LoadBalancer")
$  kubectl edit svc stable-kube-prometheus-sta-prometheus -n prometheus

Edit Grafana Service (replace third last line with "type: LoadBalancer")
kubectl edit svc stable-grafana -n prometheus
```
### Step 8: Test Deployments:
**1) Test Counter-app Application**
   
Get the node IP where pod is running by running below command:

$  kubectl get pods -o wide

**Note the public IP of the node for which we got Private IP above**

Get the port number by running below command:

$  kubectl get svc

**Note the port number got from the above command**

**Open the port on node security group (e.g. 30009)**

Browse the node public ip and port number to access application web interface: e.g. http://18.219.164.132:30009

**2) Test Prometheus and Grafana**

Similar to above get bublic IP of the node, open ports on the node security group and browse public IP with port numbers

e.g. 
     http://18.219.164.132:30227 (Grafana)
     http://18.219.164.132:30624 (Prometheus)

**To deploy new app release, Update the image name in the file deploy.yml and run command again**

$  kubectl apply -f deploy.yml 

**3) Test mysql DB**
```
Connect to the mysql-db pod using below command
$  kubectl exec --stdin --tty mysql-deployment-5fbbd946ff-7dj7s -- /bin/bash

Connect to the DB (use password mentioned in the kube secret)
$  mysql –u root –p 

Create new DB
$  CREATE DATABASE counterapp_db;

List databases
$  show databases;

Connect to the new DB
$  use counterapp_db;

Create a database table called Catalog with the following SQL statement
$  CREATE TABLE Catalog(
    Sr INTEGER PRIMARY KEY,
    Salutation VARCHAR(25),
    Name VARCHAR(25),
    Surname VARCHAR(25),
    Gender VARCHAR(25)  
  );

Add a row of data to the Catalog table with the following SQL statement:
$  INSERT INTO Catalog 
  VALUES('1','Mr.','Ajit', 'Dherange',
         'Male');

checkout the updated data using statement:
$  SELECT * FROM Catalog;
```

### Step 9: Clean up
Goto the folder EKS-AD and run below command

$  terraform apply -destroy




