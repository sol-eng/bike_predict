# Contributing

## Bugs

Please report any bugs using GitHub issues: <https://github.com/sol-eng/bike_predict/issues>

## Suggestions or improvements

Please report any suggestions or improvements to GitHub issues: <https://github.com/sol-eng/bike_predict/issues>

## Deploying to RStudio Connect on colorado

RStudio has deployed all of the content in this repo to our "Colorado" demo server. Click the link to see all of the deployed content: <https://colorado.rstudio.com/rsc/connect/#/content/listing?filter=min_role:viewer&filter=content_type:all&view_type=expanded&tags=111-tagtree:218>.

### Workflow diagram

The diagram below describes the bike predict data flow at a high level.

![](./img/workflow.drawio.png)

### `_content_admin.qmd`

The file [_content_admin.qmd](./_content_admin.qmd) is used to programmatically manage the content deployed to Connect. 

- If you deploy any new content please make sure to add it to this document.
- If you delete any existing content and deploy under a new unique identifier please make sure to update this document.

### `_write_manifest.qmd`

The file [_write_manifest_.qmd](./_write_manifest.qmd) is used to programmatically update all of the *manifest.json* files. 

- You should run this file anytime you make a change to deployed content to ensure that the latest dependencies are documented. 
- If you deploy any new content please make sure to add it to this document.