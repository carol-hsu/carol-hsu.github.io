---
title: "My Academic Family Tree: 5 Degrees from Dijkstra"
description: "Just for showing off that I have 6-degree separation with Dijkstra"
date: 2026-06-19
draft: False
tags: [
    "fun",
    "coding",
    "python"
]
categories: [
]
---

Before finding out that I'm one of Dijkstra's academic descendants, 
the only computer science pioneers whose careers I had really dug into
were [Jack Dongarra](https://en.wikipedia.org/wiki/Jack_Dongarra)
and [Leslie Lamport](https://en.wikipedia.org/wiki/Leslie_Lamport).


Let's get to the point, here comes the DFS traversal result of my PhD tree (credit by Ada).

---

 [Cornelis B. Biezeno](https://de.wikipedia.org/wiki/Cornelis_B._Biezeno)

 └ [Aad van Wijngaarden](https://nl.wikipedia.org/wiki/Adriaan_van_Wijngaarden) (TU Delft)

 &nbsp;&nbsp;&nbsp;&nbsp;└ [Edsger W. Dijkstra](https://nl.wikipedia.org/wiki/Edsger_Dijkstra) (UvA)

 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└ [A. Nico Habermann](https://en.wikipedia.org/wiki/Nico_Habermann) (TU Eindhoven)

 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└ [Anita K. Jones](https://en.wikipedia.org/wiki/Anita_K._Jones) (CMU)

 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└ [Karsten Schwan](https://en.wikipedia.org/wiki/Karsten_Schwan) (CMU)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└ [Ada](https://sites.cc.gatech.edu/home/ada/) (Georgia Tech)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└ ME! (Georgia Tech)

---

## The Dutch Root Node


The root of my PhD family tree is Biezeno, who was trained as a mechanical engineer 
and later also taught mathematics. His student, van Wijngaarden, came from a mathematics background, 
went on to found CWI, and later supervised Dijkstra. 
Together, they were among the earliest pioneers of computing in the Netherlands 
and contributed to the development of the country's first [commercially available computer](https://en.wikipedia.org/wiki/Electrologica_X1). 
Habermann is the first node in this path heading to US.


Although most people know Dijkstra for his work on algorithms, 
he made foundational contributions to systems research,
including [operating system](https://en.wikipedia.org/wiki/THE_multiprogramming_system) design, 
[resource allocation](https://en.wikipedia.org/wiki/Semaphore_(programming)), 
[concurrency control](https://en.wikipedia.org/wiki/Banker%27s_algorithm), 
and [fault tolerance](https://en.wikipedia.org/wiki/Self-stabilization) in distributed systems.[^lamport_pdf]
His impact on the field is still recognized today through the [Dijkstra Prize](https://en.wikipedia.org/wiki/Symposium_on_Principles_of_Distributed_Computing).
Since then, every descendant in this path has worked primarily in systems-related research.

[^lamport_pdf]: Putting one of Lamport's research article about Dijkstra's [concurrent algorithms](https://lamport.azurewebsites.net/pubs/dijkstra.pdf) here to remind myself to review it.

## Dijkstra's Algorithm

This is the well-known shortest path algorithm[^dijkstra_note] from Dijkstra that almost all CS students 
learn it.
Strong LeetCoders probably know it as well. 
Many problems can be solved by applying Dijkstra's Algorithm, like 
[743. Network Delay Time](https://leetcode.com/problems/network-delay-time/) and 
[787. Cheapest Flights Within K Stops](https://leetcode.com/problems/cheapest-flights-within-k-stops/).
One fun fact is, Dijkstra designed this algorithm during [a coffee break](https://dl.acm.org/doi/epdf/10.1145/1787234.1787249).

[^dijkstra_note]: The copy of [paper/note](https://www.cs.yale.edu/homes/lans/readings/routing/dijkstra-routing-1959.pdf) is published in 1959.

### Implementation in Python

As a systems person, I should probably introduce one of Dijkstra's distributed-systems ideas/principles 
in this post. However, that would probably take me more than twice as long to publish it 🤣. 
Engineering work is easier than research study to me.

Also, as a Rust learner, 
I should probably implement this in Rust for practice. 
But since [Python was created at CWI](https://www.youtube.com/watch?v=GfH4QL4VqJ0), 
let me use the easier way to introduce the algorithm with the mentioned problem 743.

In this problem, we are given a directed, weighted graph. 
Each edge represents the time needed to travel from one node to another. 
Starting from a given node `X`, 
we need to determine how long it takes to reach every node in the graph.
In other words, we find the shortest path from `X` to every other node, 
then return the longest of those shortest-path times.

Except the weighted edges, I defined three additional data structures:
- `frontier`: a min-priority queue (implemented by a heap) stores
candidate nodes to visit, ordered by their current travel time from `X`.
Each item is a tuple: `(current shortest time from X, node ID)`.

- `visited`: a set of nodes whose shortest-path time has been discovered.
Once a node is popped from `frontier` and marked as visited, 
no shorter path to it can exist, so we don't need to process it again.

- `visit_time`: an array storing the current shortest known time from `X` to every node. 
`visit_time[u]` indicates current shortest time from X to `u`. 
Initially all (except `visit_time[X]`, which is `0`) are set with the infinite value.
At the end, 
the largest value in this array is the network delay time.

Below is the main traversal loop:

```python
while len(frontier) > 0:
    
    cur_time, node = hq.heappop(frontier)

    # only process the node hasn't been checked yet
    if node in visited:
        continue

    visited.add(node)
        
    # explore this node if it has the outgoing edges
    if node in connect:
        for next_node, time in connect[node].items():

            # see if we need to update its shortest path
            if visit_time[next_node] > time+cur_time:
                visit_time[next_node] =  time+cur_time

                # The updated path may propagate the improvement to impact its downstream nodes
                hq.heappush(frontier, (visit_time[next_node], next_node))
```

After the traversal, 
we can check whether `X` can reach every node by comparing the size of `visited` 
with the total number of nodes. 
If it is smaller, at least one node is unreachable from `X`.


## Okay, Did You Bring This Up Just To Flex?

HAHA, yes --- but not entirely. It is also a moment of self-reflection.

As someone from Taiwan, I feel incredibly grateful to have followed, 
in some small way, the path of people I have long admired. 
I may never have the same impact as my academic ancestors, 
but I am proud of myself for being brave enough to step onto this career path.

Looking at the DFS traversal, the people in this path come from five different countries, 
yet their work and mentorship connect them across generations. How amazing is that?


By the way, I have visited all of the alma maters!

{{< gallery dir="school" >}}
{{< /gallery >}}

(Sorry, I did not take photos when I visited UvA and CMU, but please believe me, 
I really did make it onto both campuses!)
