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
<th style="text-align: left;">Refresh Frequency</th>
<th style="text-align: left;">Content Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><a href="">Raw Data Ingest Script</a></td>
<td style="text-align: left;">Every 20 Minutes</td>
<td style="text-align: left;">Writes data from API calls into <code>bike_raw_data</code> table in postgres.</td>
</tr>
<tr class="even">
<td style="text-align: left;"><a href="">Clean Data Script</a></td>
<td style="text-align: left;">Daily (4 am)</td>
<td style="text-align: left;">Cleans <code>bike_raw_data</code> for modeling, writes into <code>bike_model_data</code>.</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><a href="">Clean Station Metadata Script</a></td>
<td style="text-align: left;">Weekly (Sundays)</td>
<td style="text-align: left;">Ingests station metadata and saves to a pin (names, lat/long).</td>
</tr>
<tr class="even">
<td style="text-align: left;"><a href="">Data Split Script</a></td>
<td style="text-align: left;">Daily (5 am)</td>
<td style="text-align: left;">Creates a training/test split for the data for models to use, saves to a pin.</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><a href="">R XGB Model Build</a></td>
<td style="text-align: left;">Daily (6 am)</td>
<td style="text-align: left;">Rebuilds model based on training/test split indicated by Data Split Script, writes into pin.</td>
</tr>
<tr class="even">
<td style="text-align: left;"><a href="">Model Metrics Script</a></td>
<td style="text-align: left;">Daily (8 am)</td>
<td style="text-align: left;">Writes <code>bike_test_data</code> and <code>bike_predictions</code> postgres tables, writes pin of goodness-of-fit metrics.</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><a href="">Model Performance App</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">Displays model performance metrics.</td>
</tr>
<tr class="even">
<td style="text-align: left;"><a href="">Model API</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">Serves model predictions via Plumber API.</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><a href="">Bike Prediction App</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">Displays predictions from App.</td>
</tr>
<tr class="even">
<td style="text-align: left;"><a href="">bikeHelpR Package</a></td>
<td style="text-align: left;">NA</td>
<td style="text-align: left;">An R package of helper functions, rebuilt on new commits in <a href="https://demo.rstudiopm.com/client/#/repos/8/packages/bikeHelpR">internal repo</a> on demo.rstudiopm.com.</td>
</tr>
</tbody>
</table>
