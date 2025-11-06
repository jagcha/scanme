############################# Initialization ###################################
rm(list = ls())

# Packages:
require(lubridate) 

############################ Read samplefll48mn ################################
fdf <- read.csv('fdf.csv')

############################# Sliding window function ##########################
scanme <- function(data, w1_width = 16 , w2_width = 48, w3_width = 252, slide = 2, ath = 2, rth = .5) {
  # Make sure DateTime is a POSIXct object.
  data$DateTime = as.POSIXct(data$DateTime, format="%Y-%m-%d %H:%M", tz = "GMT")
  # Initialize columns:
  data$w1am <- data$w1rm <- data$w3am <- data$w3as <- data$w3rm <- data$w3rs <- data$n1 <- data$n3 <- NA # Set empty columns.
  data$Flag <- 0 # By default any event is flagged.
  idx <- 1 # Used for indexation.
  nlim <- nrow(data) # Used for identify uper bound of iteration.
  while (idx <= nlim) {
    # Get upper bound of w1:
    w1ub <- data$DateTime[idx]
    # Set lower & upper bounds of window 1, 2, and 3
    w2ub <- w1lb <- w1ub - w1_width*60^2
    w3ub <- w2lb <- w2ub - w2_width*60^2
    w3lb <- w3ub - w3_width*60^2
    # Extract spanned information (w1)
    v1a <- data$Activity[data$DateTime <= w1ub & data$DateTime > w1lb]
    v1r <- data$Rumination[data$DateTime <= w1ub & data$DateTime > w1lb]
    n1 <- length(v1a)
    # Extract spanned information (w3)
    v3a <- data$Activity[data$DateTime <= w3ub & data$DateTime > w3lb]
    v3r <- data$Rumination[data$DateTime <= w3ub & data$DateTime > w3lb]
    trk <- data$Flag[data$DateTime <= w3ub & data$DateTime > w3lb] == 0 # Logical vector. I use this vector to exclude data corresponding to already flagged behavioral changes.
    n3 <- sum(trk)
    # Check if you have useful information.
    if (n1 == 0 | n3 <= 1) {
      idx <- idx + 1
      next
    }
    # Estimation of summary statistics at a given time
    w1am <- mean(v1a)
    w1rm <- mean(v1r)
    w3am <- mean(v3a[trk])
    w3as <- sd(v3a[trk])
    w3rm <- mean(v3r[trk])
    w3rs <- sd(v3r[trk])
    # Define conditions:
    l1 <- w1am >= w3am + ath*w3as # Check outstanding increase in activity.
    l2 <- w1rm <= w3rm - rth*w3rs # Check dicrease in rumination.
    # Flag status:
    flag <- sum(l1 & l2)
    # Index information:
    data$w1am[idx] <- w1am
    data$w1rm[idx] <- w1rm
    data$w3am[idx] <- w3am
    data$w3as[idx] <- w3as
    data$w3rm[idx] <- w3rm
    data$w3rs[idx] <- w3rs
    data$n1[idx] <- n1
    data$n3[idx] <- n3
    data$Flag[idx] <- flag
    # Update idx.
    idx <- idx + 1
  }
  return(data)
}

############################ Execute sliding window ############################
fdf <- scanme(fdf)

################################ Show Activity #################################
ath <- 2 # Threshold for activity.
layout(matrix(c(1,2), nrow = 2))
red.act <- (fdf$Activity- min(fdf$Activity))/(max(fdf$Activity) - min(fdf$Activity))
## Plotting Activity Raw Data:
par(mar=c(0,5,2,0)+.1, mgp = c(3,1,0))
plot(fdf$Activity ~ fdf$DateTime,
     col=rgb(red.act, 0.5, 0.25, 0.5), cex = .85, pch = 19,
     main = 'Activity data: raw, smoothed and threshold', 
     xlab = "", 
     xaxt = "n",
     ylab = "Activity",
     cex.lab = 1,
     cex.axis = 1)
