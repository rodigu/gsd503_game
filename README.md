# MaTIC

MaTIC is a math arcade game where you combine numbers making use of fundamental math operations.

## Difficulties

MaTIC's difficulties were created to be edited and tweaked to suit different learning goals.

The difficulty options can be found in line 71 of the cart.lua file:

```lua
DIFFS={
 easy={
  title='easy',
  time=200000,
  speedup=1,
  range={min=1,max=9},
  operations=GenOps(BaseOps.sub,BaseOps.sub,BaseOps.sum,BaseOps.sum),
  next='medium'
 },
 medium={
  title='medium',
  time=1600,
  speedup=50,
  range={min=-9,max=9},
  operations=GenOps(BaseOps.sub,BaseOps.sub,BaseOps.sum,BaseOps.sum),
  next='hard'
 },
 hard={
  title='hard',
  time=1000,
  speedup=100,
  range={min=-9,max=9},
  operations=GenOps(BaseOps.mul,BaseOps.sub,BaseOps.sum,BaseOps.div),
  next='easy'
 }
}
```

To create a new difficulty, you can just insert it at the ent of the `DIFFS` object:

```lua
DIFFS={
 easy={
  title='easy',
  time=200000,
  speedup=1,
  range={min=1,max=9},
  operations=GenOps(BaseOps.sub,BaseOps.sub,BaseOps.sum,BaseOps.sum),
  next='medium'
 },
 medium={
  title='medium',
  time=1600,
  speedup=50,
  range={min=-9,max=9},
  operations=GenOps(BaseOps.sub,BaseOps.sub,BaseOps.sum,BaseOps.sum),
  next='hard'
 },
 hard={
  title='hard',
  time=1000,
  speedup=100,
  range={min=-9,max=9},
  operations=GenOps(BaseOps.mul,BaseOps.sub,BaseOps.sum,BaseOps.div),
  next='custom' -- Make sure to change this to your difficulty name
 },
 custom={
  title='custom',
  time=2000,
  speedup=10,
  range={min=-9,max=9},
  operations=GenOps(BaseOps.mul,BaseOps.sub,BaseOps.sum,BaseOps.div),
  next='easy'
 }
}
```

A difficulty has 6 attributes (note that the game runs at 60 FPS):

- `title`: the name of the difficulty
- `time`: the maximum time for the game countdown in frames
- `speedup`: speedup amount in frames
- `range`: the range of numbers that the came can choose from
- `operations`: the operations that can be used in the difficulty
- `next`: the next difficulty, used for the difficulty selection button in the settings

MaTIC comes with a few built-in basic math operations that can be found inside of `BaseOps`:

```lua
BaseOps={
 ---@type Operation
 sum={
  f=function(a,b) return a+b end,
  c='+'
 },
 ---@type Operation
 sub={
  f=function(a,b) return a-b end,
  c='-'
 },
 ---@type Operation
 mul={
  f=function(a,b) return a*b end,
  c='x'
 },
 ---@type Operation
 div={
  f=function(a,b) return a/b end,
  c='/'
 },
 ---@type Operation
 zer={
  f=function(a,b) return 0 end,
  c='='
 },
}
```

An operation is defined as a function that takes in two numbers and returns a number.

It is possible to create custom operations. Here, I have created a function for the modulus (`%`) operand:

```lua
function mod(a, b)
  return a % b
end
```

This function can now be used in my custom difficulty. I will use it in place of the division operation:

```lua
 custom={
  title='custom',
  time=2000,
  speedup=10,
  range={min=-9,max=9},
  operations=GenOps(BaseOps.mul,BaseOps.sub,BaseOps.sum,mod),
  next='easy'
 }
```
