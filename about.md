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
| **Left Sidebar** | Method selection | Lists ggproto methods to select and explore |
| **Middle Panel** | Plot definition | Define your plot or choose from pre-defined examples |
| **Right Panel** | Method exploration | Inspect/highjack method inputs/outputs using `{ggtrace}` functions |

### General Workflow

1. **Select a method** from the left sidebar
2. **Define a plot** in the middle panel
3. **Explore the method** in the right panel with a populated `inspect_*()` call. Use options at the top to change the target of exploration (Do you want the _input_ or _output_ of the method? For _which layer_ of the plot?)
4. **Run expression** to evaluate code in the right panel editor, or **Highjack plot** to re-render the plot with a modified value for the selected method

### Common Workflows

**Exploring a Stat's data-wrangling:**

<ol>
<li>Select the <code>Stat$compute_layer</code> method</li>
<li>Compare the input vs output (the "data diff")</li>
<li>Use <code>mutate()</code> on output data and click <strong>"Run expression"</strong> to see changes
<pre><code class="language-r">inspect_return(
 ...
) |>
 mutate(x = x + rnorm(n())) # jitter
</code></pre>
</li>
<li>Click <strong>"Highjack plot"</strong> to see downstream consequences. If highjacking the input, ensure that you return a <code>list()</code> of arguments:
<pre><code class="language-r">inspect_args(
 ...
) -> out # list of arguments to the method
out$data <- out$data |> 
 mutate(x = x + rnorm(n())) # jitter
out
</code></pre>
</li>
</ol>


**Exploring a Geom's graphical object output:**

<ol>
<li>Select the <code>Geom$draw_layer</code> method</li>
<li>Inspect output (a <code>list()</code> of grobs). Pluck out a grob to draw it and see its structure.</li>
<li>Use <code>editGrob()</code> on a grob and click <strong>"Run expression"</strong> to see changes</li>
<li>Click <strong>"Highjack plot"</strong> to see how it would appear on the plot. Ensure that you return a <code>list()</code> of grobs (ex: <code>out</code> instead of <code>out[[1]]</code>).
<pre><code class="language-r">inspect_return(
 ...
) -> out # list of grobs
out[[1]] <- editGrob(out, vp = viewport(angle = 30)) # rotate
out[[1]]
</code></pre>
</li>
</ol>


## Technical Scope

The app exposes just a small subset of [ggproto methods](https://ggplot2.tidyverse.org/reference/ggplot2-ggproto.html) that are:

- ✅ Called exactly once on layer data  
- ✅ Data-in, data/grob-out operations
- ✅ Pure functions

For more advanced usage beyond the app, try `{ggtrace}` directly. Questions welcome [on GitHub](https://github.com/yjunechoe/ggtrace/issues).

## Acknowledgments

This project would not be possible without `{ggplot2}` and `{shiny}` + `{webr}`. I am hugely grateful to folks in the [ggplot2 extenders community](https://github.com/ggplot2-extenders/ggplot-extension-club), especially [Gina Reynolds](https://github.com/EvaMaeRey) and [Teun van den Brand](https://github.com/teunbrand), for early feedback and support.
