### initializeYetiBackend.R
###
### this script is intended to be sourced during an mpirun 
### call to a cluster whose nodes are named according to
### the regexp "compute-\d-\d{1,2}" (e.g. compute-0-2).
###
### See 'sge_submission_script.sh' for an example of an SGE
### job submission that uses mpirun.
###
### See 'exampleYetiScript.R' for a toy example

# cleanup workspace to minimize size of data
# transfered between nodes
rm(list=ls())

# safe guard against improper MPI shutdown
.Last <- function(){
    if (is.loaded("mpi_initialize")){
        if (mpi.comm.size(1) > 0){
            print("Please use mpi.close.Rslaves() to close slaves.")
            mpi.close.Rslaves(comm=1)
        }
        print("Please use mpi.quit() to quit R")
        .Call("mpi_finalize")
    }
}

# robustly load packages
loadPackages <- Vectorize(function(package) {
  # package should be a string of a legit package name.
  package <- as.character(package)
  
  is.pkg.usable <- tryCatch(eval(bquote(library(.(package))))
                            ,error=function(e){FALSE})
  
  if (is.logical(is.pkg.usable) && !is.pkg.usable) {
    cat(package, "is not available. Will try manually installing from Berkeley's CRAN Mirror...\n")
    install.packages(package,verbose=FALSE,dependencies=TRUE,repos="http://cran.cnr.berkeley.edu/")
  } 
  
  return( eval( bquote(require(.(package))) ) )
})


nHosts <- as.numeric(Sys.getenv('NHOSTS'))
nCores <- as.numeric(Sys.getenv('NSLOTS'))

# initialize "full", RMPI cluster to figure out which nodes
# are playing host and how many slots are allocated 
loadPackages("doMPI")
rmpi.cl <- startMPIcluster()
registerDoMPI(rmpi.cl)

cl.master.node <- mpi.get.processor.name()

cl.slave.nodes <- foreach(i=seq.int(rmpi.cl$workerCount),.combine=c) %dopar% {
	mpi.get.processor.name()
}

# collect and organize slot allocation
core.dist <- table(c(cl.master.node,cl.slave.nodes))
host.names <- names(core.dist)

# output hosts and allocated cores
cat("running script on", nCores, "cores with distribution:\n")
print(core.dist)

# close cluster down
closeCluster(rmpi.cl)

# start a SOCK cluster between the scheduled hosts
loadPackages("doSNOW")
sock.cluster <- makeCluster(host.names,type="SOCK")

determineFreeCores <- function() {
	# extract node name
	node.name <- Sys.info()["nodename"]

	# make sure node.name matches a potential host
	# note that this regexp is cluster-specfic.
	# Should you move to another cluster, you'll
	# have to modify the pattern appropriately.
	node.name <- regmatches(x=node.name,
		m=regexpr(pattern="compute-\\d-\\d{1,2}",text=node.name))
	
	# look up free cores from core.dist
	free.cores <- core.dist[node.name]
	return(free.cores)
}

# export environment to nodes
clusterExport(cl=sock.cluster, list=ls())

# register snow cluster for use with outer foreach.
registerDoSNOW(sock.cluster)