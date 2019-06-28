# Running JupyterHub on a Spark cluster
This code is all about having a flexible spark cluster and attach to it JupyterHub which allows more than one user to run Jupyter notebooks using the cluster taking advantage of more processing power and making the "notebook setup" process a lot easier.

> This code has been developed using Kubernetes on IBM Cloud so if you are running on a different cloud provider (Amazon, Google Cloud, etc.) make sure to make the necessary changes.<BR><BR>
> Usually changes might be required on ingress and persistent volume claims only.<BR><BR>
> If you want to run locally you need to have [minikube](https://github.com/kubernetes/minikube) installed and you also need to change how your volumes work and maybe not use ingress.<BR>

## Getting everything up and running
### 1. Creating and starting the Spark Cluster
1. Build the `spark.Dockerfile` and push to your register.<BR><BR>
2. Change the image path in both `jupyter-spark-master.yml` and `jupyter-spark-worker.yml` so it points to your built image in your register.<BR><BR>
3. Make sure you are able to connect to your Kubernetes cluster using [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).<BR><BR>
4. Adjust your spark worker settings based on the hardware capacity you have and on what you want to run by changing the `SPARK_WORKER_CORES` and `SPARK_WORKER_MEMORY` located on `spark_cluster/spark-env.sh`.<BR><BR>
5. Start the spark master by running `kubectl create -f jupyter-spark-master.yml` (Make sure you are in the same path as the yml files or referencing the absolute path). Check the logs and the pods status to ensure it's been created successfully. Run `kubectl get pods` to check the pods statuses.<BR><BR>
6. Start the spark workers running `kubectl create -f jupyter-spark-worker.yml` and make sure they've been created successfully.
> In the jupyter-spark-worker.yml deployment I'm using one worker instance per worker due to the dynamic allocation being used. Dynamic allocation requires the shuffle service to be enabled on the worker therefore only one worker instance per worker can be created. In our case we are using 145 workers. Feel free to resize that based on your needs.
7. Create the spark master service. Run `kubectl create -f spark-master-service-jh.yml`.<BR><BR>
8. By now you should get your cluster up and running. If you want to access the cluster UI you could expose it using ingress (which is not covered here for the spark cluster) or do a port-forward on Kubernetes to expose the interface on your local machine. To do so run `kubectl port-forward <your pod name> <port on pod to be exposed>:<port on local machine to be used>`

### 2. Set up JupyterHub
1. Build the `jupyterhub.Dockerfile` located in the jupyterhub directory.
> This Dockerfile references the previous spark image created so make sure to replace the `FROM` image in this dockerfile with your respective image locations and name.

2. Create the persistent volume claim. It will be used to store all the notebooks created by the users. Run `kubectl apply -f jupyterhub-pvc.yml`.
> 1. You might need to change your PVC storage class depending on your cloud provider.
> 2. If you don't need to persist the notebooks you can skip the PVC creation.

#### How user creation works
To ensure security all the users' information are stored in a Kubernetes secret which is provided on bullet 3 since it's in gitignore to ensure data is not exposed.<BR><BR>
To add or remove users on JupyterHub the following json should be used:
```
{
  "credentials": [
    {
      "user": "user1",
      "pwd": "user1pwd"
    },
    {
      "user": "user2",
      "pwd": "user2pwd"
    }
  ]
}
```
<BR>
After creating the json, make sure to remove all spaces and new line characters and then convert it into base 64 which is supported by Kubernetes secret.<BR><BR>

3. Create the following kubernetes secret:

```
apiVersion: v1
kind: Secret
metadata:
  name: jupyterhub-secret
type: Opaque
data:
  credentials: eyJjcmVkZW50aWFscyI6W3sidXNlciI6InVzZXIxIiwicHdkIjoidXNlcjFwd2QifSx7InVzZXIiOiJ1c2VyMiIsInB3ZCI6InVzZXIycHdkIn1dfQ==
  admin_pwd: YWRtaW5wd2Q=
```

> `epmadmin` is the JupyterHub admin and its password can be defined in the kubernetes secret in the `admin_pwd` attribute. Make sure to add it there base64 encoded.

4. Create the JupyterHub deployment running `kubectl create -f jupyterhub-dep.yml`.<BR><BR>
5. To access JupyterHub straight in the deployment simply list all the pods to get the respective JupyterHub deployment's pod name by running `kubectl get pods` and then run a port forward to your local machine.
```
  kubectl port-forward <pod name> <port used by the pod>:<port mapped on your local machine>
```
  
#### Enabling JupyterHub to be accessed from a URL using HTTPS
If you want to make JupyterHub accessible from a URL to your Kubernetes cluster, you can take advantage of the ingress service. Have in mind some details on how to use ingress might be different depending on your cloud provider. All the code here has been created based on IBM Cloud.<BR><BR>
1. Create a kubernetes service for you JupyterHub deployment running `kubectl create -f jupyterhub-service.yml`.<BR><BR>
2. Create your ingress object using your cloud provider guidance.
Below is the one I'm using on IBM Cloud:
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: jhub-epm-ingress
spec:
  rules:
  - host: <pick a name>.<namespace>.us-south.containers.appdomain.cloud
    http:
      paths:
      - backend:
          serviceName: jupyterhub-service
          servicePort: 8000
        path: /
  tls:
  - hosts:
    - <pick a name>.<namespace>.us-south.containers.appdomain.cloud
    secretName: <your namespace name>
```
```
kubectl apply -f jupyterhub-ingress.yml
```
> The way I'm using ingress is by providing a specific subdomain for juyterhub. You could also choose to provide a specific URL directory.
