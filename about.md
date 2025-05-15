# About

The **ggplot2 Layer Explorer** is an [R Shiny app](https://shiny.posit.co/) that exposes the internal layer-building pipeline of [ggplot2](https://github.com/tidyverse/ggplot2/). It is primarily designed as a pedagogical tool, allowing users to _see_ (**inspect**) and _touch_ (**highjack**) a layer's data as it flows through internal processes. The aim is to help build an intuition for how user-facing code manifests into a plot.

The app makes visible a fundamental concept: **each layer has a corresponding a tabular-data representation which undergoes incremental changes in the internal pipeline**. This idea is formally motivated in the paper [Sub-layer Modularity in the Grammar of Graphics](https://yjunechoe.github.io/static/papers/Choe_2022_SublayerGG.pdf) and the companion package [ggtrace](https://github.com/yjunechoe/ggtrace) which powers the app. Later sections explain this idea in more detail in the context of the app.

The ggplot2 Layer Explorer is designed by [June Choe](https://yjunechoe.github.io/). It is deployed from GitHub at [yjunechoe/ggplot2-layer-explorer](https://github.com/yjunechoe/ggplot2-layer-explorer), where you can also files any [issues](https://github.com/yjunechoe/ggplot2-layer-explorer/issues).


## Motivation

While ggplot2 is traditionally understood as a visualization system, it can also be viewed as a sophisticated **data wrangling pipeline**. Each layer in a ggplot transforms its data through a series of data operations, from the raw input data to the drawing-ready data (and finally, into the graphical representation).

This data-centric re-imagining of the internals is simplistic yet powerful. The internals-as-data-wrangling model is an effective intermediate-level abstraction because **users of ggplot2 are already experts at reasoning about tabular data** (e.g., [dplyr](https://github.com/tidyverse/dplyr/), [data.table](https://github.com/Rdatatable/data.table)), something that we take for granted in the R community but is not necessarily true elsewhere. Moreover, many users aspire to develop their own [extensions](https://exts.ggplot2.tidyverse.org/gallery/); it turns out that conceptualizing extensions as custom data wrangling operations provides [the most accessible entry point](https://evamaerey.github.io/easy-geom-recipes/) into becoming an _extension developer_.

Even for those who are not interested in writing extension packages, learning about the internals can be _immediately useful_ thanks to recent innovations in ggplot2's [delayed aesthetic evaluation](https://ggplot2.tidyverse.org/reference/aes_eval.html) system. The new-ish functions `after_stat()`, `after_scale()`, and `stage()` now give the user unprecedented control of the layer-building pipeline _from the outside_; this flexibility is unmatched by other implementations of the Grammar of Graphics. This, again, builds on familiar ideas rooted in non-standard evaluation (specifically, [tidy evaluation](https://dplyr.tidyverse.org/articles/programming.html)), which R users are not strangers to (via `dplyr::mutate()`, the formula `~` interface, etc.). The app tries to demystify this family of functions: they essentially **schedule `mutate()` calls on the layer data, to execute later**.


## Scope

Rendering a ggplot takes a whole [village of ggproto objects and methods](https://ggplot2.tidyverse.org/reference/ggplot2-ggproto.html). The app exposes just a small subset which meets the following requirements:

1. Designed to be called _exactly once_ in building a layer
2. Manipulates the _layer data_ (dataframe in, dataframe out).

This privileges layer-level ggprotos like `Stat`, `Geom`, and `Position`, and excludes the work of others like `Facet`, `Coord`, and `Guide`. The limited scope is intentional, for reasons both practical (keeps implementation simple) and opinionated (showcases just the most approachable ggprotos).

Motivated users wanting to do more are encouraged to try out `ggtrace` on their own, outside of the app. I welcome any questions about usage [on Github](https://github.com/yjunechoe/ggtrace/issues).


## Acknowledgments

This project would not be possible without the developers of `ggplot2`. I am indebted to the [ggplot2 extenders community](https://github.com/ggplot2-extenders/ggplot-extension-club) for inspiration, feedback, and support.
