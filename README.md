# About

Shady is a GLSL shader editor, that aims to be fully compatible with [https://shadertoy.com](Shadertoy.com).

![Screenshot of Shady](https://raw.githubusercontent.com/misterdanb/shady/master/github/screenshot.png)

# (Future) Features

* Full Shadertoy.com support
* Non-freezing, very responsive UI, no matter what is compiled or rendered
* Integrated Shadertoy.com search
* Live coding mode (i.e. coding in fullscreen mode)
* GLSL version switching
* Time sliding when paused
* Optimized syntax highlighting (e.g. for swizzling) and error presentation

For not yet implemented features, please have a look at the current issues.

# Building instructions

## Meson

Run the following lines:

``` bash
meson build
cd build
ninja
ninja install
```

## Flatpak

In order to build a flatpak of Shady, you need to have an up-to-date GNOME Sdk and Platform installed. Then run the following command:

``` bash
flatpak-builder build-dir org.hasi.shady.json
```

To run the flatpak locally, run:
``` bash
flatpak-builder --run build-dir org.hasi.shady.json shady
```

# Contributing

You want to help us? Nice! You're very welcome. Please contact us (for example on Twitter @misterdanb) so we can better discuss, what needs to be done and how you can do it.

# Donate

We'd also like to point you to our [https://www.patreon.com/shadygl](Patreon), which is mostly intended to finane some infrastructure like the domain and the server.
