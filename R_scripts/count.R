args = commandArgs(trailingOnly=TRUE)
input_file = args[1]
output_file = args[2]

phe_bin = read.csv(file = input_file)
phe_bin = phe_bin[, c(2, which(colnames(phe_bin) %in% c("RBM12", "NDUFB6", "DLGAP4-AS1", "DLGAP4.AS1", "ATP6V1A", "RECK", "SLC35E1", "RFX3", "ATP8A1", 
                                                        "kegg.Pyrimidine.metabolism", "kegg.Protein.processing.in.endoplasmic.reticulum", 
                                                        "kegg.Pentose.and.glucuronate.interconversions", "kegg.Pancreatic.secretion", "kegg.RNA.polymerase", "kegg.Pantothenate.and.CoA.biosynthesis")))]
phe_bin = phe_bin[10:nrow(phe_bin),]


controls = apply(phe_bin[which(phe_bin[,1] == 0),], 2, function(x){sum(x > 0)})
controls_total = sum(phe_bin$phe == 0)
cases = apply(phe_bin[which(phe_bin[,1] == 1),], 2, function(x){sum(x > 0)})

counts = data.frame(controls, cases)
counts[1,1] = controls_total
counts$case_percent = counts$cases/counts$cases[1] * 100
counts$control_percent = counts$controls/counts$controls[1] * 100

write.csv(counts, file = paste(output_file, "counts.csv", sep = "_"))
