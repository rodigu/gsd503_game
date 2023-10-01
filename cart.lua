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

---@alias Vec {x: number, y:number}
---@class Vectic
Vectic={}
Vectic={
	---@param x number
	---@param y number
	---@return Vec
	new=function(x,y)return{x=x,y=y}end,
	---@param v Vec
	---@param v2 Vec
	---@return Vec
	add=function(v,v2)return Vectic.new(v.x+v2.x,v.y+v2.y)end,
	---@param v Vec
	---@param v2 Vec
	---@return Vec
	sub=function(v,v2)return Vectic.new(v.x-v2.x,v.y-v2.y)end,
	---@param v Vec
	---@param s Vec|number
	---@return Vec
	mul=function(v,s)return Vectic.new(v.x*s,v.y*s)end,
	---@param v Vec
	---@return string
	repr=function(v) return "Vectic.new("..v.x..", "..{v.y}..")"end,
	---@param v Vec
	---@param s Vec|number
	---@return Vec
	div=function(v,s)
	 if type(s)=="number" then return Vectic.new(v.x/s,v.y/s) end
	 return Vectic.new(v.x/s.x,v.y/s.y)
	end,
	---@param v Vec
	---@param s Vec|number
	---@return Vec
	floordiv=function(v,s)
	 if type(s)=="number"then return Vectic.new(v.x//s,v.y//s)end
	 return Vectic.new(v.x//s.x,v.y//s.y)
	end,
	---@param v Vec
	---@return Vec
	floor=function(v)return Vectic.floordiv(v,1)end,
	---@param v Vec
	---@param v2 Vec
	---@return number
	dist2=function(v,v2)return(v.x-v2.x)^2+(v.y-v2.y)^2 end,
	---@param v Vec
	---@param v2 Vec
	---@return number
	dist=function(v,v2)return math.sqrt(v.dist2(v2))end,
	---@param v Vec
	---@return number
	norm=function(v)return Vectic.dist(v,Vectic.zero())end,
	len=Vectic.norm,
	---@param v Vec
	---@param v2 Vec
	---@return boolean
	eq=function(v,v2)return v.x==v2.x and v.y==v2.y end,
	---@param v Vec
	---@return Vec
	normalize=function(v)return Vectic.div(v,Vectic.norm(v))end,
	---@param v Vec
	---@param t number Angle Theta in radians
	---@return Vec
	rotate=function(v,t)return Vectic.new(v.x*math.cos(t)-v.x*math.sin(t),v.y*math.sin(t)+v.y*math.cos(t))end,
	---@param v Vec
	---@return Vec
	copy=function(v)return Vectic.new(v.x,v.y)end,
	---@return Vec
	zero=function()return Vectic.new(0,0)end,
	---@param v Vec
	---@return number,number
	xy=function(v)return v.x,v.y end
}

W=240
H=136
F=0

function TIC()
	cls(0)
	
	if F==0 then Controls:setup() end

	Controls:run()
	Factory:run()
	Screen:update()

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
		local ox,oy=Vectic.xy(obj.vec)
		local m=ox
		if comp=='y' then m=oy end
		s:add(obj.name..'_push',t,function()
			obj.vec[comp]=m+a*math.sin(b*(F-startF))
		end,
		function()
			obj.vec=Vectic.new(ox,oy)
		end)
	end,
	null=function()end
}

---@class Screen: Entity
Screen={
	name='screen',
	memX=0x3FF9,
	memY=0x3FF9+1,
	vec=Vectic.zero(),
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

---@class Operation
---@field f fun(a:number,b:number):number
---@field c string

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

---@class Button: Entity
---@field p boolean Is button pressed
---@field c string Content of the button
---@field color number

---@class BaseCtrl:Entity
BaseCtrl={
	---@type {[direction]: number}
	bp_map={},
	---@type {[direction]: number}
	kp_map={},
	---@type {[direction]:Button} Pressed buttons
	btns={},
	---@type {[direction]:Operation|number} Control directions (up down left right)
	dirs={},
	---@param s BaseCtrl
	setup=function(s)
		for d,d_cont in pairs(s.dirs) do
			local content=tostring(d_cont)
			if type(d_cont)~="number" then content=d_cont.c end
			s.btns[d]={
				p=false,
				vec=Vectic.zero(),
				c=content,
				color=13
			}
		end
		local mod=17
		s.btns['up'].vec=Vectic.new(0,-mod)
		s.btns['down'].vec=Vectic.new(0,mod)
		s.btns['left'].vec=Vectic.new(-mod,0)
		s.btns['right'].vec=Vectic.new(mod,0)
	end,
	---@param s BaseCtrl
	drw=function(s)
		local x,y=Vectic.xy(s.vec)
		for d,b in pairs(s.btns) do
			local bx=x+b.vec.x
			local by=y+b.vec.y
			local m=0
			if b.p then m=2 end
			local t_wid=print(b.c,2*W,2*H)
			local spr_id=256
			if b.p then spr_id=258 end
			pal(13,b.color)
			spr(spr_id,bx-8,by-8,0,1,0,0,2,2)
			print(b.c,bx-t_wid/2,by+m-4,12)
			pal()
		end
	end,
	---@param s BaseCtrl
	---@param btn direction
	---@return Button
	press=function(s,btn)
		Factory:add(s.name..'-'..btn..'-ispush',7,
			function()
				s.btns[btn].p=true
			end,
			function()
				s.btns[btn].p=false
			end
		)
		local xy='x'
		if btn=='up' or btn=='down' then xy='y' end
		local dir_mod=2
		if btn=='left' or btn=='up' then dir_mod=-1 end
		Factory:pushTo(s,7,xy,dir_mod,.2)
		return s.btns[btn]
	end,
	---@param s OpCtrl|NumCtrl
	---@param d direction
	---@return boolean
	check_press=function(s,d)
		return keyp(s.kp_map[d]) or btnp(s.bp_map[d])
	end
}

---@class OpCtrl:BaseCtrl
OpCtrl={
	name='Operations-control',
	kp_map={
		left=10,
		right=12,
		up=9,
		down=11
	},
	bp_map={
		left=6,
		right=5,
		up=7,
		down=4
	},
	---@type {[direction]:Button} Pressed buttons
	btns={},
	---@type {[direction]:Operation} Control directions (up down left right)
	dirs={up=BaseOps.mul,down=BaseOps.zer,left=BaseOps.sub,right=BaseOps.sum},
	---@param s OpCtrl
	setup=function(s)
		BaseCtrl.setup(s)
		s.btns['up'].color=3
		s.btns['down'].color=6
		s.btns['left'].color=10
		s.btns['right'].color=2
	end,
	drw=BaseCtrl.drw,
	press=BaseCtrl.press,
	check_press=BaseCtrl.check_press
}

---@class NumCtrl:BaseCtrl
NumCtrl={
	name='numeric-control',
	kp_map={
		left=6,
		right=8,
		up=20,
		down=7
	},
	bp_map={
		left=2,
		right=3,
		up=0,
		down=1
	},
	---@type {[direction]:Button} Pressed buttons
	btns={},
	---@type {[direction]:number} Control directions (up down left right)
	dirs={up=0,down=0,left=0,right=0},
	---@type {[direction]: {min:number, max:number}}
	ranges={
		up={min=1,max=9},
		down={min=1,max=9},
		left={min=1,max=9},
		right={min=1,max=9}
	},
	setup=BaseCtrl.setup,
	drw=BaseCtrl.drw,
	---@param s NumCtrl
	---@param dir direction
	reGen=function(s,dir)
		s.dirs[dir]=math.random(s.ranges[dir].min,s.ranges[dir].max)
		s.btns[dir].c=tostring(s.dirs[dir])
	end,
	---Returns random direction
	---@param _ NumCtrl
	---@return direction
	randDir=function(_)
		local pd={'up','down','left','right'}
		return pd[math.random(4)]
	end,
	---@param s NumCtrl
	---@return number
	randNum=function(s)
		return s.dirs[s:randDir()]
	end,
	---Generate output using 2 random directions and given Operation
	---@param s NumCtrl
	---@param op Operation
	outputUsing=function(s,op)
		return op(s:randNum(), s:randNum())
	end,
	---@param s NumCtrl
	---@param btn direction
	---@return number
	press=function(s,btn)
		BaseCtrl.press(s,btn)
		local num=s.dirs[btn]
		Factory:add(s.name..'-'..btn..'-regen',7,
			function()
				s:reGen(btn)
			end,
			Factory.null
		)
		return num
	end,
	check_press=BaseCtrl.check_press,
}

---@class Controls: Entity
Controls={
	name='game-controls',
	vec={
		x=W/2,
		y=3*H/4,
	},
	nums=NumCtrl,
	ops=OpCtrl,
	---@param s Controls
	run=function(s)
		s.ops:drw()
		s.nums:drw()
		s:hndl_input()
	end,
	---@param s Controls
	hndl_input=function(s)
		for d,_ in pairs(s.nums.dirs) do
			if s.nums:check_press(d) then
				s.nums:press(d)
			elseif s.ops:check_press(d) then
				s.ops:press(d)
			end
		end
	end,
	---@param s Controls
	setup=function(s)
		s.nums.vec=Vectic.new(s.vec.x - W/4,s.vec.y)
		s.ops.vec=Vectic.new(s.vec.x + W/4,s.vec.y)
		s.ops:setup()
		s.nums:setup()
	end
}

---@param c0? number Original color
---@param c1? number
function pal(c0,c1)
	if(c0==nil and c1==nil)then for i=0,15 do poke4(0x3FF0*2+i,i)end
	else poke4(0x3FF0*2+c0,c1) end
 end


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

-- <SPRITES>
-- 000:0eeeeeeeeeddddddedddddddedddddddedddddddedddddddedddddddeddddddd
-- 001:eeeeee00dddddee0dddddde0dddddde0dddddde0dddddde0dddddde0dddddde0
-- 002:00000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 003:0000000000000000eeeeee00eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee0
-- 016:edddddddedddddddedddddddeeddddddfeeeeeeeffffffffffffffff0fffffff
-- 017:dddddde0dddddde0dddddde0dddddee0eeeeeef0fffffff0fffffff0ffffff00
-- 018:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefeeeeeee0fffffff
-- 019:eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeef0fffffff0
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

