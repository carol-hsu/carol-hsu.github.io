---
title: "Getting Start with Aya: Building eBPF Programs in Rust"
description: "First attempt to explore a new language and technology at a fast pace, while also turning it into a post."
date: 2026-05-26
draft: false
tags: [
    "aya",
    "ebpf",
    "rust"
]
categories: [
    "study"
]
---

I've learned the basics of Rust and [the fundamentals of eBPF](../ebpf). 
Now I want to go deeper into both, and it felt natural to explore them together through a practical project.
That's why I decided to study [Aya](https://github.com/aya-rs/aya), 
a Rust library for eBPF, 
and follow its learning materials while building a small eBPF project of my own.

I'll skip most of the general Rust background (package management, syntax, and ecosystem), 
as I plan to cover that in a separate post. 
Here, I'll focus on the questions and interesting points that come up while working with Aya.


## Goal

The goal is to work through the official tutorials, 
including [building an XDP firewall](https://aya-rs.dev/book/start/index.html)
and the posts from Loseph Ligier of
[implementing tracepoints](https://dev.to/littlejo/lets-introduce-ebpf-and-aya-40ji).
Along the way, I'll document the journey.
As a beginner, I expect to run into plenty of questions. 
From there, I'll explore additional features or possible optimizations as follow-up practice.

## Environment Setup

For this study, 
I set up a Linux VM (Ubuntu 24) on my laptop. 
Several libraries and tools are required to develop and run Aya projects.


### For Rust

Both the Aya tutorials and Joseph Ligier's blog 
provide clear prerequisite steps, so I won't repeat everything here. 
Instead, I'll summarize the key parts with a few notes from my own experience.

- **Install Rust**: 
    Follow the official [installation script](https://rust-lang.org/tools/install/) and steps.

- **Set up the toolchain** (stable + nightly): 
    This is essentially choosing your Rust version. 
    The *nightly* toolchain provides the latest features and fixes (updated daily), 
    but it can be unstable. 
    In practice, Aya uses mostly stable Rust with some nightly components.

- **Install required crates**, `bpf-linker` and `carge-generate`:
    These two crates can be managed by Cargo, and installed by command `cargo install`.
    One interesting finding: *bpf-linker* is developed by the Aya project, 
    and they recommend installing it via [cargo-binstall](https://github.com/cargo-bins/cargo-binstall), 
    which downloads a prebuilt binary directly from GitHub. 
    I wasn't sure at first this approach has trade-offs (e.g., security or skipping the build process), 
    but it is significantly faster than building from source.


    ```sh
    $ cargo binstall --disable-telemetry --force bpf-linker
     INFO resolve: Resolving package: 'bpf-linker'
     WARN The package bpf-linker v0.10.3 (x86_64-unknown-linux-musl) has been downloaded from github.com
     INFO This will install the following binaries:
     INFO   - bpf-linker => /home/nosus/.cargo/bin/bpf-linker
    Do you wish to continue? [yes]/no yes
     INFO Installing binaries...
     INFO Done in 32.885914979s
    
    ```
    
    (This latency includes the time to type "yes".)
    
    For comparison, running `cargo install bpf-linker` took about 2 minutes in my environment.
    But, installing *cargo-binstall* itself took around 8 minutes.
    
    On the other hand, installing *cargo-generate* requires some system dependencies like
    `build-essential`, `openssl`, `libssl-dev`, and `pkg-config` on a Ubuntu machine.
    If they're missing, Cargo will tell you through error messages.

- **Install system tool**, `bpftool`:
    This is the command line tool for inspecting the BPF programs. We will learn how to use it during the tutorials.

### For Aya

Aya itself is a collection of Rust crates. 
These crates are installed and configured as part of the project build process, 
so there is no separate framework setup required before development.

Both tutorials I followed are based on the official Aya project template. 
The template can be downloaded and configured interactively with:
`cargo generate https://github.com/aya-rs/aya-template`.
This is why the crate `cargo-generate` is required.

During the template generation process,
the CLI asks for several configuration options, including [the type of eBPF program](https://aya-rs.dev/book/programs/index.html) to create. 
Different program types come with different libraries, attributes, project structures, and example code.
Throughout the tutorials and implementation practice, I mainly experimented with the 
"tracepoint" and "xdp" program types.

## Hands-on Practices 👩🏻‍💻

I completed the XDP firewall and tracepoint syscall monitoring examples mentioned earlier. 
While there are useful Aya examples, 
its official documentation and user guides are still somewhat limited. 
I feel building more advanced implementations 
also requires solid familiarity with Rust to make development smoother and easier to debug.
Because of that, instead of jumping into a larger project immediately, 
I gave myself a smaller practice project: *extending the firewall example with several additional features*. 
Details as below:
- Extend the blocking rule from only IP addresses to IP + port combinations
- Load the block list from a file in userspace
- Store the block list inside an eBPF map so the kernel-space eBPF program can access it
- Apply filtering rules dynamically based on the plain-text file


### Understand Aya

Aya project templates are organized into separate *user-space* and *kernel-space* directories:
`./PROJ-NAME` and `./PROJ-NAME-ebpf`.
The Aya libraries themselves follow the same separation model. 
Crates intended for kernel/eBPF programs are usually marked with the `_ebpf` suffix, 
such as `aya_ebpf` and `aya_log_ebpf`.

There is also a third directory, `./PROJ-NAME-common`, 
which typically contains only shared library code (`./src/lib.rs`). 
Although I did not find explicit official documentation describing how this directory should be used, 
I treated it as the shared space for common methods and data structures between user-space and kernel-space programs.

Now that we understand the recommended project structure, 
the user-space side is relatively familiar since it behaves 
like a normal Rust application running on top of the operating system. 
The more interesting part is the kernel/eBPF side:

#### No standard library and no `main`

The eBPF program entry file (`./PROJ-NAME-ebpf/src/main.rs`) contains the attributes:
[`no_main`](https://doc.rust-lang.org/reference/crates-and-source-files.html#the-no_main-attribute) and
[`no_std`](https://doc.rust-lang.org/reference/names/preludes.html#the-no_std-attribute).

The eBPF program is compiled separately into bytecode and loaded into the kernel. 
Unlike a normal application, 
it is triggered by kernel events rather than starting execution from a traditional `main()` function.

The `no_std` attribute also means the program cannot rely on the standard library, such as `std::fs`, `std::io`,
and`std::collections` , 
since many standard library features depend on operating system functionality that does not exist in kernel space.
One important implication is that crates used by the eBPF program must also support `no_std`. 
For example, the [`network-types`](https://crates.io/crates/network-types)
crate used in the examples is designed to work in this restricted environment.

#### Frequent use of `unsafe`

You will notice many `unsafe` blocks in eBPF programs, 
especially when working with memory access and pointers.
These blocks explicitly tell the compiler, "[I know what I am doing](https://doc.rust-lang.org/book/ch20-01-unsafe-rust.html)."
This is common in low-level systems programming. Aya itself explains this well:
"..The safety features are less important in the context of eBPF as programs often need to read kernel memory, which is considered unsafe."
That sentence largely explains why unsafe appears so frequently in eBPF code.

#### Be careful with memory layout

I also ran into issues related to memory layout because of my own carelessness 
while working with strong type language.
This is an important point in low-level programming: 
data is accessed directly through memory, so type layout, alignment, and representation matter significantly.
We will revisit this issue later 
with a real [bug example](#debugging-and-verification) from my implementation. 
In the meantime, the official Rust documentation on 
[type alignment](https://doc.rust-lang.org/reference/type-layout.html) and 
[representation](https://doc.rust-lang.org/reference/type-layout.html#representations)
is worth reading to know the details.


### Project overview

I outlined my development journey is following stages.

#### Updating dependencies

~~During the implementation, I noticed that the `network-types` crate had already been upgraded to version 0.2.0, 
while the tutorial was still using an older version.~~
They actually updated the tutorial this week -- right before this blog post was published -- 
so I can happily skip the compatibility-fix section and keep the post a bit shorter 🫠

Still, this experience reinforced an important habit: 
always verify the development environment and check whether the latest library versions are being used.

#### Redesigning the data structure of block list

While working through the tutorials, I found Aya doesn't provide [*HashSet*](https://doc.rust-lang.org/std/collections/struct.HashSet.html)-like data structure. 
Therefore, the example IP block list is implemented using a *HashMap* instead:

```rust
use aya_ebpf::maps::HashMap;

#[map] 
static BLOCKLIST: HashMap<u32, u32> = 
        HashMap::<u32, u32>::with_max_entries(1024, 0);
```

In this example, the value stored in the HashMap is just a dummy number because only the key is actually used for lookups.

To support both IP addresses and ports at the same time, 
I changed the key type from `u32` to a custom struct.
I also placed this type inside the `PROJ-NAME-common` crate since both the user- and kernel-space programs 
need to share it.


```rust
// in ./PROJ-NAME-common/src/lib.rs 

#![no_std]
#[derive(Copy, Clone)]
pub struct IpAddr {
    pub addr: u32,
    pub port: u16,
}

#[cfg(feature="userspace")]
unsafe impl aya::Pod for IpAddr {}
```

The final line (`unsafe impl aya::Pod`) was added after I encountered the following compilation error:
`the trait 'Pod' is not implemented for 'aya_study_common::IpAddr'`. 
According to the [official documentation](https://docs.rs/aya/latest/aya/trait.Pod.html), 
the Pod trait is used for safely treating a type as raw bytes when transferring data between user and kernel spaces.
Then, the implementation is only required on the user side. 
The Cargo configuration also needs to enable this feature explicitly:

```sh
$ cat ./PROJ-NAME/Cargo.toml
:
[dependencies]
PROJ-NAME-common = { path = "../PROJ-NAME-common", features = ["userspace"] }
:
``` 

#### Debugging and verification

After the program successfully compiled and executed, I used *iPerf3* to generate real traffic for testing.
My Ubuntu VM running the XDP firewall acted as the client and attempted to connect to an iPerf3 server 
running on the host machine. 
I expected the initial handshake packets to be blocked, 
since the returning packets should have been dropped immediately after arriving at the VM.

However, something critical happened: the traffic that should have been blocked was still passing through.
I discovered that the eBPF map lookup was failing because of the 
[memory alignment issue](#be-careful-with-memory-layout)
mentioned earlier. 
To inspect the problem, we can use `bpftool` to examine the eBPF map directly:

```sh
$ sudo bpftool map
2: prog_array  name hid_jmp_table  flags 0x0
	key 4B  value 4B  max_entries 1024  memlock 8576B
	owner_prog_type tracing  owner jited
6: hash  name BLOCKLIST  flags 0x0
	key 8B  value 1B  max_entries 1024  memlock 83088B
7: ringbuf  name AYA_LOGS  flags 0x0
	key 0B  value 0B  max_entries 131072  memlock 144280B
8: array  name .rodata  flags 0x80
	key 4B  value 32B  max_entries 1  memlock 416B
	frozen


$ sudo bpftool map dump id 6
key: 02 02 00 0a 30 75 00 00  value: 00
Found 1 element

```
(The key represents `10.0.2.2:30000`. Try decoding how the bytes are laid out in memory 👀)

The solution was to make the struct layout properly aligned. One approach is to add an explicit padding field:
`_padding: u16`. 
Another option is simply changing the port field from `u16` to `u32`, allowing the structure to occupy 
naturally aligned memory space.


### Takeaways

- **It's easy to overthink the small things:** 
    Even with a clear development goal, I still spend too much time exploring side paths during implementation. For example: (1) designing a more comprehensive `ACCEPT/DENY` rule (2) creating a more realistic evaluation environment by reconfiguring VM networking (3) deciding which configuration format to use, `ini`, `toml`, `yaml`, or `json` (In the end, I simply used plain text because the project did not require complex key-value configurations.) Of course, these explorations are still valuable, and every design decision teaches something.
    Development is a bit like life: the effort you put in often pays off later in unexpected ways.

- **Kernel programming feels very different from high-level development:** 
    Writing Linux kernel/eBPF programs introduces many additional constraints compared to normal application development. Like 
    - limited access to common libraries
    - more difficult debugging workflows
    - frequent use of unsafe
    - stricter memory-layout requirements

    The debugging experience especially depends heavily on compiler and verifier feedback. At the same time, developers often need to explicitly use unsafe blocks and take responsibility for low-level operations themselves.

    This is difficult to fully understand simply through reading materials. Actually building and debugging kernel-space programs gives a much clearer sense of the trade-offs involved.
    
    I also feel that performance, efficiency, and security requirements become far more important in kernel-space development. Kernel programs operate with privileged access and affect the entire system rather than a single application. As a result, both performance gains and implementation mistakes can have much larger impact.


- **Working with Rust in a real project teaches much more:**
    Similar to the previous point, building a real project teaches far more than simply learning syntax from books or tutorials. Although I had already studied Rust before, this project helped me revisit
environment setup, 
testing workflows, crate dependencies/interactions, and project-level execution and organization.
I also encountered several Rust features that were new to me 
(even if they are common for experienced Rust developers), including the attributes `no_std`,
`no_main`, and `cfg`; `unsafe`; the one-liner/lambda function as the closure syntax (`|...|`).
Again, working on the hands-on practice provided much deeper understanding 
than reading (even more than this post itself.)

## Technical Deep Dive 

During this implementation practice, 
I revisited some topics from my previous study notes and [TODO list](../ebpf). 
I'd like to share a deeper discussion here, 
but for now I'll leave this section as a placeholder and plan to complete it next week 😗.

### eXpress Data Path (XDP)

### eBPF Maps

## Next Steps

I originally wanted to challenge myself: how quickly could I explore a new topic and turn it into a blog post?
Since this was only a small project, I optimistically gave myself one week.
Well... it was definitely faster than my previous posts, but still not that fast 🤣
I spent around: 5 days learning Aya, going through the tutorials, and drafting the outline;
2 days implementing the project and summarizing the technical findings, and; 
another 5 days just writing the post itself.
And technically, I still haven't finished it yet! (Just look at the unfinished last section 🤦🏻‍♀️)
This experience reminded me that put ideas together into a coherent story 
is often the most time-consuming. Respect to all writers.

Of course, this is far from the end of my journey with Rust, eBPF, and Aya. 
There are still many topics I want to explore further:
- [tokio](https://github.com/tokio-rs), the asynchronous process in Rust, we have it in the Aya tutorial
- [CO-RE implementation](https://eunomia.dev/tutorials/)
- reimplementing or prototyping larger projects for practice. I also came across the inspiring 
[example](https://yuki-nakamura.com/2024/12/28/tetragon-mini-by-rust-ebpf-based-process-monitoring) from Yuki Nakamura.

Happy Coding!

