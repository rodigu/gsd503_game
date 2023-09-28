-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

---@alias frames number

---@class Entity
---@field name string
---@field vec {x: number, y:number}


---@class Vectic
local Vectic={}
Vectic.zero=function()return{x=0,y=0}end
Vectic.new=function(x,y)
 local v={}
 v.x=x
 v.y=y
 v.add=function(v2)return Vectic.new(v.x+v2.x,v.y+v2.y)end
 v.iadd=function(v2)
  v.x=v.x+v2.x
  v.y=v.y+v2.y
  return v
 end
 v.sub=function(v2)return Vectic.new(v.x-v2.x,v.y-v2.y)end
 v.isub=function(v2)
  v.x=v.x-v2.x
  v.y=v.y-v2.y
  return v
 end
 v.mul=function(s)return Vectic.new(v.x*s,v.y*s)end
 v.imul=function (s)
  v.x=v.x*s
  v.y=v.y*s
  return v
 end
 v.repr=function() return "Vectic.new("..v.x..", "..{v.y}..")"end
 v.div=function(s)
  if type(s)=="number" then return Vectic.new(v.x/s,v.y/s) end
  return Vectic.new(v.x/s.x,v.y/s.y)
 end
 v.idiv=function(s)
  if type(s)=="number" then 
   v.x=v.x/s
   v.y=v.y/s
   return v
  end
  v.x=v.x/s.x
  v.y=v.y/s.y
  return v
 end
 v.floordiv=function(s)
  if type(s)=="number"then return Vectic.new(v.x//s,v.y//s)end
  return Vectic.new(v.x//s.x,v.y//s.y)
 end
 v.floor=function()return v.floordiv(1)end
 v.dist2=function(v2)return(v.x-v2.x)^2+(v.y-v2.y)^2 end
 v.dist=function(v2)return math.sqrt(v.dist2(v2))end
 v.norm=function()return v.dist(Vectic.zero())end
 v.len=v.norm
 v.eq=function(v2)return v.x==v2.x and v.y==v2.y end
 v.normalized=function()return v.div(v.norm())end
 v.normalize=function()
  v=v.normalized()
  return v
 end
 v.rotate=function(t)return Vectic.new(v.x*math.cos(t)-v.x*math.sin(t),v.y*math.sin(t)+v.y*math.cos(t))end
 v.copy=function()return Vectic.new(v.x,v.y)end
 return v
end

W=240
H=136
F=0

function TIC()
	cls(0)
	local down=btnp(0)
	local up=btnp(1)
	local left=btnp(2)
	local right=btnp(3)

	local duration=10
	local amplitude=10
	local frequency=.03

	if up then
		Factory:pushTo(Screen,duration,'y',-amplitude,frequency)
	end
	if down then
		Factory:pushTo(Screen,duration,'y',amplitude,frequency)
	end
	if left then
		Factory:pushTo(Screen,duration,'x',amplitude,frequency)
	end
	if right then
		Factory:pushTo(Screen,duration,'x',-amplitude,frequency)
	end

	Factory:run()
	Screen:update()

	spr(1+F%60//30*2,W/2,H/2,14,3,0,0,2,2)
	print("HELLO WORLD!",84,84)
	F=F+1
end

---@class RunFunc
---@field name string Name of the RunFunc
---@field t frames Time to death
---@field run fun(rf: RunFunc) Function runs every frame
---@field kill fun() Function that runs right before death

---@class Factory
Factory={
	---@type {[string]: RunFunc}
	funcs={},
	---@param s Factory
	---@param name string
	---@param t frames
	---@param run fun()
	---@param kill fun()
	add=function(s,name,t,run,kill)
		if s:has(name) then return end
		s.funcs[name]={
			name=name,
			t=t,
			---@param rf RunFunc
			run=function (rf)
				rf.t=rf.t-1
				if rf.t>=0 then run()
				else rf.kill() end
			end,
			kill=function ()
				kill()
				s:del(name)
			end
		}
	end,
	---@param s Factory
	---@param name string
	---@return boolean
	has=function(s,name)
		return s.funcs[name]~=nil
	end,
	---@param name string
	del=function(s,name)
		s.funcs[name]=nil
	end,
	---@param s Factory
	run=function(s)
		for _,rf in pairs(s.funcs) do
			rf:run()
		end
	end,
	---@param s Factory
	---@param obj Entity
	---@param t frames Shake duration
	---@param i number Shake intensity
	shake=function(s,obj,t,i)
		s:add(obj.name..'_shake',t,function()
			obj.vec.x=math.random(-i,i)
			obj.vec.y=math.random(-i,i)
		end,
		function()
			obj.vec=Vectic.zero()
		end)
	end,
	---@param s Factory
	---@param obj Entity
	---@param t frames Push duration
	---@param comp 'x'|'y' Vectic component to modify
	pushTo=function(s,obj,t,comp,a,b)
		local startF=F
		s:add(obj.name..'_push',t,function()
			obj.vec[comp]=a*math.sin(b*(F-startF))
		end,
		function()
			obj.vec=Vectic.zero()
		end)
	end
}

---@class Screen: Entity
Screen={
	name='screen',
	memX=0x3FF9,
	memY=0x3FF9+1,
	vec=Vectic.zero(0,0),
	update=function(s)
		poke(s.memX,s.vec.x)
		poke(s.memY,s.vec.y)
	end,
	---@param x number
	---@param y number
	move=function(s,x,y)
		s.vec.x=x
		s.vec.y=y
	end,
	reset=function(s)
		s:move(0,0)
	end
}

---@alias direction
---| '"up"'
---| '"down"'
---| '"left"'
---| '"right"'

---@alias operation fun(a:number,b:number):number

BaseOps={
	---@type operation
	sum=function(a,b) return a+b end,
	---@type operation
	sub=function(a,b) return a-b end,
	---@type operation
	mul=function(a,b) return a*b end,
	---@type operation
	div=function(a,b) return a/b end,
	---@type operation
	zer=function(a,b) return 0 end,
}

---@class Controls: Entity
Controls={
	name='game-controls',
	x=W/2,
	y=3*H/4,
	---@type {[direction]:number}
	buttons={},
	numsE={
		x=Controls.x - W/4,
		y=Controls.y
	},
	nums=NumCtrl,
	opsE={
		x=Controls.x + W/4,
		y=Controls.y
	},
	ops=OpCtrl,
	run=function()

	end,
	setup=function()

	end
}

---@class OpCtrl
OpCtrl={
	---@type {[direction]:operation} Control directions (up down left right)
	dirs={up=BaseOps.mul,down=BaseOps.zer,left=BaseOps.sub,right=BaseOps.sum},
}

---@class NumCtrl
NumCtrl={
	---@type {[direction]:number} Control directions (up down left right)
	dirs={up=0,down=0,left=0,right=0},
	---@type {[direction]: {min:number, max:number}}
	ranges={
		up={min=1,max=9},
		down={min=1,max=9},
		left={min=1,max=9},
		right={min=1,max=9}
	},
	---@param s NumCtrl
	---@param dir direction
	reGen=function(s,dir)
		s.dirs[dir]=math.random(s.ranges[dir].min,s.ranges[dir].max)
	end,
	---Returns random direction
	---@param s NumCtrl
	---@return direction
	randDir=function(s)
		local pd={'up','down','left','right'}
		return pd[math.random(4)]
	end,
	---@param s NumCtrl
	---@return number
	randNum=function(s)
		return s.dirs[s:randDir()]
	end,
	---Generate output using 2 random directions and given operation
	---@param s NumCtrl
	---@param op operation
	outputUsing=function(s,op)
		return op(s:randNum(), s:randNum())
	end
}

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

