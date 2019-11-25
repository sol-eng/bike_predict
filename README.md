This repository contains an example of using the [pins](https://github.com/rstudio/pins) package and [RStudio Connect](https://rstudio.com/products/connect/) to create a predictive model and serve and visualize predictions from that model.

The entire scheme looks like this: 
![](./system_schematic.png)

1. The [station data RMarkdown document](https://colorado.rstudio.com/rsc/bike_station_data_ingest/) is scheduled to run every week and update the [station metadata dataset](https://colorado.rstudio.com/rsc/bike_station_info/) ( c).

2. The [bike data ingest RMarkdown document](https://colorado.rstudio.com/rsc/bike_data_ingest/) runs a cleaning script, creating an [analysis dataset](https://colorado.rstudio.com/rsc/bike_model_data/), and pinning it to RStudio Connect.

3. The [model training RMarkdown document](https://colorado.rstudio.com/rsc/bike_model_build/) runs on demand and trains [an `xgboost` model](https://colorado.rstudio.com/rsc/bike_available_model/)  that is pinned to RStudio Connect.

4. A [Plumber API](https://colorado.rstudio.com/rsc/bike_predict/) is deployed on RStudio Connect to serve model predictions. 

5. A [Shiny dashboard](https://colorado.rstudio.com/rsc/bike_predict-app/) is deployed on RStudio Connect to visualize the predicted number of bikes available.


Much of the ETL work relies on a package of helper functions, which are stored [on Github](https://github.com/rstudio/bike_predict/tree/v0.1.0/pkg), and are loaded to RStudio Connect via an internal repository in [RStudio Package Manager](https://demo.rstudiopm.com/client/#/repos/8/packages/bikeHelpR).
