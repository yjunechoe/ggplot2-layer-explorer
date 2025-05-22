# About

**ggplot2 Layer Explorer** is an [R Shiny app](https://shiny.posit.co/) that exposes the internal layer-building pipeline of [ggplot2](https://github.com/tidyverse/ggplot2/). It allows you to _see_ (**inspect**) and _touch_ (**highjack**) a layer's data as it flows through internal processes.

The app makes visible a fundamental concept in `{ggplot2}`: **each layer has a corresponding a tabular-data representation which undergoes incremental changes in the internals**. The usefulness of this idea is explored in the paper [Sub-layer Modularity in the Grammar of Graphics](https://yjunechoe.github.io/static/papers/Choe_2022_SublayerGG.pdf) and the companion package [ggtrace](https://github.com/yjunechoe/ggtrace) which powers the app. Later sections explain this concept in more detail in the context of the app.

The app is designed by [June Choe](https://yjunechoe.github.io/). It is deployed from GitHub at [yjunechoe/ggplot2-layer-explorer](https://github.com/yjunechoe/ggplot2-layer-explorer), where you can also file [issues](https://github.com/yjunechoe/ggplot2-layer-explorer/issues).


## How should I use the app?

The app UI is organized into three parts:

1) The **left sidebar** lists the ggproto methods that you can explore. You can hover over the "?" tooltips for short descriptions, but you will learn more from exploring what each method does on the right panel.

2) The **middle panel** is used to define a plot. Variables defined here will become available in the method explorer editor to the right. This includes the variable for the plot `p` which must be present. You can either define your own plot or choose one of the pre-defined plots at the top.

3) The **right panel** feature a second code editor, inheriting the environment of the plot editor. The app will populate the editor with a call to an `inspect_*()` function from `{ggtrace}`, taking the plot and the selected ggproto method as input. The right-panel lets you further control whether to inspect the input or output value of the method, and for which plot layer (variable `i`). From there, the "Run expression" button evaluates the code in the editor, and the "Highjack" button goes a step further to use the output of the editor code as the new input/output value for the method.


Nearly all methods listed in the left sidebar are **data-in**, **data-out**. The input/output data at those steps can be manipulated using familiar data-wrangling functions like `mutate()` from `{dplyr}`, which is already loaded into the editor environment. The exception to this pattern are the final set of drawing methods, which are **data-in**, **grob-out**. The "grob" stands for "graphical object", and can be manipulated using functions from `{grid}` (also already loaded). The `editGrob()` function is a good place to start if you're new to working with grobs.


## Motivation

While `{ggplot2}` is no doubt a visualization system, it can also be viewed as a sophisticated **data wrangling pipeline**. Each layer in a ggplot transforms its data through a series of data operations, from the raw input data to the drawing-ready data (and finally, into the graphical representation).

This data-centric re-imagining of the internals is simplistic yet powerful. The internals-as-data-wrangling model is an effective intermediate-level abstraction because **users of ggplot2 are already experts at reasoning about tabular data** (e.g., [dplyr](https://github.com/tidyverse/dplyr/), [data.table](https://github.com/Rdatatable/data.table)), something that we take for granted in the R community but is not necessarily true elsewhere. Moreover, many users aspire to develop their own [extensions](https://exts.ggplot2.tidyverse.org/gallery/); it turns out that conceptualizing extensions as custom data wrangling operations provides [the most accessible entry point](https://evamaerey.github.io/easy-geom-recipes/) into becoming an _extension developer_.

Even for those who are not interested in writing extension packages, learning about the internals can still be _immediately useful_ thanks to recent innovations in the [aesthetic evaluation semantics](https://ggplot2.tidyverse.org/reference/aes_eval.html). The new-ish functions `after_stat()`, `after_scale()`, and `stage()` now give the user unprecedented control of the layer-building pipeline _from the outside_; this flexibility is unmatched by other implementations of the Grammar of Graphics. This, again, builds on familiar ideas rooted in non-standard evaluation (specifically, [tidy evaluation](https://dplyr.tidyverse.org/articles/programming.html)), which R users are not strangers to (e.g., via `dplyr::mutate()`, the formula `~` interface, etc.). The app helps to demystify this family of functions: they essentially **schedule `mutate()` calls on the layer data, to execute later**.


## Scope

Rendering a ggplot takes a whole village of [ggproto objects and methods](https://ggplot2.tidyverse.org/reference/ggplot2-ggproto.html). The app exposes just a small subset of methods which meets the following requirements:

1. Designed to be called _exactly once_ on the layer data
2. Manipulates the _layer data_ (i.e, data-in, data-out)
3. Is a pure function

This privileges layer-level ggprotos like `Stat`, `Geom`, and `Position`, and excludes the work of others like `Facet`, `Coord`, `Scale`, and `Guide`. The limited scope is intentional, for reasons both practical (simplifies implementation) and opinionated (highlights the most accessible and interesting methods).

Motivated users wanting to do more are encouraged to try out `{ggtrace}` outside of the app. I welcome any questions about usage [on Github](https://github.com/yjunechoe/ggtrace/issues).


## Acknowledgments

This project would not be possible without `{ggplot2}` and `{shiny}` + `{webr}`. I am hugely grateful to folks in the [ggplot2 extenders community](https://github.com/ggplot2-extenders/ggplot-extension-club), especially [Gina Reynolds](https://github.com/EvaMaeRey) and [Teun van den Brand](https://github.com/teunbrand), for early feedback and support.
