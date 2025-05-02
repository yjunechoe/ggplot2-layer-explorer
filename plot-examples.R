plot1 <- r"(ggplot(mtcars) +
  geom_point(aes(x = mpg, y = disp))
)"

plot2 <- r"(ggplot(mpg, aes(class)) +
  geom_bar() +
  geom_text(
    aes(
      y = after_stat(count + 2),
      label = after_stat(count)
    ),
    stat = "count"
  )
)"

plot3 <- r"(ggplot(mpg, aes(cty, colour = factor(cyl))) +
  geom_density(aes(fill = after_scale(alpha(colour, 0.3))))
)"

plot4 <- r"(ggplot(mpg, aes(x = drv, y = displ)) +
  geom_boxplot(aes(fill = drv)) +
  geom_label(
    aes(
      y = stage(start = displ, after_stat = middle),
      label = after_stat(middle)
    ),
    stat = "boxplot"
  )
)"

plot5 <- r"(ggplot(mpg, aes(displ, class)) +
  geom_violin() +
  stat_summary(
    aes(
      x = stage(displ, after_stat = 0),
      label = after_stat(paste(mean, "±", sd))
    ),
    fun.data = \(x) round(data.frame(mean = mean(x), sd = sd(x)), 2),
    geom = "label",
    hjust = 0
  )
)"

plots <- rlang::dots_list(plot1, plot2, plot3, plot4, plot5, .named = TRUE)
plots <- lapply(plots, \(x) paste("p <-", x))
