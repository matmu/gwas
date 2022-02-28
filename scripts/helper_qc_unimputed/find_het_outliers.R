
cmd_args <- commandArgs(trailingOnly=TRUE)

input_file = cmd_args[1]
output_file = cmd_args[2]
n_sd = as.numeric(cmd_args[3])


data = read.table(input_file, header=TRUE)


data$het = (data[,5]-data[,3])/data[,5]


m = mean(data$het)
med = median(data$het)
s = sd(data$het)
print(paste0("median", med, "mean", m," sd", s))

print("Max")
print(data[which(data$het == max(data$het)),])
print("Min")
print(data[which(data$het == min(data$het)),])
summary(data$het)

png(filename=paste0(tools::file_path_sans_ext(output_file), ".before.png"), units="mm", res=1200,  width=297, height=210, bg="transparent")
boxplot(data$het)
dev.off()


after = data[which(data$het<=m+n_sd*s & data$het>=m-n_sd*s),]
png(filename=paste0(tools::file_path_sans_ext(output_file), ".after.png"), units="mm", res=1200,  width=297, height=210, bg="transparent")
boxplot(after$het)
dev.off()


outliers = data[which(data$het>m+n_sd*s | data$het<m-n_sd*s), c("FID", "IID")]

write.table(outliers, file=output_file, quote=FALSE, col.names=FALSE, row.names=FALSE)