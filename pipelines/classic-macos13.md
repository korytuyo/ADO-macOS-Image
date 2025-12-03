# Classic macOS-13 Pipeline Notes

Classic pipelines cannot be defined purely through YAML, so create one in the Azure DevOps UI to exercise the discovery script's classic detection:

1. Navigate to **Pipelines > Builds > New > Classic editor** in the `macOS13 Discovery Lab` project.
2. Choose any repo (or `Empty` template) and select the **Hosted macOS** pool.
3. In the pipeline settings, pick the agent pool named `Azure Pipelines` and the agent specification **macOS-13**.
4. Add a simple `Command Line` task with `echo Classic macOS-13` and save + queue the build once.

The discovery script flags this pipeline because `_apis/build/definitions/{id}` returns `queue.pool.name = "macOS-13"`.
