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
---@field vec Vectic

---@class Vectic
---@field x number
---@field y number
local Vectic={}
Vectic.__index=Vectic

---@type fun(a?:number,b?:number): Vectic
Vectic.new=function(x,y)
  local v = {x = x or 0, y = y or 0}
  setmetatable(v, Vectic)
  return v
end

---@alias VecticOperation<OUT> fun(a:number|Vectic,b:number|Vectic):OUT
---@type VecticOperation<Vectic>
function Vectic.__add(a,b)
	a,b=Vectic.twoVec(a,b)
	return Vectic.new(a.x+b.x,a.y+b.y)
end
---@type VecticOperation<Vectic>
function Vectic.__sub(a, b)
	a,b=Vectic.twoVec(a,b)
  return Vectic.new(a.x - b.x, a.y - b.y)
end
---@type VecticOperation<Vectic>
function Vectic.__mul(a, b)
	a,b=Vectic.twoVec(a,b)
	return Vectic.new(a.x*b.x,a.y*b.y)
end
---@type VecticOperation<Vectic>
function Vectic.__div(a, b)
	a,b=Vectic.twoVec(a,b)
	return Vectic.new(a.x/b.x,a.y/b.y)
end
---@type VecticOperation<boolean>
function Vectic.__eq(a, b)
	a,b=Vectic.twoVec(a,b)
	return a.x==b.x and a.y==b.y
end
---@type VecticOperation<boolean>
function Vectic.__ne(a, b)
	a,b=Vectic.twoVec(a,b)
	return not Vectic.__eq(a, b)
end
---@type fun(a:Vectic):Vectic
function Vectic.__unm(a)
	return Vectic.new(-a.x, -a.y)
end
---@type VecticOperation<boolean>
function Vectic.__lt(a, b)
	a,b=Vectic.twoVec(a,b)
	 return a.x < b.x and a.y < b.y
end
---@type VecticOperation<boolean>
function Vectic.__le(a, b)
	a,b=Vectic.twoVec(a,b)
	 return a.x <= b.x and a.y <= b.y
end
---@type VecticOperation<string>
function Vectic.__tostring(v)
	 return "(" .. v.x .. ", " .. v.y .. ")"
end
---@type fun(a:Vectic|number,b:Vectic|number):Vectic,Vectic
function Vectic.twoVec(a,b)
	return Vectic.toVec(a),Vectic.toVec(b)
end
---@type fun(a:Vectic|number):Vectic
function Vectic.toVec(a)
	if type(a)=='number' then
		return Vectic.new(a,a)
	end
	return a