# Remove NAs:
sub_fdf = fdf[!is.na(fdf$w1am), ] # We only take this rows without NAs.
# red.Ind: range from 0 to 1.
red.w1am = (sub_fdf$w1am - min(sub_fdf$w1am))/(max(sub_fdf$w1am) - min(sub_fdf$w1am))
## Plotting w1am
par(mar=c(2,5,0,0)+.1, mgp = c(2,0.4,0))
plot(sub_fdf$w1am ~ sub_fdf$DateTime,
     col=rgb(red.w1am, 0.2, 0.25, 0.5), cex = .85, pch = 19,
     main = NULL, 
     xlab = "", 
     xaxt = "n",
     xlim = c(min(fdf$DateTime), max(fdf$DateTime)), 
     ylim = c(min(sub_fdf$w1am), max(sub_fdf$w1am)), 
     ylab = "Smoothed Activity",
     cex.lab = 1,
     cex.axis = 1)
mtext("Date Time", side = 1, line = 0.75)
par(new=TRUE)
plot((sub_fdf$w3am + ath*sub_fdf$w3as) ~ sub_fdf$DateTime,
     main = NULL, 
     xlab = "", 
     xaxt = "n",
     xlim = c(min(fdf$DateTime), max(fdf$DateTime)), 
     ylim = c(min(sub_fdf$w1am), max(sub_fdf$w1am)), 
     ylab = "",
     pch = 19,
     cex = .5)

############################## Show Rumination #################################
rth <- .5 # rumination sd threshold.
layout(matrix(c(1,2), nrow = 2))
red.rum <- (fdf$Rumination- min(fdf$Rumination))/(max(fdf$Rumination) - min(fdf$Rumination))
## Plotting Rumination Raw Data:
par(mar=c(0,5,2,0)+.1, mgp = c(3,1,0))
plot(fdf$Rumination ~ fdf$DateTime,
     col=rgb(red.rum, 0.5, 0.25, 0.5), cex = .85, pch = 19,
     main = 'Rumination data: raw, smoothed and threshold', 
     xlab = "", 
     xaxt = "n",
     ylab = "Rumination",
     cex.lab = 1,
     cex.axis = 1)
# Remove NAs:
sub_fdf = fdf[!is.na(fdf$w1rm), ] # We only take this rows without NAs.
# red.Ind: range from 0 to 1.
red.w1rm = (sub_fdf$w1rm - min(sub_fdf$w1rm))/(max(sub_fdf$w1rm) - min(sub_fdf$w1rm))
## Plotting w1rm
par(mar=c(2,5,0,0)+.1, mgp = c(2,0.4,0))
plot(sub_fdf$w1rm ~ sub_fdf$DateTime,
     col=rgb(red.w1rm, 0.2, 0.25, 0.5), cex = .85, pch = 19,
     main = NULL, 
     xlab = "", 
     xaxt = "n",
     xlim = c(min(fdf$DateTime), max(fdf$DateTime)), 
     ylim = c(min(sub_fdf$w1rm), max(sub_fdf$w1rm)), 
     ylab = "Smoothed Rumination",
     cex.lab = 1,
     cex.axis = 1)
mtext("Date Time", side = 1, line = 0.75)
par(new=TRUE)
plot((sub_fdf$w3rm - rth*sub_fdf$w3rs) ~ sub_fdf$DateTime,
     # col=rgb(red.w1rm, 0.2, 0.25, 0.5), cex = .85, pch = 19,
     main = NULL, 
     xlab = "", 
     xaxt = "n",
     xlim = c(min(fdf$DateTime), max(fdf$DateTime)), 
     ylim = c(min(sub_fdf$w1rm), max(sub_fdf$w1rm)), 
     ylab = "",
     pch = 19,
     cex = .5)

################################ Visualization #################################
layout(matrix(c(1,1,1,2,2,2,3,3,3,4,4,4,5), nrow = 13))
## Plotting Activity Raw Data:
red.act <- (fdf$Activity- min(fdf$Activity))/(max(fdf$Activity) - min(fdf$Activity))
par(mar=c(0,5,2,0)+.1, mgp = c(3,1,0))
plot(fdf$Activity ~ fdf$DateTime,
     col=rgb(red.act, 0.5, 0.25, 0.5), cex = 1, pch = 19,
     main = 'Activity and Rumination data: raw, smoothed and thresholds', 
     xlab = "", 
     xaxt = "n",
     ylab = "Activity",
     cex.lab = 1,
     cex.axis = 1)
