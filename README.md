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

The image below is used to conceptually explain how a rolling wondow works. 
![Alt text](path/to/image.png)









