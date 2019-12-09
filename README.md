This repository contains an example of using the
[pins](https://github.com/rstudio/pins) package and [RStudio
Connect](https://rstudio.com/products/connect/) to create a predictive
model and serve and visualize predictions from that model.

The entire scheme looks like this: ![](./system_schematic.png)

Content in this App
===================

<table>
<thead>
<tr class="header">
<th style="text-align: left;">Content</th>
<th style="text-align: left;">Code</th>
<th style="text-align: left;">Pin</th>
<th style="text-align: left;">Refresh Frequency</th>
<th style="text-align: left;">Content Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_intake_raw">Raw Data Ingest Script</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/master/ETL/intake_raw/ETL_raw_into_db.Rmd">Code</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">Every 20 Minutes</td>
<td style="text-align: left;">Writes data from API calls into <code>bike_raw_data</code> table in postgres.</td>
</tr>
<tr class="even">
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_clean_raw">Clean Data Script</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/master/ETL/clean_raw/ETL_clean_raw.Rmd">Code</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">Daily (4 am)</td>
<td style="text-align: left;">Cleans <code>bike_raw_data</code> for modeling, writes into <code>bike_model_data</code>.</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_station_data_ingest">Clean Station Metadata Script</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/master/ETL/station_api_to_pin/ETL_station_api_to_pin.Rmd">Code</a></td>
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_station_info">bike_station_info</a></td>
<td style="text-align: left;">Weekly (Sundays)</td>
<td style="text-align: left;">Ingests station metadata and saves to a pin (names, lat/long).</td>
</tr>
<tr class="even">
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_data_split">Data Split Script</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/master/ETL/data_split/data_split.Rmd">Code</a></td>
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_model_params">bike_model_params</a></td>
<td style="text-align: left;">Daily (5 am)</td>
<td style="text-align: left;">Creates a training/test split for the data for models to use, saves to a pin.</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_train_rxgb">R XGB Model Train</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/master/Model/build_rxgb/build_rxgb.Rmd">Code</a></td>
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_rxgb">bike_rxgb</a></td>
<td style="text-align: left;">Daily (6 am)</td>
<td style="text-align: left;">Retrains model based on training/test split indicated by Data Split Script, writes into pin.</td>
</tr>
<tr class="even">
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_model_metrics_script">Model Metrics Script</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/master/Model/model_quality_metrics/model_quality_metrics.Rmd">Code</a></td>
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_err_dat">bike_err_dat</a></td>
<td style="text-align: left;">Daily (8 am)</td>
<td style="text-align: left;">Writes <code>bike_test_data</code> and <code>bike_predictions</code> postgres tables, writes pin of goodness-of-fit metrics.</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_model_performance_app">Model Performance App</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/master/App/model_performance/app.R">Code</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">Displays model performance metrics.</td>
</tr>
<tr class="even">
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_predict_api">Model API</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/master/API/plumber.R">Code</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">Serves model predictions via Plumber API.</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/bike_predict_app">Bike Prediction App</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/master/App/client_app/app.R">Code</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">Displays predictions from App.</td>
</tr>
<tr class="even">
<td style="text-align: left;"><a href="https://colorado.rstudio.com/rsc/dev_bike_predict_app">Dev Bike Prediction App</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/dev/App/client_app/app.R">Code</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">Dev version of Bike Prediction App</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><a href="https://demo.rstudiopm.com/client/#/repos/8/packages/bikeHelpR">bikeHelpR Package</a></td>
<td style="text-align: left;"><a href="https://github.com/rstudio/bike_predict//blob/master/pkg">Code</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">Tags</td>
<td style="text-align: left;">An R package of helper functions, built in internal repo on demo.rstudiopm.com.</td>
</tr>
</tbody>
</table>
