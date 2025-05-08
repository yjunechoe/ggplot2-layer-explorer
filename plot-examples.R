plot1 <- r"(
# Plot data as points and fit a linear model
p <- ggplot(mtcars, aes(x = mpg, y = disp)) +
  geom_smooth(formula = y ~ x, method = "lm") +
  geom_point()
)"

plot2 <- r"(
# Label values on top of bars
p <- ggplot(mpg, aes(class)) +
  geom_bar() +
  geom_text(
    aes(
      y = after_stat(count + 2),
      label = after_stat(count)
    ),
    stat = "count"
  )
)"

plot3 <- r"(
# Use scaled color-aesthetic values for the fill-aesthetic
p <- ggplot(mpg, aes(cty, colour = factor(cyl))) +
  geom_density(
    aes(fill = after_scale(alpha(colour, 0.3)))
  )
)"

plot4 <- r"(
# Label a boxplot variable, using complex mapping with `stage()`
p <- ggplot(mpg, aes(x = drv, y = displ)) +
  geom_boxplot(aes(fill = drv)) +
  geom_label(
    aes(
      y = stage(start = displ, after_stat = middle),
      label = after_stat(middle)
    ),
    stat = "boxplot"
  )
)"

plot5 <- r"(
# Apply a custom function for the Stat computation
# (See also the new `stat_manual()` function in dev {ggplot2})
p <- ggplot(mpg, aes(displ, class)) +
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

plot6 <- r"(
# Fit a linear model in log-space, plot model fit in the original data-space
p <- ggplot(mtcars, aes(x = mpg, y = disp)) +
  geom_smooth(method = "lm") +
  geom_point() +
  scale_x_continuous(transform = "log") +
  scale_y_continuous(transform = "log") +
  coord_trans(x = "exp", y = "exp")
)"

plots <- rlang::dots_list(plot1, plot2, plot3, plot4, plot5, .named = TRUE)
plots <- lapply(plots, \(x) gsub(x = x, "^\\s*", ""))
