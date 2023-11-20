-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

---@alias frames number
---@alias spr fun(id:number,x:number,y:number,colorkey?:number,scale?:number,flip?:number,rotate?:number,w?:number,h?:number)

DIRS={'up','left','right','down'}

---@class Entity
---@field name string
---@field vec Vectic
---@field siz? Vectic

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
	return Vectic.new(math.floor(a.x/b.x),math.floor(a.y/b.y))
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

	Game:run()

	Factory:run()
	F=F+1
end

---@type fun(p:Vectic,e:Entity):boolean
function PtCol(p,e)
	local rc=e.vec+e.siz/2
	local lc=e.vec-e.siz/2
	return p<rc and p>lc
end

---@class Factory
Factory={
	---@type {[string]: RunFunc}
	funcs={},
	---@param s Factory
	---@param name string
	---@param t frames
	---@param run fun()
	---@param kill fun()
	---@param delay? number
	add=function(s,name,t,run,kill,delay)
		delay=delay or 0
		if s:has(name) then return end
		s.funcs[name]={
			name=name,
			t=t,
			---@param rf RunFunc
			run=function (rf)
				if delay>0 then
					delay=delay-1
					return
				end
				rf.t=rf.t-1
				if rf.t~=0 then run()
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
	null=function()end,
	---@param s Factory
	---@param obj Entity
	---@param t frames
	---@param a number
	---@param b number
	float=function(s,obj,t)
	end,
	---@param s Factory
	---@param n string
	---@param f function
	---@param t number
	delayCall=function(s,n,f,t)
		s:add(n,t,s.null,f)
	end
}

---@class Selection
---@field drw fun(s: Game)
---@field slct number

---@param s Game
---@param buttons Button[]
---@param funcs fun(s: Game)[]
---@return Selection
local CreateSelection=function (s, buttons, funcs)
	local t={}
	t.slct=1

	local function ctrls()
		if btnp(NumCtrl.bp_map['up']) then
			t.slct=t.slct-1
		elseif btnp(NumCtrl.bp_map['down']) then
			t.slct=t.slct+1
		end

		if btnp(OpCtrl.bp_map['down']) then
			funcs[t.slct](s)
		end

		if t.slct<1 then t.slct=#buttons end
		if t.slct>#buttons then t.slct=1 end
	end

	---@param s Game
	t.drw=function(s)
		ctrls()
		for i,b in ipairs(buttons) do
			if i==t.slct then
				b.color=6
			else
				b.color=13
			end
			s:drwTxtBtn(b, b.siz.x/8-2)
		end
	end
	
	return t
end

---@param s Game
GameMenu=function()
	---@type Button[]
	local bs={
		{
			c='start',
			color=13,
			name='start-button',
			p=false,
			vec=Vectic.new(W/2,H/2-20),
			siz=Vectic.new(7*8,16)
		},
		{
			c='options',
			color=13,
			name='options-button',
			p=false,
			vec=Vectic.new(W/2,H/2),
			siz=Vectic.new(7*8,16)
		},
	}

	local fs={
		function (s)
			s:transTo(s.states.runGame)
		end
	}

	local slct=nil

	return function(s)
		if slct==nil then slct=CreateSelection(s, bs, fs) end
		slct.drw(s)
	end
end

---@param v Vectic
function CreateExplode(v)
	local max=5
	local maxS=5

	---@class Particle
	---@field pos Vectic
	---@field speed Vectic
	---@field size number

	---@type Particle[]
	local ps={}
	for i=1,max do
		ps[i]={
			pos=v:copy(),
			speed=Vectic.new(math.random(-2,2),math.random(-2,2)),
			size=.5
		}
	end

	local startF=F
	
	return function()
		for _,p in ipairs(ps) do
			circb(p.pos.x, p.pos.y, p.size, 2)
			p.pos=p.pos+p.speed
			p.size=math.sin((F - startF)/3.2)*maxS
		end
	end
end

GameRun=function()
	---@type NumberEntity
	local target={
		name='target',
		n=NumCtrl:outputUsing(OpCtrl:rndOp()),
		vec=Controls.output.vec
	}
	local score=0
	local tmax=900
	local timer=tmax
	local c=6

	local showScore=function()
		local y=16
		local w=print('SCORE: '..score,W,H)
		rect((W-w)/2-2,y-3,w+2,12,14)
		CPrint('SCORE: '..score,W/2-1,y+1,15)
		CPrint('SCORE: '..score,W/2,y,12)
	end

	local showTarget=function()
		CPrint('target:',W/2,target.vec.y-10,4)
		CPrint(target.n,target.vec.x,target.vec.y,4)
	end

	---@param s Game
	local function endGame()
		score=0
		tmax=900
		timer=tmax
		c=6
		Controls:reset()
		target.n=NumCtrl:outputUsing(OpCtrl:rndOp())
	end

	---@param s Game
	return function(s)
		Controls.target_ref=target
		local pts=(10*#Controls.hist)*(timer/tmax)//1
		if pts<1 then pts=1 end
		if Controls.result.n==target.n then
			Factory:add('explosion', 20, CreateExplode(target.vec),Factory.null)
			Factory:shake(target,10,5)
			score=math.floor(score+pts)
			Controls.hist={}
			timer=tmax
			c=5
			target.n=NumCtrl:outputUsing(OpCtrl:rndOp())
		end
		Controls:drw()
		Controls:run(tostring(target.n))
		Screen:update()
		if (timer%200==0) and c~=2 then c=c-1 end
		rect(0,0,W*timer/tmax,10,c)
		rectb(0,0,W,10,12)
		timer=timer-1
		if timer<=1 then
			s:transTo(s.states.menu)
			endGame()
		end
		showScore()
		showTarget()
	end
end

CPrint=function(t,x,y,c)
	local w=print(t,W,H)
	return print(t,x-w/2,y,c)
end


---@class RunFunc
---@field name string Name of the RunFunc
---@field t frames Time to death
---@field run fun(rf: RunFunc) Function runs every frame
---@field kill fun() Function that runs right before death

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

ButtonFuncs={
	---@param b Button
	unpush=function(b)
		Factory:add('unpush-'..b.c, 5, Factory.null, function() b.p=false end)
	end
}

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
	---@param b Button
	---@param side 'left'|'right'|'center'
	---@param pos? Vectic
	btnSection=function(b,side,pos)
		local spr_id=256

		if side=='right' then spr_id=288
		elseif side=='center' then spr_id=320 end

		if b.p then spr_id=spr_id+1 end

		if pos==nil then pos=b.vec end
		
		pal(13,b.color)
		spr(spr_id,pos.x-8,pos.y-8,0,1,0,0,1,2)
		pal()
	end,
	
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
		BaseCtrl.btnSection(b,'left',b.vec+s.vec)
		BaseCtrl.btnSection(b,'right',b.vec+Vectic.new(8,0)+s.vec)
		pal()
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
	dirs={up=BaseOps.mul,down=BaseOps.div,left=BaseOps.sub,right=BaseOps.sum},
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
	get_btn_pos=BaseCtrl.get_btn_pos,
	drwBtn=BaseCtrl.drwBtn,
	---@param s OpCtrl
	---@return Operation
	rndOp=function(s)
		local d=DIRS[math.random(1,3)]
		return s.dirs[d].f
	end
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
		up={min=-9,max=9},
		down={min=-9,max=9},
		left={min=-9,max=9},
		right={min=-9,max=9}
	},
	drw=BaseCtrl.drw,
	---@param s NumCtrl
	---@param dir direction
	reGen=function(s,dir)
		s.dirs[dir]=math.random(s.ranges[dir].min,s.ranges[dir].max)
		s.btns[dir].c=tostring(s.dirs[dir])
	end,
	---@param s NumCtrl
	reGenAll=function(s)
		for _,d in pairs(DIRS) do s:reGen(d) end
	end,
	---Returns random direction
	---@param _ NumCtrl
	---@return direction
	randDir=function(_)
		return DIRS[math.random(4)]
	end,
	---@param s NumCtrl
	---@return number
	rndNum=function(s)
		return s.dirs[s:randDir()]
	end,
	---Generate output using 2 random directions and given Operation
	---@param s NumCtrl
	---@param op Operation
	outputUsing=function(s,op)
		return op(s:rndNum(), s:rndNum())
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
	get_btn_pos=BaseCtrl.get_btn_pos,
	drwBtn=BaseCtrl.drwBtn,
	---@param s NumCtrl
	setup=function(s)
		BaseCtrl.setup(s)
		s:reGenAll()
	end
}

