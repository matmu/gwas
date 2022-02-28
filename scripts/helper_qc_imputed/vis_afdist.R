library(ggplot2) 

cmd_args <- commandArgs(trailingOnly=TRUE)


input_file = cmd_args[1]
output_file = cmd_args[2]


data = read.table(input_file, header=FALSE)

data$frequency = data$V4/sum(data$V4)


p = ggplot(data, aes(x=V2, y=frequency)) + 
  geom_point() + 
  geom_line() +
  ylab("Frequency") +
  #xlab("Genotype Probability (assuming HWE)") +
  theme_bw() +
  theme(
    plot.background = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_rect(colour="black")
  ) + 
  scale_x_continuous("Genotype Probability", 
                     labels = as.character(data$V2), breaks = data$V2, limits=c(0,1), expand=c(0,0)) +
  scale_y_continuous("Frequency", limits=c(0,max(data$frequency)*1.1), expand=c(0,0))


ggsave(output_file, scale=0.6, plot=p, dpi=300, width=20, height=15, units="cm")

