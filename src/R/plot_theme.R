theme_map <- function(...) {
  theme_minimal() +
    theme(
      text = element_text(family = "Ubuntu Regular", color = "#22211d"),
      axis.line = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      # panel.grid.minor = element_line(color = "#ebebe5", size = 0.2),
      panel.grid.major = element_line(color = "transparent", size = 0.2),
      panel.grid.minor = element_blank(),
      plot.background = element_blank(), 
      panel.background = element_blank(), 
      legend.background = element_blank(), 
      panel.border = element_blank(),
      ...
    )
}
