rm(list = ls())
args = commandArgs(trailingOnly=TRUE)

res = read.csv(file="results_skato.csv")
colnames(res) = c("Bin", "SKAT-O")
summary = read.csv(file = "biobin/summary.tsv", sep = "\t")

lastIndex = regexpr("_[^_]*$", res$Bin)

res$Bin = substr(res$Bin, lastIndex + 1, nchar(as.character(res$Bin)))
res$Bin = gsub(',', '_', res$Bin)
summary$Bin = gsub('/', '|', summary$Bin)

output = merge(summary, res, by = "Bin")
output$`SKAT-O` = as.numeric(output$`SKAT-O`)

output = output[order(output$`SKAT-O`, decreasing = F),]
output[, ncol(output) + 1] = p.adjust(output$`SKAT-O`, method = "fdr", n = nrow(output)) 
colnames(output)[ncol(output)] = "FDR"
output[, ncol(output) + 1] = p.adjust(output$`SKAT-O`, method = "bonferroni", n = nrow(output)) 
colnames(output)[ncol(output)] = "Bonferroni"

colnames(output)[which(colnames(output) == "SKAT-O")] = paste("R:", args[1], sep = "") 
write.csv(output, file="results_summary.csv", row.names = F, quote = F)