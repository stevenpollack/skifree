
### exampleYetiScript.R
###
### 

source("initializeYetiBackend.R") #load up Yeti Backend

loadPackages(doParallel)
loadPackages(doRNG)	

embarassinglyParallelTask <- function(mu, sigma) {
	### calculate the sample mean and standard deviation
	### of 10^6 Normal(mean=mu,sd=sigma) random variables

	### generate the numbers in parallel,
	### assume doRNG is loaded and backend is registered
	sample.rng <- foreach(j=seq.int(100),
		.combine=c,
		.final=unlist) %dopar% {
		rnorm(n=1e4,mean=mu,sd=sigma)
	}
	data.frame(mean=mean(sample.rng),sigma=sd(sample.rng))
}


parameter.grid <- expand.grid(mu=0:3,sigma=seq(from=1,to=5,length.out=3))

out <- foreach(params=iter(parameter.grid,by='row'),
	.combine=rbind,
	.packages=c("doParallel","doRNG")) %dopar% {
	# determine how many free cores are available
	# at a particular node
	nCores <- determineFreeCores()
	
	# register a multicore backend
	registerDoParallel(cores=nCores)
	registerDoRNG(1234) # make RNG reproducible

	# do the simple calculation, splitting RNG over cores
	embarassinglyParallelTask(mu=params[1,1], sigma=params[1,2])
}

cat("**** expected results: ****\n")
print(parameter.grid)

cat("**** observed results: ****\n")
print(out)

# shut cluster down
stopCluster(sock.cluster)
mpi.finalize()