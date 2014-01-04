
### exampleYetiScript.R
###
### 

source("initializeYetiBackend.R") #load up Yeti Backend

loadPackages("doParallel")
loadPackages("doRNG")	

embarassinglyParallelTask <- function(mu, sigma) {
	### calculate the sample mean and standard deviation
	### of 10^7 Normal(mean=mu,sd=sigma) random variables

	### generate the numbers in parallel,
	### assume doRNG is loaded and backend is registered
	### set seed for reproducibility

	foreach(j=seq.int(1e3),
		.final=function(x){data.frame(mean=mean(x),sd=sd(x))},
		.combine=c,
		.inorder=FALSE,
		.options.RNG=1234) %dorng% {
		rnorm(n=1e4,mean=mu,sd=sigma)
	}
}

parameter.grid <- expand.grid(mu=0:3,sigma=seq(from=1,to=5,length.out=3))

out <- foreach(params=iter(parameter.grid,by='row'),
	.packages=c("doParallel","doRNG"),
	.combine=rbind) %dopar% {
	
	# determine how many free cores are available
	# at a particular node
	nCores <- determineFreeCores()
	
	registerDoParallel(cores=nCores) # register a multicore backend

	# do the simple calculation, splitting RNG over cores
	mu <- params[1,1]
	sigma <- params[1,2]
	embarassinglyParallelTask(mu, sigma)
}

cat("**** expected results ****\n")
print(parameter.grid)

cat("**** observed results ****\n")
print(out)

# shut cluster down
cat("*** cleaning up and shutting cluster down ***\n")
snow::stopCluster(sock.cluster)
detach(package:doMPI)
mpi.quit()