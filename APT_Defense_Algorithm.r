# Load required libraries
if (!require("isotree")) install.packages("isotree", dependencies = TRUE)
if (!require("lpSolve")) install.packages("lpSolve", dependencies = TRUE)
if (!require("ggplot2")) install.packages("ggplot2", dependencies = TRUE)

library(isotree)
library(lpSolve)
library(ggplot2)

# Simulating network traffic data
set.seed(42)
n_samples <- 1000

normal_traffic <- data.frame(
  feature1 = rnorm(n_samples, mean = 50, sd = 10),
  feature2 = rnorm(n_samples, mean = 50, sd = 10),
  feature3 = rnorm(n_samples, mean = 50, sd = 10),
  label = 0
)

attack_traffic <- data.frame(
  feature1 = rnorm(n_samples / 10, mean = 100, sd = 30),
  feature2 = rnorm(n_samples / 10, mean = 100, sd = 30),
  feature3 = rnorm(n_samples / 10, mean = 100, sd = 30),
  label = 1
)

data <- rbind(normal_traffic, attack_traffic)

# Applying Isolation Forest for Anomaly Detection
iso_forest <- isolation.forest(data[, 1:3], ntrees = 100, sample_size = 256)

# Predict anomaly scores
data$score <- predict(iso_forest, newdata = data[, 1:3], type = "score")

# Flag anomalies based on threshold
threshold <- quantile(data$score, 0.95)
data$anomaly <- ifelse(data$score >= threshold, 1, 0)

# Game Theory: Stackelberg Optimization
payoff_matrix <- matrix(c(0, -10, 5, -5), nrow = 2, byrow = TRUE)
costs <- c(-1, -1)  # Objective function (minimization)
constraints <- matrix(c(1, 1), nrow = 1)
bounds <- c(1)

# Solve the Stackelberg game using linear programming
optimal_defense <- lp(direction = "min",
                      objective.in = costs,
                      const.mat = constraints,
                      const.dir = "=",
                      const.rhs = bounds,
                      all.int = FALSE)

# Check if optimization was successful
if (!is.null(optimal_defense$solution)) {
  defense_strategy <- optimal_defense$solution
} else {
  defense_strategy <- c(NA, NA)  # Placeholder in case of failure
  cat("Warning: Linear programming did not return a valid solution.\n")
}

# Compute Expected Impact
if (!is.na(defense_strategy[1])) {
  defense_impact <- sum(defense_strategy * c(-10, -5))
} else {
  defense_impact <- NA
  cat("Warning: Defense impact could not be computed due to missing strategy.\n")
}

# Display results
cat("Anomaly Detection Rate:", mean(data$anomaly), "\n")
cat("Optimal Defense Strategy:", defense_strategy, "\n")
cat("Expected Defense Impact:", defense_impact, "\n")

# Plot Anomaly Detection Results
ggplot(data, aes(x = score, fill = as.factor(anomaly))) +
  geom_histogram(bins = 30, alpha = 0.7, position = "identity") +
  scale_fill_manual(values = c("blue", "red"), labels = c("Normal", "Anomalous")) +
  labs(title = "Anomaly Score Distribution", x = "Anomaly Score", y = "Count", fill = "Status") +
  theme_minimal()
