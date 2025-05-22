## About

**ggplot2 Layer Explorer** is an [R Shiny app](https://shiny.posit.co/) that exposes the internal layer-building pipeline of [ggplot2](https://github.com/tidyverse/ggplot2/). It allows you to *see* (**inspect**) and *touch* (**highjack**) a layer's data as it flows through internal processes.

## The Big Idea

The app makes visible a fundamental idea in `{ggplot2}`: **each layer has a corresponding tabular-data representation which undergoes incremental changes in the internals**.

This concept is further explored in:

- **Talks**: [JSM 2023](https://youtu.be/613Q0j6Kjm0?feature=shared), [rstudioconf 2022](https://www.youtube.com/watch?v=dUBnitXf5mk), [useR! 2022](https://www.youtube.com/watch?v=2JX8zu4QxMg&t=2959s)
- **Paper**: [Sub-layer Modularity in the Grammar of Graphics](https://yjunechoe.github.io/static/papers/Choe_2022_SublayerGG.pdf)
- **Companion package**: [ggtrace](https://github.com/yjunechoe/ggtrace)

## How to Use the App

| Panel | Purpose | Details |
|-------|---------|---------|
| **Left Sidebar** | Method selection | Lists ggproto methods to explore |
| **Middle Panel** | Plot definition | Define your plot or choose a pre-defined example |
| **Right Panel** | Method exploration | Inspect/highjack method inputs/outputs using `{ggtrace}` functions |

### Workflow

1. **Select a method** from the left sidebar
2. **Define a plot** in the middle panel
3. **Explore the method** in the right panel with a populated `inspect_*()` call. Use options at the top to change the target of exploration (Do you want the input or output of the method? For which layer in the plot?)
4. **Run expression** to see the captured value, or **Highjack** to re-render the plot with a modified value

### Tips

- **Data Methods**: Most methods are data-in → data-out. You can manipulate these data frames with `{dplyr}` functions like `mutate()`

- **Drawing Methods**: The final steps in the pipeline are data-in → grob-out. You can manipulate the grobs (graphics objects) with `{grid}` functions like `editGrob()`

## Technical Scope

The app exposes just a small subset of [ggproto methods](https://ggplot2.tidyverse.org/reference/ggplot2-ggproto.html) that are:

- ✅ Called exactly once on layer data  
- ✅ Data-in, data/grob-out operations
- ✅ Pure functions

For more advanced usage beyond the app, try `{ggtrace}` directly. Questions welcome [on GitHub](https://github.com/yjunechoe/ggtrace/issues).

## Acknowledgments

This project would not be possible without `{ggplot2}` and `{shiny}` + `{webr}`. I am hugely grateful to folks in the [ggplot2 extenders community](https://github.com/ggplot2-extenders/ggplot-extension-club), especially [Gina Reynolds](https://github.com/EvaMaeRey) and [Teun van den Brand](https://github.com/teunbrand), for early feedback and support.
