library(GGally)
library(ggplot2)
library(plyr)

cmd_args <- commandArgs(trailingOnly=TRUE)

plink_fam = cmd_args[1]
plink_pc = cmd_args[2]
output_file = cmd_args[3]


fam = read.table(plink_fam, header=FALSE)
colnames(fam) = c("FID", "IID", "faid", "moid", "sex", "pheno")
pc = read.table(plink_pc, header=TRUE, comment.char = "")
colnames(pc)[1] = "FID"
all = merge(fam, pc, by=c("FID", "IID"))


all$pheno[which(all$pheno == 1)] = "unaffected"
all$pheno[which(all$pheno == 2)] = "affected"

all$pheno = factor(all$pheno, levels = c("unaffected", "affected"))
all = all[order(all$pheno),]


col_idx = 7:11


p = ggpairs(all, columns = col_idx, title = "",  
        axisLabels = "show", columnLabels = colnames(all[, col_idx]), upper="blank", mapping=ggplot2::aes(colour = pheno, alpha=0.1))

##ggally_points(all, ggplot2::aes(colnames(all)[col_idx[1]], colnames(all)[col_idx[2]], color = pheno))
points_legend = gglegend(ggally_points)
p[1,length(col_idx)] = points_legend(all, ggplot2::aes(colnames(all)[col_idx[1]], colnames(all)[col_idx[2]], color = pheno))


png(filename=output_file, height=2000, width=2000, pointsize=5, res=300)
print(p)
dev.off()

file.remove("Rplots.pdf")