end
---@type VecticOperation<Vectic>
function Vectic.floordiv(a,b)
	b=Vectic.toVec(b)
	return Vectic.new(a.x//b.x,a.y//b.y)
end
---@type VecticOperation<number>
function Vectic.dist2(a,b)
	b=Vectic.toVec(b)
	return(a.x-b.x)^2+(a.y-b.y)^2
end
---@type VecticOperation<number>
function Vectic.dist(a,b)
	b=Vectic.toVec(b)
	return math.sqrt(a.dist2(a,b))
end
---@alias VecticFunction<OUT> fun(a:Vectic):OUT
---@type VecticFunction<Vectic>
function Vectic.floor(a)return a.floordiv(a,1)end
---@type VecticFunction<number>
function Vectic.norm(a)return a:dist(Vectic.new(0,0))end
---@type VecticFunction<Vectic>
function Vectic.normalize(a)return a/a:norm() end
---@type fun(a:Vectic,t:number):Vectic
function Vectic.rotate(a,t)return Vectic.new(a.x*math.cos(t)-a.x*math.sin(t),a.y*math.sin(t)+a.y*math.cos(t))end
---@type VecticFunction<Vectic>
function Vectic.copy(a)return Vectic.new(a.x,a.y)end
---@type fun(a:Vectic):number,number
function Vectic.xy(a) return a.x,a.y end

W=240
H=136
F=0

function TIC()
	cls(0)
	Factory:run()
	
	if F==0 then Controls:setup() end

	Controls:run()
	Screen:update()

	F=F+1
end

---@class Game
Game={
	states={
		---@param s Game
		menu=function(s)
		end,
		---@param s Game
		runGame=function(s)
			Controls:drw()
			Controls:run()
			Screen:update()
		end
	},
	currentState=Game.states.runGame,
	---@param s Game
	run=function(s)
		s:currentState()
	end
}

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
		local ox,oy=obj.vec:xy()
		s:add(obj.name..'_shake',t,function()
			obj.vec.x=math.random(ox-i,ox+i)
			obj.vec.y=math.random(oy-i,oy+i)
		end,
		function()
			obj.vec=Vectic.new(ox,oy)
		end)
	end,
	---@param s Factory
	---@param obj Entity
	---@param t frames Push duration
	---@param comp 'x'|'y' Vectic component to modify
	pushTo=function(s,obj,t,comp,a,b)
		local startF=F
		local ox,oy=obj.vec:xy()
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
	vec=Vectic.new(),
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
	---@param b Button
	drwBtn=function(s,b)
		local x,y=s.vec:xy()
		local bx=x+b.vec.x
		local by=y+b.vec.y
		local m=0
		if b.p then m=2 end
		local t_wid=print(b.c,2*W,2*H,0,false)
		local spr_id=256
		if b.p then spr_id=258 end
		pal(13,b.color)
		spr(spr_id,bx-8,by-8,0,1,0,0,2,2)
		print(b.c,bx-t_wid/2,by+m-4,12,false)
	end,
	---@param s BaseCtrl
	setup=function(s)
		for d,d_cont in pairs(s.dirs) do
			local content=tostring(d_cont)
			if type(d_cont)~="number" then content=d_cont.c end
			s.btns[d]={
				p=false,
				vec=Vectic.new(),
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
		for d,b in pairs(s.btns) do
			s:drwBtn(b)
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
	end,
	---@param s BaseCtrl
	---@param b direction
	get_btn_pos=function(s,b)
		local x,y=s.btns[b].vec:xy()
		return x+s.vec.x,y+s.vec.y
	end
}

---@class OpCtrl:BaseCtrl
OpCtrl={
	name='operations-control',
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
	---@param s BaseCtrl
	---@param btn direction
	---@return string
	press=function(s,btn)
		BaseCtrl.press(s,btn)
		return s.btns[btn].c
	end,
	check_press=BaseCtrl.check_press,
	get_btn_pos=BaseCtrl.get_btn_pos
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
	get_btn_pos=BaseCtrl.get_btn_pos
}

---@class NumberEntity:Entity
---@field n number|nil

---@param n number|nil
---@return NumberEntity
function CreateNum(name,n,x,y)
	return {name=name,n=n,vec={x=x,y=y}}
end

---@class Controls: Entity
Controls={
	name='game-controls',
	---@type OpCtrl|NumCtrl
	nxt_in=nil,
	vec={
		x=W/2,
		y=3*H/4,
	},
	---@type NumberEntity
	result=CreateNum('result',nil,W/2,H/2),
	---@type NumberEntity
	output=CreateNum('output',nil,W/2,H/2-10),
	---@type Operation
	operation=nil,
	hist={},
	nums=NumCtrl,
	ops=OpCtrl,
	---@param s Controls
	run=function(s)
		s:hndl_input()
	end,
	---@param s Controls
	drw=function(s)
		local x,y=s.nxt_in.vec:xy()
		circ(x-1,y,20,5)
		s.ops:drw()
		s.nums:drw()
		print(s.result.n,s.result.vec.x,s.result.vec.y)
		print(s.output.n,s.output.vec.x,s.output.vec.y)
	end,
	---@param s Controls
	hndl_input=function(s)
		for d,_ in pairs(s.nums.dirs) do
			if s.nxt_in:check_press(d) then
				if s.nxt_in.btns[d].c=='=' then
					s:_anim_output()
					s:_btn_press(d)
					s.output.n=s.result.n
					s.result.n=nil
					s.hist={}
					s.operation=nil
					s.nxt_in=s.nums
				else
					s:_anim_change_result(d)
					s:_btn_press(d)
				end
			end
		end
	end,
	---@param s Controls
	_anim_output=function(s)
		sfx(1,10)
	end,
	---@param s Controls
	---@param d direction
	_anim_change_result=function(s,d)
		local x,y=s.nxt_in:get_btn_pos(d)
		Factory:add(s.name..'change-result-lazer',10,
		function()
			line(s.result.vec.x,s.result.vec.y,x,y,2+(F//3)%2)
		end,
		Factory.null)

		Factory:shake(s.result,7,2)

		sfx(0,20)
	end,
	---@param s Controls
	---@param d direction
	---@param last number|string Last pressed number
	_update_result=function(s,d,last)
		if s.result.n==nil then
			s.result.n=last
		elseif s.operation==nil then
			s.operation=s.nxt_in.dirs[d]
		elseif type(s.nxt_in.dirs[d])=="number" then
			s.result.n=s.operation.f(s.result.n,s.nxt_in.dirs[d])
		else
			s.operation=s.nxt_in.dirs[d]
		end
	end,
	---@param s Controls
	---@param d direction
	_btn_press=function(s,d)
		local last=s.nxt_in:press(d)
		table.insert(s.hist,last)
		s:_update_result(d,last)
		if s.nxt_in.name==s.nums.name then s.nxt_in=s.ops
		else s.nxt_in=s.nums end
	end,
	---@param s Controls
	setup=function(s)
		s.nums.vec=Vectic.new(s.vec.x - W/3,s.vec.y)
		s.ops.vec=Vectic.new(s.vec.x + W/3,s.vec.y)
		s.ops:setup()
		s.nums:setup()
		for d,_ in pairs(s.nums.dirs) do
			s.nums:reGen(d)
		end
		s.nxt_in=s.nums
		s.result.n=nil
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
-- 000:0119013a014b015c116d217e718f9180b1a1c1c3d1d4e1f5f126f107f109f109f100f100f100f100f100f100f100f100f100f100f100f100f100f100107000000000
-- 001:0119012c0120013111242126f127f12cf11cf113019901bd01d001e401f7f10af100f100f100f100f100f100f100f100f100f100f100f100f100f100107000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

