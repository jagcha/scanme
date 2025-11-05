# scan-change

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

The **past activity threshold** for `ID 470` at iteration `3240` is defined as:  

$$
T_{a,470,3240} = a_{3_1, 470, 3240} + u_a \times a_{3_2, 470, 3240} = 41.9 + 2 \times 10.5 = 62.9
$$  

Similarly, for **rumination**:  

- $w_1$ returns an **rumination mean** of `35.3`. Define this value as $r_{1, 470, 3240}$. This value is reffered as smoothed rumination.  
- $w_3$ returns an **rumination mean** of `48`. Define this value as $r_{3_1, 470, 3240}$.
- $w_3$ return an **rumination sample standard deviation** of `14.7`. Define this value as $r_{3_2, 470, 3240}$.


The **past rumination threshold** is defined as:  

$$
T_{r,470,3240} = r_{3_1, 470, 3240} - u_r \times r_{3_2, 470, 3240} = 48 - 0.5 \times 14.7 = 40.65 \approx 40.6
$$

For a given iteration $t$ and `ID=470`, a **change in behavior** is flagged when:  

$$
a_{1, 470, t} >= T_{a,470,t} \quad \text{and} \quad r_{1, 470, t} <= T_{2,470,t}
$$

If the condition holds, a variable $\hat{F}_{470,t} = 1$ is defined. Otherwise, $\hat{F}_{470,t} = 0$.  

Once the status of $\hat{F}_{470,t}$ is defined, we proceed to repeat the process for $t+1$. This hapens iterativelly, from the first to the last behavioral record of animal 470.

After scanning the entire chronological sequence with the sliding window, a vector $\widehat{\mathbf{F}}_{470}$ is constructed. It is mostly composed of zeros, with occasional sequences of ones corresponding to **outstanding increases in activity and decreases in rumination**.  

These segments of ones can be **zoomed-in** to extract further information and characterize the behavioral changes at that moment.

What are the optimal values of $u_a$ and $u_r$? This is an optimization problem.

Suppose that we have a TRUE vector $\mathbf{F}_{470}$. Then we can try to find $u_a$ and $u_r$ such that the distance between $\widehat{\mathbf{F}}_{470}$ and $\mathbf{F}_{470}$ is minimized. 

Now as PhD I know many techniques that could serve that propose. However, at the time where I developed this script I was a MS and I didn't knew most of them. At that time, I solved this optimization problem with an iterative and exaustive method. 

For a subset of animals, I had the vector $\mathbf{F}_{.}$ obtained from a **gold standard software** defining `Heat Indices`.  

I then tested an alternative pair of units $(u_{a,1}, u_{r,1})$, which produced an estimated vector $\widehat{\mathbf{F}}_{.,1,1}$. The distance between $\mathbf{F}_{.}$ and $\widehat{\mathbf{F}}_{.,1,1}$ was evaluated using the **F1 score**, denoted $F1_{1,1}$.  

Next, I changed the rumination unit to $u_{r,2}$ while keeping $u_{a,1}$ fixed, obtaining $\widehat{\mathbf{F}}_{.,1,2}$ and the corresponding F1 score $F1_{1,2}$.  

Using this logic, I defined a **domain of units for activity** and a **domain of units for rumination**, then explored all combinations iteratively. For each pair $(u_{a,i}, u_{r,j})$, I computed the corresponding F1 score $F1_{i,j}$.  

Finally, I selected the units $(u_{a,i*}, u_{r,j*})$ that yielded a **local maximum** of the F1 score.  

Currently, I believe there are more **elegant and efficient methods** to solve this optimization problem.



