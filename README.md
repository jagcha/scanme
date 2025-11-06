# scanme

Show how I implement a sliding window to detect changes in activity and rumination.

## Background

Sliding-window methods are widely used in streaming analytics, signal processing, and real-time monitoring systems. 

The idea is to evaluate data in small segments (windows) that move step-by-step across time. 

This allows detection of changes in patterns without loosing the chronological connectivity of the data. 

In each roll (iteration), functions are triggered, and transformations are applied. 

## Motivation

In a world of increasing connectivity and data volume, storing all information for later batch processing is often impractical. By the time batch analysis is complete, decisions may already be too late. 

Streaming analytics addresses this challenge by processing data in real time using windowing techniques. When data is abundant, you don’t need to store everything, you can extract only the insights necessary for immediate decisions, keeping summaries or essential outcomes and discarding the raw data.

Processing live data with sliding windows is a powerful example of this approach. It transforms high-frequency records into actionable information, allowing more precise and timely management decisions.

Here, I will implement a sliding window technique using a fixed dataset. In the future, the same logic could be applied to streaming data to flag and predict actionable events in real time, while aggregating large amounts of data into a few essential traits for latter selection purposes. 

This makes sliding windows particularly promising for a future of high connectivity, automation, and real-time decision-making.

## Dataset

The dataset `fdf.csv` contains high-frequency activity and rumination records collected from `2021-04-08 18:00:00` to `2023-01-22 20:00:00`.

It includes the columns:  
- `ID` – animal identifier (only one ID is present in this example, `470`)  
- `DateTime` – timestamp of the record. Foramt is `YYYY-MM-DD hh:mm:ss` 
- `Rumination` – rumination measurements (derived from accelerometer data processed with undesclosed algorithms).
- `Activity` – activity measurements  (derived from accelerometer data processed with undesclosed algorithms).

The `DateTime` column stores hourly information from `00:00:00` to `22:00:00`, allowing up to 12 records per day.  

No missing values (`NA`) are allowed in any column. When gaps occur in high-frequency data, they are simply excluded from `fdf`. As a result, you may observe missing periods in activity or rumination data. This is normal when working with high-frequency measurements.

## Logic of Sliding Window.

Schematic representation of the sliding window technique for processing raw activity and rumination time-series data. (white theme recommedned).
![Alt text](SlidingWindowExample.png)

Schematic representation of the sliding window technique applied to activity and rumination time-series data of animal `ID 470`, focusing on iterations `3239` and `3240`.  

The window spanning the **earliest set of raw records** is defined as $w_1$. In this example, $w_1$ has a width of **6 hours**.  

The window spanning **older records** is defined as $w_3$, which has a width of **14 hours**.  

Between $w_1$ and $w_3$, a segment $w_2$ is inserted to allow contrast between **present** and **past** information. Here, $w_2$ has a width of **6 hours**.  

The windows $w_1$, $w_2$, and $w_3$ are rolled together with a **sliding parameter** of **2 hours**. When the sliding parameter is smaller than the window width, this is referred to as an **overlapping rolling window**.  

At each 2-hour increment, computations are triggered using the data inside $w_1$ and $w_3$. For `ID 470` at iteration `3240`:  

- $w_1$ returns an **activity mean** of `38.3`. Define this value as $a_{1, 470, 3240}$. This value is reffered as smoothed activity.  
- $w_3$ returns an **activity mean** of `41.9`. Define this value as $a_{3_1, 470, 3240}$.
- $w_3$ return an **activity sample standard deviation** of `10.5`. Define this value as $a_{3_2, 470, 3240}$.

The **past activity threshold** for `ID 470` at iteration `3240` is defined as (assume $u_a = 2$):  

$$
T_{a,470,3240} = a_{3_1, 470, 3240} + u_a \times a_{3_2, 470, 3240} = 41.9 + 2 \times 10.5 = 62.9
$$  

Similarly, for **rumination**:  

- $w_1$ returns an **rumination mean** of `35.3`. Define this value as $r_{1, 470, 3240}$. This value is reffered as smoothed rumination.  
- $w_3$ returns an **rumination mean** of `48`. Define this value as $r_{3_1, 470, 3240}$.
- $w_3$ return an **rumination sample standard deviation** of `14.7`. Define this value as $r_{3_2, 470, 3240}$.


The **past rumination threshold** is defined as (assume $u_r = 0.5$):  

$$
T_{r,470,3240} = r_{3_1, 470, 3240} - u_r \times r_{3_2, 470, 3240} = 48 - 0.5 \times 14.7 = 40.6
$$

For a given iteration $t$ and `ID=470`, a **change in behavior** is flagged when:  

$$
a_{1, 470, t} >= T_{a,470,t} \quad \text{and} \quad r_{1, 470, t} <= T_{2,470,t}
$$


If the condition above evaluates as `True`, the variable below is defined.

$\hat{F}_{470,t} = 1$


If the condition evaluates as `False`, the variable below is defined.

$\hat{F}_{470,t} = 0$


