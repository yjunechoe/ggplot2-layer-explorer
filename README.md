# ggplot2 layer explorer

An interactive R Shiny app that exposes `{ggplot2}`'s internal layer-building pipeline, allowing you to _see_ and _touch_ a layer's data as it flows through each processing stage.

🚀 Live app: <https://yjunechoe.github.io/ggplot2-layer-explorer/>

[](app_demo.mp4)

## Usage

Learn how the grammar of graphics is implemented under the hood with two workflows:
- **Inspect** the internal data transformation pipeline of plot layers
- **Highjack** the layer data see how modifications affect the final plot

Designed for both `{ggplot2}` users and extension developers.

## Installation

To run the app locally, clone this repository:

```bash
git clone https://github.com/yjunechoe/ggplot2-layer-explorer.git
cd ggplot2-layer-explorer
```

Install dependencies (listed in DESCRIPTION) and the companion package `{ggtrace}`:

```r
# Install app dependencies
remotes::install_deps()

# Install ggtrace from GitHub
remotes::install_github("yjunechoe/ggtrace")
```

Run the app:

```r
shiny::runApp()
```

## Related works

**Package**: [ggtrace](https://yjunechoe.github.io/ggtrace/)

**Paper**: [Sub-layer Modularity in the Grammar of Graphics](https://www.youtube.com/watch?v=dUBnitXf5mk&list=PL9HYL-VRX0oTOwqzVtL_q5T8MNrzn0mdH&index=38)

**Talks**: [JSM 2023](https://youtu.be/613Q0j6Kjm0?feature=shared), [rstudioconf 2022](https://www.youtube.com/watch?v=dUBnitXf5mk&list=PL9HYL-VRX0oTOwqzVtL_q5T8MNrzn0mdH&index=38), [useR! 2022](https://www.youtube.com/watch?v=2JX8zu4QxMg&t=2959s)
