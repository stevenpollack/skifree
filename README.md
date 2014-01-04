STORM -- Snow mulTicOre RMpi
=====

This repo contains the script(s) necessary to create a STORM cluster.

To understand what a STORM cluster is (and why you may want to use it), imagine you have have access to a cluster with 15 nodes, and 32 cores on each node (managed by something like a SUN Grid Engine). The nodes are named something like node1, node2, ..., node15 and because of the high traffic on your cluster, even a job submission requesting 12 cores may be spread across multiple nodes. 

Using `RMPI` (via the `doRmpi` package, for example) is an acceptable way to leverage any parallelization you've written into your code; however, if you're passing non-trivial amounts of data between the master process and the various slaves, the speed benefits from your parallelized may be overshadowed by the time to move data back and forth. Hence, I propose STORM clusters as a workaround to this problem.

A STORM cluster initially leverages your `rmpi` submission to perform some book-keeping and figure out how many nodes (and consequently, how many slots on each node) the scheduler has allocated for your job. It then replaces the RMPI cluster with a SNOW cluster whose machines are precisely the nodes allocated to your original submission. Each node inside said SNOW cluster is aware of how many cores the scheduler has alloted to it for your job, so anytime a task is given to a core, the core can register a multicore backend (through the `doParallel` package) and perform the assigned task in a parallelized fashion.

An example of a situation where a STORM cluster would be more effective than a simple parallel implementation with `doRmpi` would be when you're calculating values of a function over a particular domain, and the function, itself, is "embarassignly parallel". In this case, `doRmpi` would have every scheduled core peform the function calculation sequentially. However, a STORM cluster could progress through the function's domain by processing several points in parallel (the number of points is equal to the number of nodes scheduled to your job) and inside each batch of points, calculating the function in parallel. 