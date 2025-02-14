# Install missing packages
if (!require("isotree")) install.packages("isotree", dependencies = TRUE)
if (!require("lpSolve")) install.packages("lpSolve", dependencies = TRUE)

# Load required libraries
library(isotree)
library(lpSolve)

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
iso_forest <- isolation.forest(data[ ,1:3], ntrees = 100, sample_size = 256)

# Predict anomaly scores
data$score <- predict(iso_forest, newdata = data[ ,1:3], type = "score")

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

# Extract defense strategy
defense_strategy <- optimal_defense$solution

# Compute Expected Impact
impact <- sum(defense_strategy * c(-10, -5))

# Display results
cat("Anomaly Detection Rate:", mean(data$anomaly), "\n")
cat("Optimal Defense Strategy:", defense_strategy, "\n")
cat("Expected Defense Impact:", impact, "\n")
