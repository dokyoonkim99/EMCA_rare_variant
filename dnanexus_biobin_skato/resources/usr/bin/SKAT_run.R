library(SKAT)
library(parallel)

outDir = "intermediate"
files = list.files(path = outDir)
args = commandArgs(trailingOnly=TRUE)
test = args[1]
weight = args[2]
threads = as.numeric(args[3])

lastIndex = regexpr("_[^_]*$", files)
files = substr(files, 1, lastIndex - 1)
files = unique(files)

runSKAT = function(file, test, weight) {
  cat(paste("Starting R", file, '\n', sep = " "))
  cov = read.table(file = paste(outDir, paste(file, "_covar", sep = ""), sep = .Platform$file.sep), sep = ' ', header = F, stringsAsFactors = F)
  cov = cov[,c(-1, -ncol(cov))]
  phe = read.table(file = paste(outDir, paste(file, "_pheno", sep = ""), sep = .Platform$file.sep), sep = ' ', header = F, stringsAsFactors = F)
  geno = read.table(file = paste(outDir, paste(file, "_geno", sep = ""), sep = .Platform$file.sep), sep = ' ', header = F, stringsAsFactors = F)
  geno = geno[,!is.na(geno[1,])]
  geno = as.matrix(geno)
  data = data.frame(cov, phe, stringsAsFactors = F)
  obj = NA
  if (test == "SKAT-logistic" || test == "SKATO-logistic") {
    cat(paste("Test discrete phenotype:", test, '\n', sep = " "))
    obj = SKAT_Null_Model(V1 ~ ., data = data, out_type="D", Adjustment = F)
  }
  else {
    cat(paste("Test continous phenotype:", test, '\n', sep = " "))
    obj = SKAT_Null_Model(V1 ~ ., data = data, out_type="C", Adjustment = F)
  }
  pval_skato = -1
  test_method = strsplit(test, '-')[[1]][1]
  if (weight == "madsen-browning" || weight == "no-weight") {
    cat(paste("Test:", test_method, " Weighing scheme beta(1,1):", weight, '\n', sep = " "))
    pval_skato = SKAT(geno, obj, method = test_method, weights.beta=c(1,1))$p.value
  } else {
    cat(paste("Test:", test_method, " Weighing scheme  beta(1,25):", weight, '\n', sep = " "))
    pval_skato = SKAT(geno, obj, method = test_method, weights.beta=c(1,25))$p.value
  }
  return(c(file, pval_skato))
}

workerfun <- function(file) {
  tryCatch({
    ret = runSKAT(file, test, weight)
    cat(paste("Success ", ret[1], " ", ret[2], '\n', sep = " "))
    return(ret)
  },
  error=function(e) {
    ret = paste("Error row:", file, "\n", sep="\t")
    cat(ret)
    print(e)
    #stop(e)
  })
}

start.time <- Sys.time()

threads
# run in parallel
cl = makeCluster(threads, type="FORK", outfile= "outfile_parallel_log")
clusterExport(cl = cl, varlist=c("test", "weight"))
results = parApply(cl, data.frame(files), 1, workerfun)
stopCluster(cl)
end.time = Sys.time()
time.taken = end.time - start.time
write.csv(file="results_skato.csv", t(results), row.names = F)
