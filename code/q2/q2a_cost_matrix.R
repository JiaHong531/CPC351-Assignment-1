# CPC351 Assignment 01 - Question 2(a)
# Build the Rainy Morning travel-time cost matrix.

# Delivery point coordinates, in the order P1 to P10.
point_names <- paste("P", 1:10, sep = "")
points <- data.frame(
  x = c(60, 180, 80, 140, 20, 100, 200, 140, 40, 100),
  y = c(200, 200, 180, 180, 160, 160, 160, 140, 120, 120)
)

# Read the clearly labeled synthetic development data.
logs <- read.csv("data/synthetic/q2/q2a_synthetic_travel_logs.csv")

# Keep only Rainy Morning records. Change missing weather/time conditions to FALSE.
rainy_morning_rows <- logs$Weather == "Rainy" & logs$Time_of_Day == "Morning"
rainy_morning_rows[is.na(rainy_morning_rows)] <- FALSE
rainy_logs <- logs[rainy_morning_rows, ]

# Start an empty 10 by 10 matrix. Rows are origins; columns are destinations.
cost_matrix <- matrix(NA, nrow = 10, ncol = 10)
used_record_count <- 0
observed_route_count <- 0
outside_point_count <- 0

# Count records that do not use one of the ten assignment points.
for (record in 1:nrow(rainy_logs)) {
  origin_found <- FALSE
  destination_found <- FALSE

  for (point in 1:10) {
    if (!is.na(rainy_logs$Origin_X[record]) &
        !is.na(rainy_logs$Origin_Y[record]) &
        rainy_logs$Origin_X[record] == points$x[point] &
        rainy_logs$Origin_Y[record] == points$y[point]) {
      origin_found <- TRUE
    }

    if (!is.na(rainy_logs$Dest_X[record]) &
        !is.na(rainy_logs$Dest_Y[record]) &
        rainy_logs$Dest_X[record] == points$x[point] &
        rainy_logs$Dest_Y[record] == points$y[point]) {
      destination_found <- TRUE
    }
  }

  if (origin_found == FALSE | destination_found == FALSE) {
    outside_point_count <- outside_point_count + 1
  }
}

# Calculate the 75th percentile for every directed origin-destination route.
for (origin in 1:10) {
  for (destination in 1:10) {
    if (origin != destination) {
      route_rows <- rainy_logs$Origin_X == points$x[origin] &
        rainy_logs$Origin_Y == points$y[origin] &
        rainy_logs$Dest_X == points$x[destination] &
        rainy_logs$Dest_Y == points$y[destination]
      route_rows[is.na(route_rows)] <- FALSE

      route_times <- rainy_logs$Travel_Time_Minutes[route_rows]
      valid_times <- route_times[!is.na(route_times) & route_times >= 0]
      used_record_count <- used_record_count + length(valid_times)

      if (length(valid_times) > 0) {
        cost_matrix[origin, destination] <- quantile(valid_times, 0.75)
        observed_route_count <- observed_route_count + 1
      }
    } else {
      # Travelling from a point to itself has zero cost.
      cost_matrix[origin, destination] <- 0
    }
  }
}

# Give routes with no valid history a large cost.
maximum_observed_cost <- max(cost_matrix, na.rm = TRUE)
impassable_penalty <- maximum_observed_cost * 11 + 1
penalty_route_count <- 0

for (origin in 1:10) {
  for (destination in 1:10) {
    if (is.na(cost_matrix[origin, destination])) {
      cost_matrix[origin, destination] <- impassable_penalty
      penalty_route_count <- penalty_route_count + 1
    }
  }
}

# Print the cleaning results and matrix.
travel_times <- rainy_logs$Travel_Time_Minutes
print(paste("Rows in file:", nrow(logs)))
print(paste("Rainy Morning rows:", nrow(rainy_logs)))
print(paste("Missing travel times:", sum(is.na(travel_times))))
print(paste("Road-closure records (-1):", sum(travel_times == -1, na.rm = TRUE)))
print(paste("Other negative travel times:",
            sum(travel_times < 0 & travel_times != -1, na.rm = TRUE)))
print(paste("Rows outside assignment points:", outside_point_count))
print(paste("Valid travel records used:", used_record_count))
print(paste("Observed directed routes:", observed_route_count))
print(paste("Routes given the high penalty:", penalty_route_count))
print(paste("High penalty in minutes:", impassable_penalty))

print("Cost matrix: rows are origins, columns are destinations; order is P1 to P10")
print(cost_matrix)

# Save generated results under outputs/q2.
output_dir <- file.path("outputs", "q2")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Save a CSV table with origin names and P1-P10 destination columns.
cost_table <- data.frame(
  Origin = point_names,
  P1 = cost_matrix[, 1], P2 = cost_matrix[, 2],
  P3 = cost_matrix[, 3], P4 = cost_matrix[, 4],
  P5 = cost_matrix[, 5], P6 = cost_matrix[, 6],
  P7 = cost_matrix[, 7], P8 = cost_matrix[, 8],
  P9 = cost_matrix[, 9], P10 = cost_matrix[, 10]
)
write.table(cost_table, file.path(output_dir, "q2a_cost_matrix.csv"),
            sep = ",", row.names = FALSE)

# Plot the matrix values. Axis numbers 1 to 10 correspond to points P1 to P10.
png(file.path(output_dir, "q2a_cost_matrix_heatmap.png"))
observed_costs <- cost_matrix[cost_matrix != impassable_penalty]
highest_observed_cost <- max(observed_costs, na.rm = TRUE)
image(1:10, 1:10, cost_matrix, col = c("red", "orange", "yellow", "white"),
      zlim = c(0, highest_observed_cost),
      xlab = "Origin point (1 = P1 to 10 = P10)",
      ylab = "Destination point (1 = P1 to 10 = P10)",
      main = "Synthetic Rainy Morning: 75th-percentile travel time (minutes)")
title(sub = "P marks a route assigned the severe penalty")

for (origin in 1:10) {
  for (destination in 1:10) {
    if (cost_matrix[origin, destination] == impassable_penalty) {
      rect(origin - 0.5, destination - 0.5, origin + 0.5, destination + 0.5,
           col = "purple", border = NA)
      text(origin, destination, "P", col = "white", font = 2)
    } else {
      text(origin, destination, round(cost_matrix[origin, destination], 1))
    }
  }
}
dev.off()