---@class NumberEntity:Entity
---@field n number|nil

---@param n number|nil
---@return NumberEntity
function CreateNum(name,n,x,y)
	return {name=name,n=n,vec=Vectic.new(x,y)}
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
	target_ref={},
	---@type NumberEntity
	result=CreateNum('result',nil,W/2,H/2+10),
	---@type NumberEntity
	output=CreateNum('output',nil,W/2,H/2-20),
	---@type Operation
	operation=nil,
	hist={},
	nums=NumCtrl,
	ops=OpCtrl,
	---@param s Controls
	---@param target string
	run=function(s, target)
		s:hndl_input(target)
	end,
	---@param s Controls
	drw=function(s)
		local x,y=s.nxt_in.vec:xy()
		circ(x-1,y,20,5)
		s.ops:drw()
		s.nums:drw()
		CPrint('result:',s.result.vec.x,s.result.vec.y-10,12)
		local r='?'
		if s.result.n~=nil then r=s.result.n end
		CPrint(r,s.result.vec.x,s.result.vec.y,12)
	end,
	---@param s Controls
	reset=function(s)
		s.output.n=s.result.n
		s.result.n=nil
		s.operation=nil
		s.nxt_in=s.nums
	end,
	---@param s Controls
	---@param target string
	hndl_input=function(s, target)
		for d,_ in pairs(s.nums.dirs) do
			if s.nxt_in:check_press(d) then
				if s.nxt_in.btns[d].c==target then
					local x,y=s.nxt_in:get_btn_pos(d)
					s:_anim_output()
					s:_btn_press(d)
					Factory:add('submit-score',10,
						function()
						end,
						function()
							s:reset(d)
						end)
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
		-- Factory:add('set-output',10,
		-- 	function()

		-- 	end)
	end,
	---@param s Controls
	---@param d direction
	_anim_change_result=function(s,d)
		local duration=15
		local x,y=s.nxt_in:get_btn_pos(d)
		local speed_vec=(s.result.vec-Vectic.new(x,y))/duration
		local p=Vectic.new(x,y)
		local sf=F
		Factory:add(s.name..'-change-result-lazer-'..s.nxt_in.name,duration,
			function()
				p=p+speed_vec
				circ(p.x,p.y,5+5*math.sin((F-sf)/4),12)
				-- line(s.result.vec.x,s.result.vec.y,x,y,2+(F//3)%2)
			end,
			Factory.null)

		Factory:shake(s.result,7,2)

		sfx(0,20,10)
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

Controls:setup()

---@class Game
Game={
	---@type fun(s:Game,b:Button,wid:number)
	drwTxtBtn=function(s,b,wid)
		local cx=-(wid/2)*8
		BaseCtrl.btnSection(b,'left',b.vec+Vectic.new(cx,0))
		cx=cx+8
		for i=1,wid do
			BaseCtrl.btnSection(b,'center',b.vec+Vectic.new(cx,0))
			cx=cx+8
		end
		BaseCtrl.btnSection(b,'right',b.vec+Vectic.new(cx,0))

		local t_wid=print(b.c,W,H,12)
		local pymod=0
		if b.p then pymod=2 end
		print(b.c,b.vec.x-t_wid/2,b.vec.y-4+pymod,12)
	end,
	states={
		menu=GameMenu(),
		runGame=GameRun()
	},
	---@type fun(s:Game)
	currentState=nil,
	---@param s Game
	run=function(s)
		s.currentState(s)
	end,
	---@type fun(s:Game)
	setup=function(s)
		s.currentState=s.states.menu ----------------------------------------------------------------- TODO: CHANGE
	end,
	---@type fun(s:Game,nxt:fun(s:Game))
	transTo=function(s,nxt)
		local w=0
		local x=0
		local dur=30
		Factory:add('transition',dur/2+1,
		function()
			rect(0,0,w,H,14)
			w=w+(W/(dur/2))
		end,
		function()
			s.currentState=nxt
		end)
		Factory:add('detransition',dur,
		function()
			rect(x,0,w,H,14)
			x=x+(W/(dur/2))
		end,
		Factory.null,
		dur/2)
	end,
}

---@param c0? number Original color
---@param c1? number
function pal(c0,c1)
	if(c0==nil and c1==nil)then for i=0,15 do poke4(0x3FF0*2+i,i)end
	else poke4(0x3FF0*2+c0,c1) end
 end

Game:setup()

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
-- 001:00000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 016:edddddddedddddddedddddddeeddddddfeeeeeeeffffffffffffffff0fffffff
-- 017:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefeeeeeee0fffffff
-- 032:eeeeee00dddddee0dddddde0dddddde0dddddde0dddddde0dddddde0dddddde0
-- 033:0000000000000000eeeeee00eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee0
-- 048:dddddde0dddddde0dddddde0dddddee0eeeeeef0fffffff0fffffff0ffffff00
-- 049:eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeef0fffffff0
-- 064:eeeeeeeedddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 065:0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 080:ddddddddddddddddddddddddddddddddeeeeeeeeffffffffffffffffffffffff
-- 081:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffffff
-- 096:000f000000fcf00000fcff000ffcccf0fcfccccf0fcccccf00fcccf0000fff00
-- 097:f0000000ff000000fcf00000fccf0000fcccf000fcccff00fcff0000ff000000
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:0109011a111a111b112b112d213e214f3161317241a441c541d541e641e641d641d541b5418431623151314e213c212b112a111a011a011a010b010b137000000000
-- 001:0119012c0120013111242126f127f12cf11cf113019901bd01d001e401f7f10af100f100f100f100f100f100f100f100f100f100f100f100f100f100107000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

