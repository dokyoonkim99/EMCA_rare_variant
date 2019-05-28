library('qqman')

args = commandArgs(trailingOnly=TRUE)
input_file = args[1]
output_file = "gene"

#input_file = "../files_from_geisinger/pathway based-60k-results_summary (2).csv"
#output_file = "pathway"

results = read.csv(file = input_file, stringsAsFactors = F)


png(paste(output_file, "qqplot1.png", sep = "_"), res = 300, width = 1600, height = 1200)
qq(results$pval)
z = qnorm(results$pval / 2)
l = round(median(z^2) / qchisq(0.5, 1), 3)

y_80 = 0.9 * max(-log10(results$R.NA))
text(0.55, y_80, paste(expression(lambda), ":", l))
dev.off()