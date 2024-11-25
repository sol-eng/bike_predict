# Contributing

## Bugs

Please report any bugs using GitHub issues: <https://github.com/sol-eng/bike_predict/issues>

## Suggestions or improvements

Please report any suggestions or improvements to GitHub issues: <https://github.com/sol-eng/bike_predict/issues>

## solutions.posit.co

For each change please review <https://solutions.posit.co/example/bike_predict/> to ensure that the information is still accurate. If necessary please also update the repo for solutions.posit.co (<https://github.com/rstudio/solutions.posit.co>).

## Deploying to Posit Connect

Posit has deployed all of the content in this repo to a demo server. Click the link to see all of the deployed content: <https://pub.current.posit.team/connect/#/content/listing?q=is:published+tag:%22Projects/Bikeshare+-+R%22>.

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
