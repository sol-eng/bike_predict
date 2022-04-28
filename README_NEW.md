## Packge managment

All packages are managed using `renv`. The follow source was used:

```r
options(
  repos = c(
    CRAN = "https://colorado.rstudio.com/rspm/all/__linux__/bionic/2022-04-22+Y3JhbiwxMDo1MzA5LDk6ODEyMzg3NTtFRkFCRjI2RA", 
    RSPM = "https://colorado.rstudio.com/rspm/all/__linux__/bionic/2022-04-22+Y3JhbiwxMDo1MzA5LDk6ODEyMzg3NTtFRkFCRjI2RA"
  )
)
```

## Individual Content

| Content              | Content Description                                                 | Connect Deployment                                                                                                                                                               | Code                                              | Pin | Refresh Frequency |
|----------------------|---------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------|-----|-------------------|
| 01 Raw Data Ingest   | Writes data from API calls into `bike_raw_data` table in postgres.  | [Collaborator](https://colorado.rstudio.com/rsc/connect/#/apps/6c96c05d-a77a-4a4e-baf0-8e7d9f69fc20) \| [Public](https://colorado.rstudio.com/rsc/r-bike-predict-01-intake-raw/) | [content/01-intake-raw/](./content/01-intake-raw) | N/A | Every 20 minutes  |
| 02 Clean Raw         | Cleans `bike_raw_data` for modeling, writes into `bike_model_data`. | [Collaborator](https://colorado.rstudio.com/rsc/connect/#/apps/c2198b1e-a3dc-44ea-94c2-630ea9009d60) \| [Public](https://colorado.rstudio.com/rsc/r-bike-predict-02-clean-raw/)  | [content/02-clean-raw](./content/02-clean-raw)    |     |                   |
| 03 Write to Pin      |                                                                     |                                                                                                                                                                                  |                                                   |     |                   |
| 04 Build Model       |                                                                     |                                                                                                                                                                                  |                                                   |     |                   |
| 05 Model Metrics     |                                                                     |                                                                                                                                                                                  |                                                   |     |                   |
| 06 Model Performance |                                                                     |                                                                                                                                                                                  |                                                   |     |                   |
| 07 Model API         |                                                                     |                                                                                                                                                                                  |                                                   |     |                   |
| 08 Client App        |                                                                     |                                                                                                                                                                                  |                                                   |     |                   |
| 09 R Package         |                                                                     |                                                                                                                                                                                  |                                                   |     |                   |