# Remove NAs:
sub_fdf = fdf[!is.na(fdf$w1am), ] # We only take this rows without NAs.
# red.Ind: range from 0 to 1.
red.w1am = (sub_fdf$w1am - min(sub_fdf$w1am))/(max(sub_fdf$w1am) - min(sub_fdf$w1am))
## Plotting w1am
par(mar=c(0,5,0,0)+.1)
plot(sub_fdf$w1am ~ sub_fdf$DateTime,
     col=rgb(red.w1am, 0.2, 0.25, 0.5), cex = 1, pch = 19,
     main = NULL, 
     xlab = "", 
     xaxt = "n",
     xlim = c(min(fdf$DateTime), max(fdf$DateTime)), 
     ylim = c(min(sub_fdf$w1am), max(sub_fdf$w1am)), 
     ylab = "Smoothed Activity",
     cex.lab = 1,
     cex.axis = 1)
par(new=TRUE)
plot((sub_fdf$w3am + ath*sub_fdf$w3as) ~ sub_fdf$DateTime,
     main = NULL, 
     xlab = "", 
     xaxt = "n",
     xlim = c(min(fdf$DateTime), max(fdf$DateTime)), 
     ylim = c(min(sub_fdf$w1am), max(sub_fdf$w1am)), 
     ylab = "",
     pch = 19,
     cex = .5)
## Plotting Rumination Raw Data:
red.rum <- (fdf$Rumination- min(fdf$Rumination))/(max(fdf$Rumination) - min(fdf$Rumination))
par(mar=c(0,5,0,0)+.1, mgp = c(3,1,0))
plot(fdf$Rumination ~ fdf$DateTime,
     col=rgb(red.rum, 0.5, 0.25, 0.5), cex = 1, pch = 19,
     main = NULL, 
     xlab = "", 
     xaxt = "n",
     ylab = "Rumination",
     cex.lab = 1,
     cex.axis = 1)
# Remove NAs:
sub_fdf = fdf[!is.na(fdf$w1rm), ] # We only take this rows without NAs.
# red.Ind: range from 0 to 1.
red.w1rm = (sub_fdf$w1rm - min(sub_fdf$w1rm))/(max(sub_fdf$w1rm) - min(sub_fdf$w1rm))
## Plotting w1rm
par(mar=c(0,5,0,0)+.1)
plot(sub_fdf$w1rm ~ sub_fdf$DateTime,
     col=rgb(red.w1rm, 0.2, 0.25, 0.5), cex = 1, pch = 19,
     main = NULL, 
     xlab = "", 
     xaxt = "n",
     xlim = c(min(fdf$DateTime), max(fdf$DateTime)), 
     ylim = c(min(sub_fdf$w1rm), max(sub_fdf$w1rm)), 
     ylab = "Smoothed Rumination",
     cex.lab = 1,
     cex.axis = 1)
par(new=TRUE)
plot((sub_fdf$w3rm - rth*sub_fdf$w3rs) ~ sub_fdf$DateTime,
     main = NULL, 
     xlab = "", 
     xaxt = "n",
     xlim = c(min(fdf$DateTime), max(fdf$DateTime)), 
     ylim = c(min(sub_fdf$w1rm), max(sub_fdf$w1rm)), 
     ylab = "",
     pch = 19,
     cex = .5)
# Flagged behavior
red.Flag = (fdf$Flag - min(fdf$Flag))/(max(fdf$Flag) - min(fdf$Flag))
par(mar=c(2,5,0,0)+.1)
plot(fdf$Flag ~ fdf$DateTime,
     col=rgb(red.Flag, 0, 0.25, 0.5), cex = 1, pch = 19,
     main = NULL, 
     xlab = '',
     xaxt = "n",
     ylab = "Flag",
     xlim = c(min(fdf$DateTime), max(fdf$DateTime)), 
     cex.lab = 1,
     cex.axis = 1)
mtext("Date Time", side = 1, line = 0.5)

