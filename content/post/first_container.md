---
title: "The Chaotic and Misleading Use of Linux Containers"
description: "The mindset behind how and why we run containers"
date: 2025-03-03
draft: false
tags: [
    "container",
    "rethinking"
]
categories: [
    "study"
]
---

While working with containers for several years, I've come across statements like these:

1. *We package the development environment in this Docker image so you can build it, run it, and do your implementation there.*
2. *We shouldn't containerize parallel programs -- it doesn't provide any benefit.*
3. *We containerize our service, so it is now a system of microservices.*

I don't agree with them. Let me explain why. 

{{< expand "Still yammering -> someone said: why are you so picky!? " >}}
I understand that there's nothing wrong with solving a problem using whatever works and makes life easier. 
But please, don't be loud and dismissive if you haven't considered 
whether the tool was **even designed for this purpose**. 
Complaining about missing features or saying "why is this so hard to use?" 
becomes indefensible when you're using **the wrong tool in the first place**.
{{< /expand >}}

## Docker =\\= Container

I want to emphasize that when I talk about containers, 
I mean *Linux* containers -- which are implemented using `namespaces` and `cgroups` in the Linux kernel. 
This is also known as *OS-level virtualization*.

**Docker**, on the other hand, is a system software that makes it easy to deploy applications as containers. 
When Docker was introduced in 2013, it played a major role and made container popular. 
Later, Docker was split into two projects:
* moby: Focuses on platforming and orchestration, providing a user interface and related APIs.
* containerd: Acts as the `container runtime`, managing the container lifecycle.

The container ecosystem is now governed by [Open Container Initiate (OCI)](https://opencontainers.org), 
a Linux Foundation standard that defines container image formats and runtimes. 
This means that, any software that follows OCI standards and gains community acceptance can replace Docker.
In fact, you can create your own container deploying platform without Docker products.
Currently, the other major players are [Red Hat](https://github.com/containers) (CRI-O, Podman, ... etc) and
Mirantis (the enterprise version of Docker engine).

#### Clarifying statement #1

The more accurate term is "OCI image" or "container image" instead. 
However, don't worry -- saying "Docker image" is still widely understood by most people.

## Container and VM: similar but not the same

Container is not designed to replace virtual machine (VM) entirely.
 
Both container and VM are virtualization technologies that
benefit development and deployment.
They allow us to rethink how different functionalities are managed between 
applications and infrastructure, enabling:
* **Flexibility**: Avoids exclusive use cases and reduces dependency on low-level components.
* **Scalability**: Much easier to deliver, run, and terminate as needed, with proper resource isolation.
* **Availability**: Works with low-latency operations. 
Also, it simpilifies setting up abstraction layers/controllers/message queues for traffic and load management, 
improving responsiveness to clients.

Below is a summary table comparing their key differences:

| | **VM** | **Container** |
|:----|:----:|:----:| 
|Virtualization concept| Packs OS to share the hardware | Packs application to share the OS |
|Manager | Hypervisor | Container runtime; [runc](https://github.com/opencontainers/runc) in Linux|
|Deployment/Boot time| High | Low |
|Image/snapshot size | Large | Small |

Now, we know containers are lighter and faster, 
when do they fall short? In other words, when is a VM the better choice?

The key reason containers are lightweight and fast is that 
they "borrow" more OS-level mechanisms/functions beneath, and share more system resources with other containers. 
Yet, this also introduces limitations. 
If a container does not use the same OS kernel as the host machine, 
it requires additional support from control plane components in the software stack.
For example, running Linux containers on macOS or Windows requires 
either a Linux VM as a host or a compatibility layer like Windows Subsystem for Linux (WSL). 
Additionally, containers may face deployment challenges when workloads depend on specialized hardware, 
and they often require extra configurations for networking and security --- issues that VMs handle more seamlessly.
In short, more fine-grained virtualization methods provide better efficiency 
but come at the cost of increased infrastructure complexity.

#### Clarifying statement #1

I wouldn't use containers as a development environment. 
They're not designed for it, and they won't automatically provide a smooth development experience.

Statement #1 is fairly common in coursework, 
where instructors package development environments in Docker to spare students from setting up dependencies 
manually -- hoping they can start coding right away without questions (or excuses) at the beginning of a project.
While this thought has good intentions, it overlooks some key issues:

* **Skipping the fundamentals**: 
Computer science students aren't just learning to write code -- 
they're learning to run programs correctly. 
Hiding the burden of setting up a development environment prevents them 
from understanding why certain dependencies and configurations are necessary.

* **Encouraging bad practices**: 
If students or junior engineers get used to "coding in a container and repackaging it", 
they might carry this habit into real-world development, causing unnecessary complexity and frustration. 
Using a proper IDE and gaining a clear understanding of computing environment is far more practical.

* **Introducing more debugging challenges** (which I'm actually glad to see it!): 
Infrastructure-as-Code and scripted deployments aim to simplify setup, 
but they also add extra layers of complexity. 
What happens when errors still occur during environment setup 
(breaking the instructors' initial expectation of saving students' time)?
Even if students understand every line of the Dockerfile, 
can they troubleshoot issues like missing `apt-get` packages or errors in 
`CMake`, `Bazel`, or `Ansible`/`Terraform` (bye HashiCorp 🥲)? 
But honestly, I welcome these challenges -- solving real problems is how we grow.

That said, containers are great for deployment and testing. 
If I were an instructor, I'd teach students to deploy projects in containers 
*for validation and delivery*
while ensuring they develop in a proper IDE with a well-configured environment.

#### Clarifying statement #2

Parallel computing applications typically focus on maximizing throughput. 
Some may expect performance improvements after containerizing such applications, 
but containerization itself *does not* guarantee better performance. 
Whether a parallel program should run in a container is not about direct performance gains 
but about deployment efficiency and service quality. 
To achieve meaningful performance improvements, 
one should rethink the application's overall architecture alongside the chosen deployment method.


## Containerization is just a deployment method

As described earler, containers enable fine-grained workload deployment,
helping us build more efficient and scalable services.
One common architecture leveraging containers is **microservices**,
which offers several advantages over monolithic applications: 

* **Decouple the development and deployment**: 
Each microservice can be developed, deployed, and updated independently, 
allowing project owners to use different languages, frameworks, and storage solutions 
without affecting others' schedules.

* **Optimize resource allocation**: 
We can carefully allocate the suffient resource to each microservice so as to
reduce the overall computing cost. 
Smaller, independent components are also easier to scale and schedule.

* **Improve fault isolation**: 
If a single microservice crashes, 
it is easier to identify and fix the issue, reducing the risk of failure cascading across the system.

Regardless, not all programs or services benefit from a microservices architecture. 
Poorly planned design choices, 
such as incorrect separation of components or inefficient data pipelines, 
can lead to excessive networking or I/O overhead, duplicated implementations, 
and unclear ownership between services. 
Microservices should be adopted for genuine improvements, 
not just because they're a popular trend or a selling point for managers and customers.

#### Clarifying statement #3

Moving system components from VMs to containers doesn't automatically make them microservices. 
As mentioned earlier, structural changes require careful design -- 
simply containerizing programs might give the appearance of a microservices system 
but provide no real benefits, only headaches.


## Non-related summary 🤪 

During my gap year, I sometimes feel anxious about not making enough progress.
Writing code doesn't always help -- it can feel like I'm just building another toy project.
But I've realized that writing things down helps me organize my thoughts, study new things, 
and feel a sense of achievement. 
It's actually something I've been doing for years.

I'm still figuring out what a technical posts should look like, 
they probably include more personal opinions and have a casual style 🤔.

---

Happy coding!
