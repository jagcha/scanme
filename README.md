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

- $w_1$ returns an **activity mean** of `38.3` (smoothed activity).  
- $w_3$ returns an **activity mean** of `41.9` and a **sample standard deviation** of `10.5`.  

The **past activity threshold** for `ID 470` at iteration `3240` is defined as:  

\[
T_{1,470,3240} = \text{mean}(w_3) + 2 \cdot \text{SD}(w_3) = 41.9 + 2 \cdot 10.5 = 62.9
\]  

Similarly, for **rumination**:  

- $w_1$ returns a **rumination mean** of `35.3`.  
- $w_3$ returns a **rumination mean** of `48` and a **sample standard deviation** of `14.7`.  

The **past rumination threshold** is defined as:  

$$
T_{2,470,3240} = \text{mean}(w_3) - 0.5 \cdot \text{SD}(w_3) = 48 - 0.5 \cdot 14.7 = 40.65 \approx 40.6
$$

For a given iteration $t$, a **change in behavior** is flagged when:  

$$
\text{smoothed activity from } w_1 > T_{1,470,t} \quad \text{and} \quad \text{smoothed rumination from } w_1 < T_{2,470,t}
$$

If the condition holds, a variable $F_{470,t} = 1$ is defined. Otherwise, $F_{470,t} = 0$.  

After scanning the entire chronological sequence with the sliding window, a vector $\mathbf{F}_{470}$ is constructed. It is mostly composed of zeros, with occasional sequences of ones corresponding to **outstanding increases in activity and decreases in rumination**.  

These segments of ones can be **zoomed-in** to extract further information and characterize the behavioral changes at that moment.


