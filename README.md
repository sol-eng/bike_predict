This repository contains an example of using the [pins]() package and [RStudio Connect]() to create a predictive model and serve and visualize predictions from that model.

The entire scheme looks like this: 
![](./system_schematic.png)

1. The [bike data ingest](https://colorado.rstudio.com/rsc/bike_data_ingest/)(1) script (in `./ETL`) runs every 10 minutes on RStudio Connect as an RMarkdown document, pulling data from the Capital Bikeshare API and pinning [the raw dataset](https://colorado.rstudio.com/rsc/bike_raw_data/)(a) to RStudio Connect. It then cleans the data, and pins the [analysis dataset](https://colorado.rstudio.com/rsc/bike_model_data/)(b) to RStudio Connect.
2. Every week, the [station data ingest script](https://colorado.rstudio.com/rsc/bike_station_data_ingest/)(2) runs, which updates the [station metadata dataset](https://colorado.rstudio.com/rsc/bike_station_info/)(c) with station-level information like name and location 
2. The [model training script](https://colorado.rstudio.com/rsc/bike_model_build/)(3) (in `./Model`) is deployed on RStudio Connect for easy versioning and the ability to re-run on demand. When it runs, it trains [an `xgboost` model](https://colorado.rstudio.com/rsc/bike_available_model/)(d) that is pinned to RStudio Connect.
3. A [Plumber API](https://colorado.rstudio.com/rsc/bike_predict/)(4) (in `./API`) is deployed on RStudio Connect to serve the model predictions. While this model is intentionally opened to the world as a demo asset, it could take advantage of authentication on RStudio Connect to require [RStudio Connect API keys](https://docs.rstudio.com/connect/user/api-keys.html#api-keys-plumber) to use the API. 
4. [A Shiny dashboard](https://colorado.rstudio.com/rsc/bike_predict-app/)(5) (in `./App`) is available on RStudio Connect that visualizes the predicted number of bikes available at any station in the system over a future time period.
