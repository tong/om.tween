
# OM|TWEEN [![Build Status](https://travis-ci.org/tong/om.tween.svg?branch=master)](https://travis-ci.org/tong/om.tween)

Simple tween engine.


## Usage

```haxe
new Tween( target )
    .to( { x:700, y:200, rotation:359 }, 2000 )
    .delay( 500 )
    .easing( Linear.None )
    .start();
```
See [examples/](examples/) for more complex usage.

## Easing
![EasingGraphs](easing-graphs.png)