Once the status of $\hat{F}_{470,t}$ is defined, we proceed to repeat the process for $t+1$. This hapens iterativelly, from the first to the last behavioral record of animal 470.

After scanning the entire chronological sequensce with the sliding window, a vector $\widehat{\mathbf{F}}_{470}$ is constructed. It is mostly composed of zeros, with occasional sequences of ones corresponding to **outstanding increases in activity and decreases in rumination**.  

These segments of ones can be zoomed-in to extract further information and characterize the behavioral changes at that moment.

**Estimating the units $u_a$ and $u_r$**

The objective is to find the values of $u_a$ and $u_r$ that best align the estimated flag vector $\widehat{\mathbf{F}}$ with the reference vector $\mathbf{F}$.

At the time this procedure was developed, I used a simple, exhaustive grid search over candidate values of $u_a$ and $u_r$. For a subset of animals I had the reference vector $\mathbf{F}$ from a gold-standard software that defines Heat Indices.

I first tested an initial pair $(u_{a,1}, u_{r,1})$, ran the sliding-window algorithm, and obtained the estimated vector $\mathbf{\widehat{F_{1,1}}}$. The agreement between $\mathbf{F}$ and $\mathbf{\widehat{F_{1,1}}}$ was measured with the F1 score, denoted $F1_{1,1}$.

Next, I varied the rumination unit to $u_{r,2}$ while keeping $u_{a,1}$ fixed, producing $\mathbf{\widehat{F_{1,2}}}$ and the corresponding score $F1_{1,2}$. 

Repeating this across a predefined domain of activity units and a domain of rumination units, I evaluated every pair $(u_{a,i}, u_{r,j})$ and recorded the F1 score $F1_{i,j}$ for each combination.

The final choice $(u_{a,i*}, u_{r,j*})$ was the pair that produced a local maximum of the F1 surface over the explored grid.

This grid-search approach is simple and reproducible. However, more efficient optimization algorithms (for example, Bayesian optimization, coordinate search, or gradient-free methods) could replace the exhaustive search to reduce computation while achieving similar or better results.

## Visualization of trend detection using overlapping rolling wodnows

<video src=https://github.com/user-attachments/assets/8adc43b0-d87a-4d91-91b2-3975d3d4ac34 controls width="600">
  Your browser does not support the video tag.
</video>

## Zoom in in flagged event

Once the exact moment is flagged, you can extract the charactewristic of this event. For the propose of my study, I had to extractthe duration, the average increase in activity above the threshold, and the average decrease in rumination below the threshold. The giff below summarices goe from a detected event it is possible to extract magnitudes that confers information of such event.

![xtraction of information in behavioral change](Zoomin.gif)

## Implementation in base-R

The R script `scanme.R` contains the code for implementing an **overlapping rolling window** on activity and rumination data stored in `fdf.csv`.

> Note: `fdf.csv` is a small snippet randomly selected from my dataset. The data is **not filtered or curated**, so you may observe gaps or missing periods in the time series. This is common in high-frequency data, and I intentionally leave it as-is to reflect realistic, noisy measurements rather than an idealized abstraction.

The main function in the script is `scanme()`. It iterates windows across time-series data according to the logic described in [Logic of Sliding Window](#logic-of-sliding-window).

### Default Parameters

By default, `scanme()` uses the following parameters:

- `w1_width = 16` — width of window 1 in hours  
- `w2_width = 48` — width of window 2 in hours  
- `w3_width = 252` — width of window 3 in hours  
- `slide = 2` — sliding step in hours  
- `ath = 2` — units of activity used to define the activity threshold  
- `rth = 0.5` — units of rumination used to define the rumination threshold  

### Input Requirements

The function expects a **data frame** passed to the argument `data`. For proper functioning, the data must include a **DateTime column of class `POSIXct` or `POSIXt`**. The script is tailored to the structure of `fdf.csv`, but the logic can be adapted to other similar datasets.

### Output

The script generates plots of **raw and smoothed activity and rumination**, along with the **Flagged events** indicating behavioral changes.

## Limitations and Scope

The program `scanme.R` was implemented in base R to provide a clear and fundamental example of sliding-window analysis. The core function, `scanme()`, is computationally intensive and can be slow on large datasets. Performance could be improved through code optimization or alternative implementations.

This repository offers a reproducible, real-world example of how sliding windows can be used to detect time-dependent events in high-frequency behavioral data.

For applications involving a large number of animals, and in case you wish to use `scanme()`, I would recommend leveraging parallel computing.


## References

Akidau, T., Balikov, A., Bekiroğlu, K., Chernyak, S., Haberman, J., Lax, R., McVeety, S., Mills, D., Nordstrom, P., & Whittle, S. (2013). *MillWheel: Fault-Tolerant Stream Processing at Internet Scale*.

Verwiebe, J., Grulich, P. M., Traub, J., & Markl, V. (2023). *Survey of window types for aggregation in stream processing systems*.

Singh, T., Kalra, R., Mishra, S., Satakshi, & Kumar, M. (2022). *An efficient real‑time stock prediction exploiting incremental learning and deep learning*.



