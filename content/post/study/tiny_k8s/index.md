---
title: "The Goblin Kubernetes"
description: "Deepdive into the popular, lightweight Kubernetes distributions."
date: 2026-08-19
draft: false
tags: [
    "kubernetes",
    "container",
    "linux"
]
categories: [
    "study"
]
---

Although I have worked with Kubernetes (K8s) for many years, my on-premise setup is usually 
the official, standard version for a cluster: using `kubeadm` for installation and 
cluster administration. 
Such tools simplify and automate the cluster-building process. 
Yet, my [installation manuals](https://github.com/GTkernel/kubernetes-cluster-deployment) still takes about 
9 steps to build a K8s cluster. 
There are other distributions that offer one-click worry-free installations, 
and this is the topic of this post.

#### Why not using these mini-K8s systems for edge? 

My previous research focused on edge computing, so 
people might wonder why I didn't use the K8s distributions that build lightwight system components.
They seem like a perfect fit for the resource-contrained edge environment. Is this really the case?

While reducing resource consumption of system control-plane components is desirable, my edge system,
working in the last mile to end users in a cellular network, should still run in a data center, 
and this D/C is probably much smaller than any availability zone of a public cloud.
A quick comparison between mini-K8s and standard K8s reveals more concerns about using them in my projects:

- Some are designed for learning, playgrounds, and fast testing, especially on personal desktops; others target IoT edge environments, such as smart home systems.
- More automation means additional abstraction and less control, making the system harder to customize or manage.
- Unable or difficult to scale because system components are tightly bundled together.

With this background, 
this post aims to walk through some popular mini-K8s distributions and discuss my technical findings.
Let's go!


## Candidates Evaluation

| Item                 | [minikube](https://minikube.sigs.k8s.io/docs/) | [MicroK8s](https://microk8s.io) | [K3s](https://k3s.io) | [kind](https://github.com/kubernetes-sigs/kind/) | [k0s](https://k0sproject.io) |
|----------------------|--------------|--------------|---------|---------|--------|
| Owner                | K8s Special Interest Group (SIG) | Canonical   |  CNCF Sandbox from 2020; originally by Rancher | K8s SIG | CNCF Sandbox from 2025; originally by Mirantis |
| Repository location | [K8s Org](https://github.com/kubernetes/minikube) | [Canonical Org](https://github.com/canonical/microk8s) | [Dedicated Org](https://github.com/k3s-io/k3s/) | [SIG Org](https://github.com/kubernetes-sigs/kind/) | [Dedicated Org](https://github.com/k0sproject/k0s) |
| Initial release      | July 2016 | July 2018 | Feb 2019 | Nov 2019 | Nov 2020 |
| Current version      | v1.38.1  | v1.36/stable  | v1.36.3+k3s1 | v0.32.0 |v1.36.3+k0s.2 |
| Deployed K8s version | v1.35.1  | v1.36.2  | v1.36.3+k3s1 | v1.36.1 | v1.36.3+k0s |



{{< figure src="https://kubernetes.io/blog/2026/04/22/kubernetes-v1-36-release/k8s-v1.36.svg" caption="The logo of v1.36 is quite adorable 😍" width="50%" class="center" >}}

The latest version of K8s is `v1.36.3`. 
In the above table, three out of five, coincidentally the ones that are not in the official SIG, 
have aligned their version numbers with K8s's version. 
Besides that, they can be further differentiated by their system architectures; I name them **Nested Goblin K8s** and **Native Goblin K8s**.

| Goblin type                   | Nested                        | Native                                          |
| ----------------------------- | ----------------------------- | ----------------------------------------------- |
| Distribution                  | minikube and kind             | MicroK8s, K3s and k0s                           |
| Design target                 | Personal / local testing      | IoT edge / CI                                   |
| Working style                 | Nested in a VM or a container | Directly on the same host, managed by `systemd` |
| K8s CLI                       | External `kubectl` required   | Embedded in the tool. E.g. `k0s kubectl`        |
| Need image upload?[^registry] | Yes                           | Yes                                             |
| Need port exposure?           | Yes                           | No                                              |


[^registry]: If you have set up a private registry, you don't need to load the images separately. This refers to the case where you need to load locally built images into the running mini-K8s, as it is either running on a nested host or using a container runtime with a special namespace.

Next, I will discuss the technique details of these candidates with some deployment screenshots.

### minikube

I used **minikube** on my MacBook before, and at the time I ran it with a VM driver/VirtualBox. 
So, this time, I ran it with the Docker driver, which means minikube itself runs as a Docker container.

The logs below show the control-plane building information:
```
$ minikube start
* minikube v1.38.1 on Ubuntu 24.04 (vbox/amd64)
* Automatically selected the docker driver. Other choices: none, ssh
! Starting v1.39.0, minikube will default to "containerd" container runtime. See #21973 for more info.
* Using Docker driver with root privileges
* Starting "minikube" primary control-plane node in "minikube" cluster
* Pulling base image v0.0.50 ...
* Downloading Kubernetes v1.35.1 preload ...
    > preloaded-images-k8s-v18-v1...:  272.45 MiB / 272.45 MiB  100.00% 4.67 Mi
    > gcr.io/k8s-minikube/kicbase...:  519.58 MiB / 519.58 MiB  100.00% 4.89 Mi
* Creating docker container (CPUs=2, Memory=3072MB) ...
* Preparing Kubernetes v1.35.1 on Docker 29.2.1 ...
* Configuring bridge CNI (Container Networking Interface) ...
* Verifying Kubernetes components...
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
* Enabled addons: storage-provisioner, default-storageclass
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

From these logs, 
the important messages are that the CNI is implemented using the network bridge, 
and the `kubectl` on the host is configured to access to this minikube cluster as the working K8s cluster.

```
$ kubectl get pod -n kube-system
NAME                               READY   STATUS    RESTARTS        AGE
coredns-7d764666f9-wnz2j           1/1     Running   0               4m14s
etcd-minikube                      1/1     Running   0               4m20s
kube-apiserver-minikube            1/1     Running   0               4m19s
kube-controller-manager-minikube   1/1     Running   0               4m19s
kube-proxy-nsjfq                   1/1     Running   0               4m14s
kube-scheduler-minikube            1/1     Running   0               4m21s
storage-provisioner                1/1     Running   1 (3m42s ago)   4m17s

$ minikube profile list
┌──────────┬────────┬─────────┬──────────────┬─────────┬────────┬───────┬────────────────┬────────────────────┐
│ PROFILE  │ DRIVER │ RUNTIME │      IP      │ VERSION │ STATUS │ NODES │ ACTIVE PROFILE │ ACTIVE KUBECONTEXT │
├──────────┼────────┼─────────┼──────────────┼─────────┼────────┼───────┼────────────────┼────────────────────┤
│ minikube │ docker │ docker  │ 192.168.49.2 │ v1.35.1 │ OK     │ 1     │ *              │ *                  │
└──────────┴────────┴─────────┴──────────────┴─────────┴────────┴───────┴────────────────┴────────────────────┘
```

One keyword in minikube is `profile`, 
which defines a set of K8s control-plane configurations. 
It is feasible to keep multiple minikube profiles, each representing an independent cluster, and switch between them when needed.


### MicroK8s

Now, let's take a look at our first natively running tool (there are three of them): **MicroK8s**. 
Different from the others, MicroK8s is controlled by Canonical's *snap*, 
the software packaging and deployment system. 
To interact with this type of K8s environment, 
we will need to use the embedded `kubectl`, which works as a subcommand of `microk8s`.

```
$ microk8s start
$ microk8s status
microk8s is running
high-availability: no
  datastore master nodes: 127.0.0.1:19001
  datastore standby nodes: none
addons:
  enabled:
    dns                  # (core) CoreDNS
    ha-cluster           # (core) Configure high availability on the current node
    helm                 # (core) Helm - the package manager for Kubernetes
    helm3                # (core) Helm 3 - the package manager for Kubernetes
:


$ microk8s kubectl get pod -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-8496b98c8c-sphj2   1/1     Running   0          4m3s
calico-node-5w278                          1/1     Running   0          4m4s
coredns-8557fccfc5-fgznl                   1/1     Running   0          4m3s

```

MicroK8s provides some addon services that you can easily plug in or out whenever you want. 
By checking the system control-plane components in where we usually do, we can find that it uses Calico as the default CNI.
Wait! Where are the common ones like API server, scheduler, and controller manager?

```
$ ps aux | grep "microk8s"
root       86104  3.1  0.8 1314796 69448 ?       Ssl  14:35   0:17 /snap/microk8s/9044/bin/k8s-dqlite --storage-dir=/var/snap/microk8s/9044/var/kubernetes/backend/ --listen=unix:///var/snap/microk8s/9044/var/kubernetes/backend/kine.sock:12379
root       86109  9.8  4.3 1639080 353312 ?      Ssl  14:35   0:22 /snap/microk8s/9044/kubelite --scheduler-args-file=/var/snap/microk8s/9044/args/kube-scheduler --controller-manager-args-file=/var/snap/microk8s/9044/args/kube-controller-manager --proxy-args-file=/var/snap/microk8s/9044/args/kube-proxy --kubelet-args-file=/var/snap/microk8s/9044/args/kubelet --apiserver-args-file=/var/snap/microk8s/9044/args/kube-apiserver --kubeconfig-file=/var/snap/microk8s/9044/credentials/client.config --start-control-plane=true
:

$ ls /etc/systemd/system/*microk8s*
/etc/systemd/system/snap-microk8s-9044.mount
/etc/systemd/system/snap.microk8s.daemon-apiserver-kicker.service
/etc/systemd/system/snap.microk8s.daemon-apiserver-proxy.service
/etc/systemd/system/snap.microk8s.daemon-cluster-agent.service
/etc/systemd/system/snap.microk8s.daemon-containerd.service
/etc/systemd/system/snap.microk8s.daemon-etcd.service
/etc/systemd/system/snap.microk8s.daemon-flanneld.service
/etc/systemd/system/snap.microk8s.daemon-k8s-dqlite.service
/etc/systemd/system/snap.microk8s.daemon-kubelite.service

```

It is clear to see that they are running as system daemons and managed by `systemd`
There are two new components implemented in MicroK8s. 
*kubelite* is the all-in-one service running almost the whole control-plane of K8s; 
we can inspect this design from the arguments of the process. 
The other one is *k8s-dqlite*, which acts as the datastore.
Although we would find `etcd` and `flannel` under the systemd configuration directory, 
they are not running at all.

#### Uploading container images to Native Goblin K8s 

Also, MicroK8s is not able to use your local container images directly. 
It uses a self-installed, separate `containerd` instance with a specified namespace.

```
$ docker save maligo:latest | microk8s ctr images import -
docker.io/library/maligo:latest         	saved
application/vnd.oci.image.index.v1+json sha256:642ee1e8a7cda02a10a54c2b7d2f069c2827bd0b7402100dd7e7ee834e6892f4
Importing	elapsed: 26.6s	total:   0.0 B	(0.0 B/s)
```

So, we can either upload the image to a private image registry, or for a fast deployment evaluation, 
just import the image into the contianerd of MicroK8s.


### K3s

The naming of **K3s** makes sense, but it needs a small tweak 😉. 
If you know that K8s got its abbreviation because there are 8 characters in the middle 
(and so does o11y for observability, which is somehow too much for me...), 
the team brought this lightweight K8s, 
so they representatively reduced the 10 characters by half, leaving 5 letters, and then came up with K3s, brilliant!


```
$ sudo k3s kubectl get pod -n kube-system
NAME                                      READY   STATUS      RESTARTS       AGE
coredns-54996dc9b4-fzzn5                  1/1     Running     0              6m46s
helm-install-traefik-crd-v7gkj            0/1     Completed   0              6m44s
helm-install-traefik-xnvfp                0/1     Completed   2 (6m9s ago)   6m44s
local-path-provisioner-58d557dc48-bc6fm   1/1     Running     0              6m46s
metrics-server-6dc596dfb8-kkfd4           1/1     Running     0              6m46s
svclb-traefik-70f9ba28-llhcr              2/2     Running     0              5m54s
traefik-59b7647586-9c5qf                  1/1     Running     0              5m54s
```

Similar to Microk8s, we don't find the familiar control-plane components running as K8s Pods.
Moreover, K3s's binary itself is an all-in-one process. 
Instead of running them one by one like Microk8s, 
those componenets are running together in a single process (that is, `/usr/local/bin/k3s`). 
To check it yourself, you can view the logs from the system daemon:
`sudo journalctl -u k3s.service`.


#### The containerd namespace of Native Goblin K8s 

We know the containerd in native goblin K8s is not the same as the containerd on local host (check `/run`).
When I try to list the images used in K3s, I find that the containerd namespaces are also different.

```
$ sudo k3s ctr namespaces list
NAME   LABELS
k8s.io

$ sudo ctr namespaces list
NAME         LABELS
moby
moby_history
```

As MicroK8s and k0s also use containerd as the container runtime, they have their control-plane images stored in `k8s.io` 
by default as well[^serverfault].
This is because this name is hardcored in containerd's [CRI plugin](https://github.com/containerd/containerd/blob/main/internal/cri/constants/constants.go#L21), making sure any request from K8s are isolated in this namespace. 
On the other hand, the `moby` namespace on my local host is created on the [Docker side](https://github.com/moby/moby/blob/6671fe46aa945930d11339a4b6a08ca83543b868/daemon/config/config.go#L58) (so does [`moby_history`](https://github.com/moby/buildkit/blob/d665eb4925bd5a6d87bb4753aa820f1f6a3c8595/control/control.go#L193), which looks like it is used for service recovery).


[^serverfault]: I found someone who [argued this design](https://serverfault.com/questions/1150107/kubelet-breaks-cri-standards-by-running-containers-in-k8s-io-containerd-namesp). The only one responding was not on the same page, so they kind of debated back and forth. Maybe I will try to repond later (joining the war 😈).

### kind

**kind** is named after "*Kubernetes in Docker*".
As its name literally suggests, kind is similar to minikube, 
but Docker is the only driver. 
The less deployment configuration you need to worry about, 
the more it gives you a sense of faster automation during deployment (the shorter deployment time, not a higher success rate). 


In the kind deployment, we can optionally apply a text configurations 
to specify some customizable settings.
See those nice emojis in the log! 🥰

```
$ kind create cluster --config kind-config.yaml
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.36.1) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Not sure what to do next? 😅  Check out https://kind.sigs.k8s.io/docs/user/quick-start/

$ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS                       NAMES
551d206c11d2   kindest/node:v1.36.1   "/usr/local/bin/entr…"   3 minutes ago   Up 2 minutes   127.0.0.1:36389->6443/tcp   kind-control-plane

$ kubectl get pod -n kube-system
NAME                                         READY   STATUS    RESTARTS   AGE
coredns-589f44dc88-cvxk4                     1/1     Running   0          8m49s
coredns-589f44dc88-mhs2l                     1/1     Running   0          8m49s
etcd-kind-control-plane                      1/1     Running   0          9m3s
kindnet-r8mqv                                1/1     Running   0          8m48s
kube-apiserver-kind-control-plane            1/1     Running   0          9m4s
kube-controller-manager-kind-control-plane   1/1     Running   0          9m3s
kube-proxy-sxm8x                             1/1     Running   0          8m49s
kube-scheduler-kind-control-plane            1/1     Running   0          9m3s
```

Clearly from the output, we are able to verify that kind is running in a Docker container 
(its image name is `kindest` 😆), and the
local kubectl points to the kind cluster and shows the expected control plane.

Inside this kind Docker container, it runs containerd as the K8s container runtime.
I dug around for a while in kind's containerd environment and found there are 9 containers running, 
one more than the ones shown above. 
Then, I figured it out that the additional one was sitting in the other namespace. Suprise!

```
$ kubectl get namespaces
NAME                 STATUS   AGE
default              Active   5h35m
kube-node-lease      Active   5h35m
kube-public          Active   5h35m
kube-system          Active   5h35m
local-path-storage   Active   5h35m

$ kubectl get pod -n local-path-storage
NAME                                      READY   STATUS    RESTARTS   AGE
local-path-provisioner-855c7b7774-5cflk   1/1     Running   0          5h35m
```

The mentioned usage in nested goblin K8s that needs attention is like [image loading](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster) and [service port forwarding](https://kind.sigs.k8s.io/docs/user/configuration/#extra-port-mappings). 

kind has the `load` subcommand for image loading,
which can replace the pipeline command of `docker save` and `ctr images import`.

```
$ kind load docker-image $IMAGE_NAME
```

You might also define port explosure in the booting configuration. Here is my example:

```
$ cat goblin-k8s/kind-config.yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /proc
        containerPath: /procHost
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
        listenAddress: "0.0.0.0"
        protocol: TCP
```
          
### k0s

**k0s** looks literally similar to K3s, but with a clearer ambition: *zero friction, zero dependency, and zero cost*.
As it is the youngest one among the other native goblins, let me go through a more detailed deployment process:

```
$ sudo k0s install controller --single --enable-worker
$ sudo k0s start
$ sudo k0s status
Error: status: can't get "status" via "/run/k0s/status.sock": Get "http://localhost/status": dial unix /run/k0s/status.sock: connect: no such file or directory

$ sudo k0s status
Version: v1.36.3+k0s.2
Process ID: 186471
Role: controller
Workloads: true
SingleNode: true
Kube-api probing successful: true
Kube-api probing last error:
```

The first step of k0s deployment is configuring the worker node you want. 
In above example, I defined it as a controller (master node), the cluster is just a standalone node, 
and therefore it also acts like a worker to sustain the application workload. 
Then, once we boot it up, 
there is definitely a few-minutes delay for the cluster to become available. 
All other distributions have this reasonable boot-up time. 


```
$ sudo k0s kubectl get pod -n kube-system
NAME                              READY   STATUS    RESTARTS   AGE
coredns-7656c59669-v8ml4          1/1     Running   0          80s
konnectivity-agent-vn4mg          1/1     Running   0          79s
kube-proxy-62qmw                  1/1     Running   0          79s
kube-router-68k4z                 1/1     Running   0          79s
metrics-server-67bc669cf4-rhj44   1/1     Running   0          75s
```

I actually use another k0s configuration for above control-plane settings. 
This is because, in single node mode, there is no (need to have a) `konnectivity-agent` to support cluster-wise networking.
Similarly, you are able to find the missing components in process list, as they are executed one by one, 
rather than in the same style as `/usr/local/bin/k3s` and `kubelite` of MicroK8s.
The three native goblins are still three different codebases and have their own system designs.

```
root      186471  2.7  1.3 1436388 110860 ?      Ssl  15:48   0:11 /usr/local/bin/k0s controller --enable-worker=true --single
kube-ap+  186482  5.3  0.6 1310092 51632 ?       Sl   15:48   0:22 /var/lib/k0s/bin/kine --compact-interval=0 --endpoint=sqlit
kube-ap+  186490  9.2  3.4 1549892 279708 ?      Sl   15:48   0:39 /var/lib/k0s/bin/kube-apiserver --enable-admission-plugins=
kube-sc+  186522  0.4  0.6 1309112 53532 ?       Sl   15:48   0:02 /var/lib/k0s/bin/kube-scheduler --authentication-kubeconfig
kube-ap+  186523  3.3  1.3 1400444 105788 ?      Sl   15:48   0:14 /var/lib/k0s/bin/kube-controller-manager --allocate-node-ci
root      186543  4.8  0.7 1372728 63608 ?       Sl   15:48   0:19 /var/lib/k0s/bin/containerd --root=/var/lib/k0s/containerd
root      186562  4.4  1.0 1320316 84700 ?       Sl   15:48   0:18 /var/lib/k0s/bin/kubelet --cert-dir=/var/lib/k0s/kubelet/pk
```

## Wrapping Up the Goblins

It is fun to quickly study and try-out these mini-systems. 
Of course, confidently saying which one works better than the others in a specified case would require 
a more comprehensive diagnosis.
There are still some interesting topics I have in my mind for further investigation:

- How does container-in-container work? 
(I understand that Linux namespace and multithreading make it theorically possible)

- How do their special, customized CNIs work, and what is [kine](https://github.com/k3s-io/kine)?

- How's real-world edge IoT use cases of native goblin K8s?

On the other hand, a goblin K8s being lightweight and fast to deploy 
does not mean using it allows us to skip the knowledge to operate and troubleshoot a K8s system.
We still need to the ability to understand what is happening under the hood.

{{< figure src="./microk8s-not-running.png" caption="I faced the same kind of trouble as these guys. The issue was caused by unclear error messages." >}}

Happy Qixi Festival!




