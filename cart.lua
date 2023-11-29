-- title:   MaTIC
-- author:  Rodrigo
-- desc:    Arcade math worksheet game
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

GLOBAL={
	JUICE=true,
	DIFFICULTY='medium',
	HIGH=0,
	VOL=10
}

if pmem(0) then
	GLOBAL.HIGH=pmem(0)
end

---@class Difficulty
---@field title string
---@field time integer
---@field speedup number speedup increment for every correct answer
---@field range {min: number, max:number}
---@field operations table<direction, Operation>
---@field next string

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

---@param up Operation
---@param down Operation
---@param left Operation
---@param right Operation
---@return table<direction, Operation>
function GenOps(up, down, left, right)
	return {
		up=up,
		down=down,
		left=left,
		right=right
	}
end

---@type table<string,Difficulty> Difficulties
DIFFS={
	easy={
		title='easy',
		time=2000,
		speedup=10,
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
			if not GLOBAL.JUICE then return end
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
			if not GLOBAL.JUICE then return end
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
	end,
	---@param s Factory
	---@param str string
	---@param pos Vectic position
	---@param t integer duration
	---@param freq integer wave frequency
	---@param hei number wave height
	---@param col number color
	waveStr=function(s,str,pos,t,freq,hei,col,sc,fix)
		if not sc then sc=1 end
		local start=F
		---@param mod integer modifier
		local sin=function(mod)
			return math.sin((F-start+mod)/freq)*hei
		end

		s:add('wave-'..str, t, function ()
			local dist=0
			for i=1,#str do
				local c=str:sub(i,i)
				local wid=print(c,-W,-H,1,fix,sc)
				local m=sin(dist)
				if not GLOBAL.JUICE then
					col=12
					m=0
				end
				print(c,pos.x+dist,pos.y+m,col,fix,sc)
				dist=dist+wid
				i=i+1
			end
		end,
		function ()
			
		end)
	end
}

function Sound(id,note,dur,speed)
	if not GLOBAL.JUICE then return end
	sfx(id,note,dur,0,GLOBAL.VOL,speed)
end

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
			Sound(2,28,15)
		elseif btnp(NumCtrl.bp_map['down']) then
			t.slct=t.slct+1
			Sound(2,28,15)
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
	local maxS=8

	---@class Particle
	---@field pos Vectic
	---@field speed Vectic
	---@field size number

	---@type Particle[]
	local ps={}
	for i=1,max do
		ps[i]={
			pos=v:copy(),
			speed=Vectic.new(math.random(-2,2),math.random(-4,-2)),
			size=0
		}
	end

	local startF=F
	local g=Vectic.new(0,.2)
	
	return function()
		if not GLOBAL.JUICE then return end
		for _,p in ipairs(ps) do
			circb(p.pos.x, p.pos.y, p.size, 3)
			circb(p.pos.x, p.pos.y, p.size - 2, 2)
			p.pos=p.pos+p.speed
			p.speed=p.speed+g
			p.size=math.sin((F - startF)/12)*maxS
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
	local tmax=DIFFS[DIFFICULTY].time
	local timer=tmax
	local c=6

	local showScore=function()
		local y=16
		local w=print('SCORE: '..score,W,H)
		rect((W-w)/2-2,y-3,w+2,12,14)
		CPrint('SCORE: '..score,W/2-1,y+1,15)
		CPrint('SCORE: '..score,W/2,y,12)
		local m=0
		if GLOBAL.JUICE then
			m=math.sin(F/10)*2+1
		end
		CPrint('x'..LastSession.multi,W/2+w*.7,y+m,3)
	end

	local showTarget=function()
		CPrint('target:',W/2,target.vec.y-10,4)
		CPrint(target.n,target.vec.x,target.vec.y,4)
	end

	OpCtrl:setDiff()
	NumCtrl:setDiff()
	Controls:setup()
	Controls.nxt_in=NumCtrl

	---@param s Game
	local function endGame()
		score=0
		tmax=tmax-DIFFS[DIFFICULTY].speedup
		timer=tmax
		c=6
		Controls:reset()
		target.n=NumCtrl:outputUsing(OpCtrl:rndOp())
	end

	---@param s Game
	return function(s)
		Controls.target_ref=target
		local time_taken=tmax-timer
		local pts=(tmax*(1+#Controls.hist)/(time_taken+2))-2
		if pts<1 then pts=1 end
		if Controls.result.n==target.n then
			Factory:delayCall('explode-sfx', 
			function()
				Sound(1,25,60)
				Factory:add('explosion', 60, CreateExplode(target.vec),Factory.null)
				Factory:shake(target,10,5)
				score=math.floor(score+pts)
				Controls.hist={}
				timer=tmax
				c=5
				target.n=NumCtrl:outputUsing(OpCtrl:rndOp())
				Controls:reset()
			end, 10)
		end
		Controls:drw()
		Controls:run(tostring(target.n))
		Screen:update()
		if (timer%200==0) and c~=2 then c=c-1 end
		if not GLOBAL.JUICE then c=13 end
		rect(0,0,W*timer/tmax,10,c)
		rectb(0,0,W,10,12)
		timer=timer-1
		if timer<=1 then
			s:transTo(s.states.gameOver)
			Sound(5,32,20)
			Factory:delayCall('game-reset', endGame, 30)
		end
		showScore()
		showTarget()
	end
end

CPrint=function(t,x,y,c)
	local w=print(t,W,H)
	if not GLOBAL.JUICE and c~=15 then c=12 end
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
		
		pal(14,b.color)
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
		pal(14,b.color)
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
				color=14
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
	setDiff=function(s)
		s.dirs=DIFFS[DIFFICULTY].operations
	end,
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
	rndOp=function(s)
		local d=DIRS[math.random(1,3)]
		return DIFFS[DIFFICULTY].operations[d].f
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
	setDiff=function(s)
		local r=DIFFS[DIFFICULTY].range
		for n,_ in pairs(s.ranges) do
			s.ranges[n]={min=r.min,max=r.max}
		end
	end,
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
		local cc=13
		if GLOBAL.JUICE then cc=5 end
		circ(x-1,y,20,cc)
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
	---@param d direction
	_anim_change_result=function(s,d)
		local duration=15
		local x,y=s.nxt_in:get_btn_pos(d)
		local speed_vec=(s.result.vec-Vectic.new(x,y))/duration
		local p=Vectic.new(x,y)
		local sf=F
		Factory:add(s.name..'-change-result-lazer-'..s.nxt_in.name,duration,
			function()
				if not GLOBAL.JUICE then return end
				p=p+speed_vec
				circ(p.x,p.y,5+5*math.sin((F-sf)/4),12)
				-- line(s.result.vec.x,s.result.vec.y,x,y,2+(F//3)%2)
			end,
			Factory.null)

		Factory:shake(s.result,7,2)

		Sound(0,20,10)
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
	if (not GLOBAL.JUICE) then return end
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
-- 000:0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 001:00000000000000000fffffffffffffffffffffffffffffffffffffffffffffff
-- 016:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefeeeeeeeffffffffffffffff0fffffff
-- 017:ffffffffffffffffffffffffffffffffffffffffffffffffffffffff0fffffff
-- 032:eeeeee00eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeee0
-- 033:0000000000000000ffffff00fffffff0fffffff0fffffff0fffffff0fffffff0
-- 048:eeeeeee0eeeeeee0eeeeeee0eeeeeee0eeeeeef0fffffff0fffffff0ffffff00
-- 049:fffffff0fffffff0fffffff0fffffff0fffffff0fffffff0fffffff0fffffff0
-- 064:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 065:0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff
-- 080:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffffffffffffffffffffff
-- 081:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 096:000f000000fcf00000fcff000ffcccf0fcfccccf0fcccccf00fcccf0000fff00
-- 097:f0000000ff000000fcf00000fccf0000fcccf000fcccff00fcff0000ff000000
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:0009001a101a101b102b102d203e204f3061307240a440c540d540e640e640d640d540b5408430623051304e203c202b102a101a001a001a000b000b138000000000
-- 001:0019002c0020003110242026f027f02cf01cf013009900bd00d000e400f7f00af000f000f000f000f000f000f000f000f000f000f000f000f000f000107000000000
-- 002:00f700f700f70008000800080000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000301000000000
-- 003:001800180058005800a500a500a500e700e700e700e700e7f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000440000000000
-- 004:7071609260b250c340d330e320e410f410f510f510e510d510d510c510a50095f085f065f055f064f064f064f083f083f082f082f0c1f0c1f0c1f0f0300000000000
-- 005:00e700a700ab00ab00ab00ab00ab00ab00ab00ab004b004b004b004b004b004b004b004b004b004b004b004b004b0048000800080008000800080008300000000000
-- 006:f20002000200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200305000000000
-- 007:f000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000f000208000000000
-- 008:620062006200620062006200620062006200620062006200620062006200620062006200620062006200620062006200620062006200620062006200000000000000
-- 009:b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000000000000000
-- </SFX>

-- <PATTERNS>
-- 000:8cc176000070dcc176000000fcc1760000004cc178000000dcc176000000100070000000000070000000000070000000800076000070d00076000000f00076000000400078000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:000070000070000070000070000070000000d5b1820000700000700000008fb182000070000070000000d5b182000000000070000070800082000000000000000070d00082000070000070000000800082000000000000000000d00082000000000000000000800082000000000000000000d00082000000000000000000800082000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:0000000000008b5182000000000000000000d5b1820000000000000000008b5182000000000000000000d5b182000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:8cc176000070dcc176000000f000760000004cc198000070000070000070f00076000070d00076000070400078000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:400078000070f00076000070d00076000000800078000000000070000000800078000000000000000000800078000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:800078000000600078000070800078000000900078000000900078000070000070000070000070000070000070100070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:800078000000800078000000600078000000800078000000400078000000000070000000000070000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:400078000000400078000000400078000000f00076000000000070000000800078000070000070000000400078000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000f00076000000000070000000d00076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:0000000000008b5182000000000000000000f5b1820000000000000000008b5182000000000000000000f5b182000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000000000800082000000000000000000d00082000000000000000000800082000000000000000000d00082000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </PATTERNS>

-- <TRACKS>
-- 007:0001800001c00004c00005c00006820007c00008820009c0000000000000000000000000000000000000000000000000ce0300
-- </TRACKS>

-- <SCREEN>
-- 000:0000000000000000000f0f000220000000000001000000000100222000000000000000000000000000000000000000000000000000f0000000000000ff0000000000000000022200000011100000000000000000000000000000000000000000000000000000000010000000000000000000000000000000
-- 001:0000000000000000000fff002000000000000000100000001000202000000000000000000000000000000000000000000000f0f00ff000000000000000f000000000000000001200000000100000000000000000000000000000000000000000000000000000000010000000000000000000000cc0000c00
-- 002:000000000000000000000f002220000000000011000000001000222000000000000000000000000000000000000000000000f0f000f00000000000000f00000000000000000012000000001000000000000000000000000000000000000000000000000000000022000000000000000000c0c0c0c000cc00
-- 003:000000000000000000000f002020000000000002200000000220002000000000000000000000000000000000000000000000fff000f000000000000000f0000000000000000111000000220000000000000000000000000000000000000000000000000000000000200000000000000000c0c0c0c0000c00
-- 004:000000000000000000011100222000000000002000000000200000200000000000000000000000000000000000000000000000f00fff000000000000ff00000000000000000222000000002000000000000000000000000000000000000000000000000000000002000000000000000000c0c0c0c0000c00
-- 005:0000000000000000000101000000000000000022200000002220fff00000000000000000000000000000000000000000000000f000110000000000000000000000000000000202000000020000000000000000000000ff00000000000000000000000000000000002000000000000000000c00cc00c0ccc0
-- 006:000000000000000000011100000000000000002020000aaaaaaaaaa00000aaaaaaaaaa0000000000000000000000000000000000010000aaaaaaaaaaaaaaaaaaaa0000000002aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaa0000000000000000000002200000000000000000000000000000000
-- 007:000000000000000000010100000000000000002220000aaaaaaaaaa00000aaaaaaaaaa000000000000000000000000000000ff00011100aaaaaaaaaaaaaaaaaaaa0000000002aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000011100000000000000000000000aaaaaaaaaa00000aaaaaaaaaa00000000000000000000000000000000f0010100aaaaaaaaaaaaaaaaaaaa0000000002aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000000aaaaaaaaaa00000aaaaaaaaaa0000000000000000000000000000000f00011100aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000
-- 010:000000000000000000020200000000000000000000000aaaaaaaaaa00000aaaaaaaaaa00000000000000000000000000000000f0000000aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000
-- 011:000000000000000000020200000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaaaaaaaff0002220000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa0000000000aaaaa00000000000000000000000000000000000000000000000000
-- 012:000000000000000000022200000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaaaaaaa000002020000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa0000000000aaaaa00000000000000000000000000000000000000000000000000
-- 013:000000000000000000000200000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaaaaaaa111002220000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa0000000000aaaaa00fff000000000000000000000000000000000000000000000
-- 014:000000000000000000000200000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaaaaaaa100000020000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa0000000000aaaaa00f0f000000000000000000000000000000000000000000000
-- 015:000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaaaaaaa110000020000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa0000000000aaaaa00fff000000000000000000000000000000000000000000000
-- 016:000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaa00000aaaaa0000000000aaaaaaaaaa001000000000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa00000000000000000f0f000000000000000000000f0f000000000000000000000
-- 017:000000000ff0000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaa00000aaaaa0000000000aaaaaaaffa110000000000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa00000000000000000fff000000000000000000000f0f000000000000000000000
-- 018:00000000000f000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaa00000aaaaa0000000000aaaaaafaaa000000000000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa00000000000000000000000000000000000000000fff000000f0f000000000000
-- 019:0000000000f0000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaa00000aaaaa0000000000aaaaaafffa220000000000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa00000000000000000fff00000000000000000000000f000000f0f000000000000
-- 020:00000000000f000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaa00000aaaaa0000000000aaaaaafafa002000000000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa00000000000000000f0f00000000000000000000000f000000fff000000000000
-- 021:000000000ff0000000000000000000000000000000000aaaaa00001aaaaa00000aaaaa00000aaaaa0000000000aaaaaafffa020000000000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa0000000000aaaaa00ff000000000000000000000000000000000f000000000000
-- 022:000000000000000000000000000000000000000000000aaaaa00000aaaaa00000aaaaa00000aaaaa0000000000aaaaaaaaaa200000000000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa0000000000aaaaa00fff00000000000000000000011100000000f000000000000
-- 023:0000000000f0000000000000000000000000000000000aaaaa00022aaaaa00000aaaaa00000aaaaa0000000000aaaaaafffa222000000000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa0000000000aaaaa00ff0000000000000000000000100000000000000000000000
-- 024:000000000ff0000000000000000000000000000000000aaaaa00200aaaaa00000aaaaa00000aaaaa0000000000aaaaaaaafa000000000000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa0000000fffaaaaa00ff0000000000000000000000110000000f0f000000000000
-- 025:0000000000f000f0f0000000000000000000000000000aaaaa00222aaaaa00000aaaaa00000aaaaa0000000000aaaaaaafaa000000000000000aaaaaaaaaa00000000000000000000aaaaaaaaaa0000000000aaaaaaaaaa0000000f0faaaaa0011f000000000000000000000001000000f0f000000000000
-- 026:0000000000f000f0f0000000f0f000000000000000000aaaaa002020000000000aaaaa0000000000aaaaaaaaaaaaaaaafaaa000000000000000aaaaaaaaaa000000000000000aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaafff0000000ff0000000000000000000000110000000fff000000000000
-- 027:000000000fff00fff0000000f0f000000000000000000aaaaa002220000000000aaaaa0000000000aaaaaaaaaaaaaaaafaaa000000000000000aaaaaaaaaa000000000000000aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaf0000000f1f00000000000000000000000000000000f000000000000
-- 028:0000000000000000f0000000fff000000000000000000aaaaa000000000000000aaaaa0000000000aaaaaaaaaaaaaaaaaaaa000000000000000aaaaaaaaaa000000000000000aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaf0000000fff0fff0000000000000000022000000000f000000000000
-- 029:0000000000110000f000000000f000000000000000000aaaaa000000000000000aaaaa0000000000aaaaaaaaaaaaaaaa11aa000000000000000aaaaaaaaaa000000000000000aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaaaaa0000000fff0f0000000000000000000002000000000000000000000
-- 030:00000000010000000000000000f0000000000000000ffaaaaa000000000000000aaaaa0000000000aaaaaaaaaaaaaaaaaa1a000000000000000aaaaaaaaaa000000000000000aaaaaaaaaaaaaaaaaaaa0000000000aaaaaaaaaaaa11a00000000ff0ff000000000000000000020000000111000000000000
-- 031:00000000011100fff00000000000000000000000000f0f00000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000ff00000000000000000fff000000000100000002ff000f00000000000000000200000000001000000000000
-- 032:00000000010100f000000000fff0000000000000000fff0000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000f000000000000000000f00000000100000000fff0ff000000000000000000222000000010000000000000
-- 033:00000000011100ff00000000f000000000000000000f0f000000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000000000000f0000000000000000000f00000001000000000fff000000000000000000000000000000100000000000000
-- 034:0000000000000000f0000000ff00000000000000000fff00000000000000000000000000000000000000000000000000000000000000000ff000000000000000000000000000000000000000000f000000000000000000000000001110000000f1f00ff00000000000000000000000000100000000000000
-- 035:00000000022200ff0000000000f00000000000000000000000000000000000000000000000000000000000000000000022000000000000f000000000000000000000000000000000000000000ff0000000000000000011000000000000000000fff0f0000000000000000000000000000000000000000000
-- 036:000000000200000000000000ff00000000000000000fff000000000000000000000000000000000000000000000fff0000200000000000fff000000000000000000000000000000000000000000000000000000000000010000000222000000001f0fff00000000000000000000000000202000000000000
-- 037:0000000002200011100000000000000000000000000f0f000000000000000000000000000000000000000000000f0f0002000000000000f0f0000000000000000000000000000000000000000ff000000000000000000100000000002000000022f0f0f00000000000000000000000000202000000000000
-- 038:0000000000020010100000001100000000000000000fff000000000000000000000000000000000000000000000fff0000200000000000fff000000000000000000000000000000000000000000f0000000000000000001000000002000000001120fff00000000000000000000000000222000000000000
-- 039:000000000220001110000000001000000000000000000f000000000000000000000000000000000000000000000f0f002200000000000000000000000000000000000000000000000000000000f0000000000000000011000000002000000000110000000000000000000000000000000002000000000000
-- 040:000000000000001010000000010000000000000000000f000000000000000000000000000000000000000000000fff0000000000000000111000000000000000000000000000000000000000000f000000000000000000000000002000000000221011000000000000000000000000000002000000000000
-- 041:000000000000001110000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000ff0000000000000000022200000000000000000212000100000000000000000000000000000000000000000
-- 042:0000000000000000000000001110000000000000000110000000000000000000000000000000000000000000000fff00000000000000001100000000000000000000000000000000000000000000000000000000000020200000000000000000122001000000000000000000000000000000000000000000
-- 043:0000000000000022200000000000000000000000000001000000000000000000000000000000000000000000000f0000000000000000000010000000000000000000000000000000000000000111000000000000000022200000000000000000111010000000000000000000000000000000000000000000
-- 044:0000000000000020200000002020000000000000000010000000000000000000000000000000000000000000000ff000000000000000001100000000000000000000000000000000000000000101000000000000000000200000000000000000002011100000000000000000000000000000000000000000
-- 045:0000000000000022200000002020000000f0000000000100000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000111000000000000000000200000000000000000222000000000000000000000000000000000000000000000
-- 046:000000000fff002020000000222000000ff00000000110000000000000000000000000000000000000000000000ff000000000000000002220000000000000000000000000000000000000000001000000000000000000000000000000000000002022200000000000000000000000000000000000000000
-- 047:000000000f0f0022200000000020000000f0000000000000000000000000000000000000000000000000000000000000000000000000002020000000000000000000000000000000000000000001000000000000000000000000000000000000020000200000000000000000000000000000000000000000
-- 048:000000000fff0000000000000020000000f0000000022200000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000200002000000000000000000000000000000000000000000
-- 049:00000000000f000000000000000000000fff000000020200000000000000000000000000000000000000000000c10000000000000000002020000000000000000000000000000000000c00000222000000000000000000000000000000000000200020000000000000000000000000000000000000000000
-- 050:00000000000f000000000000000000000000000000022200000000000000000000000000000000000000000000c11666666666666666666666666666666666666666666666666666660c00000202000000000000000000000000000000000000000020000000000000000000000000000000000000000000
-- 051:000000000000000000000000000000000010000000000200000000000000000000000000000000000000000000c16666666666666666666666666666666666666666666666666666666c00000222000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 052:000000000fff000000000000000000000110000000000200000000000000000000000000000000000000000000c16666666666666666666666666666666666666666666666666666666c00000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 053:000000000f0f000000000000000000000010000000000000000000000000000000000000000000000ff0000000c06666666666666666666666666666666666666666666666666666666c00000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 054:000000000fff00000000000000000000001000000000000000000000000000000000000000000000000f000000c066666666666666666666cc6666666666666666cc666666666666666c00000000000000000000000000000000000000000000000000000000000000000000000000000f0f000000000000
-- 055:000000000f0f0000000000000000000001110000000000000000000000000000000000000000000000f0000000c266666666666666cccc6ccccc66cccc6cccc66ccccc6666666666666c000000000000000000000000000000000000000ff000000000000000000000000000000000000f0f000000000000
-- 056:000000000fff00000000000000000000000000000000000000000000000000000000000000000000000f000000c26666666666666ccc6666cc666c66cc6cc66c66cc666666666666666c00000000000000000000000000000000000000000f00000000000000000000000000000000000fff000000000000
-- 057:0000000000000000000ff0000000000002220000000000000000000000000000000fff00000000000ff0000000c2666666666666666ccc66cc666c66cc6cc66666cc666666666666666c0000000000000000000000000000000000000000f0000000fff0000000000000000000000000000f000000000000
-- 058:000000000111000000000f000000ff0002020000000000000000000000000000000f0f00000000000000000000c26666666666666cccc6666ccc66cccc6cc666666ccc6666666666666c000000000000000000000000000000000000000f00000000f000000000000000000000000000000f000000000000
-- 059:00000000010100000000f000000000f002220000000000000000000000000000000fff000000000000f0000000c06666666666666666666666666666666666666666666666666666666c000000000000000000000000000000000000000fff000000ff000000000000000000000000000000000000000000
-- 060:0000000001110000000f000000000f0000020000000000000000000000000000000f0f00000000000ff0000000c06666666666666666666666666666666666666666666666666666666c00000000000000000000000000000000000000000000000000f00000000000000000000000000ff0000000000000
-- 061:0000000001010000000fff00000000f000020000000000000000000000000000000fff000000000000f0000000c06666666666666666666666666666666666666666666666666666666c000000000000000000000000000000000000000fff000000ff00000000000000000000000000000f000000000000
-- 062:0000000001110000000000000000ff0000000000000000000000000000000000000000000000000000f0000000c0f66666666666666666666666666666666666666666666666666666fc000000000000000000000000000000000000000f00000000000000000000000000000000000000f0000000000000
-- 063:0000000000000000000ff000fff0000000000000000000000000000000000000000fff00000000000fff000000c0fffffffffffffffffffffffffffffffffffffffffffffffffffffffc000000000000000000000000000000000000000ff000000001000000000000000000000000000f00000000000000
-- 064:000000000222000000000f00fff00ff000000000000000000000000000000000000f0f00000000000000000000c0fffffffffffffffffffffffffffffffffffffffffffffffffffffffc00000000000000000000000000000000000000000f00000011000000000000000000000000000fff000000000000
-- 065:0000fff0000200000000f000fff0f00000000000000000000000000000000000000fff00000000000111000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000ff000000001000000000000000000000000000000000000000000
-- 066:0000f00000200000000f0000fff0fff00000000000000000000000000000000000000f000000000000f1000000000f00ff0000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000111000000000000
-- 067:0000ff0002000000000fff00fff0f0f00000000000000000000000000000000000000f00000000000ff000000000f00000f000000000000000000000000000000000002220000000ff00000000000000000000000000000000000000000011000000fff00000000000000000000000000001000000000000
-- 068:000000f00200000000000000fff0fff000000000000000000000000000000000000000000000000001f00000000f00000f000000000000000000000000000000000000202000000000f0000000000000000000000000f0f000000000000100000000f0f00000000000000000000000000010000000000000
-- 069:0000ff000000000000011100ff00000000000000000000000000000000000000000111000000000001f00000000f0000f000000000000000000000000000000000000022200000000f00000000000000000000000000f0f000000000000111000000fff00000000000000000000000000100000000000000
-- 070:000000000000000000010100fff011000000000000000000000000000000000000000100000000000fff000000000ddddddddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000fff000000000000101000000f0f00000000000000000000000000100000000000000
-- 071:0000111000000000000111000ff00010000000000000ff000000000000000000000010000000000002220000000fddddddddddddddddddddddddddddddddddddddddddddddddddddddd000000000000000000000000000f000000000000111000000fff00000000000000000000000000000000000000000
-- 072:000010000000000000000100ff00010000000000000f000000000000000000000001000000000000011200000000ddddddddddddddddddddddddddddddddddddddddddddddddddddddd000000000000000000000000000f00000000000000000000020000000000000000000000000000222000000000000
-- 073:000011000000000000000100fff0001000000000000fff0000000000000000000001000000000000002100000000ddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000000000000000000000000000000000000000222000000fff00000000000000000000000000002000000000000
-- 074:000000100000000000000000f000110000000000000f0f000000000000000000000000000000000002100000000fdddddddddddddddddddddccdddccddddddddddddddddddddddddddd0000000000000000000000000ff0000000000000200000000f0f00000000000000000000000000020000000000000
-- 075:00001f0000000000000222000110000000000000000fff000000000000000000000220000000000002010000000fdddddddddcccddccccddcccccdddddcccddccccdddccccddddddddd000000000000000000000000000f000000000000220000000fff00000000000000000000000000200000000000000
-- 076:0000ff00000000000002020011102220000000000000000000000000000000fff00002000000000001100000000fddddddddccddcdccddcddccdddccdccddcdccddcdcccddddddddddd00000000000000000000000000f0000000000000002000000f0f00000000000000000000000000200000000000000
-- 077:00000f2000000000000222001110202000000000000fff000000000000f000f00000200000000000000000000001ddddddddccddcdccddcddccdddccdccddcdccddcdddcccddddddddd000000000000000000000000000f000000000000220000000fff00000000000000000000000000000000000000000
-- 078:00002f0000000000000202001110222000000000000f0f00000000000ff000ff0002000000000000020200000001dddddddddcccddccccddddcccdccddcccddccddcdccccdddddddddd00f0000000000000000000000ff000000000000000000fff000000000000000000000000000000000000000000000
-- 079:0000fff000000000000222001110002000000000000fff000000000000f00000f002220000000000020200000001ddddddddddddddccddddddddddddddddddddddddddddddddddddddd0ff000000000000000000000000000000000000000000f00011100000000000000000000000000000000000000000
-- 080:00002020000000000000000011000020000000fff00f0f000000000000f000ff0000000000000000022200000001ddddddddddddddddddddddddddddddddddddddddddddddddddddddd00f000000000000000000000001000000000000000000ff0010000000000000000000000000000000000000000000
-- 081:000011100000000000000000222000000fff0000f00fff00000000000fff00000000000000000000000200000001ddddddddddddddddddddddddddddddddddddddddddddddddddddddd00f00000000000000000000001100000000000000000000f011000fff000000000000000000000000000000000000
-- 082:000000100000000000000000222000000f00000f0000000000000000000000f0f000000000000000000200000001fdddddddddddddddddddddddddddddddddddddddddddddddddddddf0fff00000000000000000000001000000000000000000ff000010000f000000000000000000000000000000000000
-- 083:000001000000000000000000222000000ff000f000001000000000000ff000f0f000000000000000000000000002fffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000010000000000000000000000110000f0000000000000000000000000000000000000
-- 084:00001000000000000000000022200000000f00f00001100000000000000f00fff000000000000000000000000001fffffffffffffffffffffffffffffffffffffffffffffffffffffff0fff00000000000000000000011100000000000000000f0f000000f00000000000000000000000000000000000000
-- 085:000010000000000000000000222000000ff00000000010000000000000f00000f0000000000000000000000000002fffffffffffffffffffffffffffffffffffffffffffffffffffff00f0f00000000000000000000000000000000000000000f0f022200f00000000000000000000000000000000000000
-- 086:000000000fff000000000000200000000000001110001000000000000f000000f00000000000000000000000000222000000000000000000000000000f00000000000010100fff000000fff00000000000000000000002200000000000000000fff000200000000000000000000000000000000000000000
-- 087:000022200f0f000000000000000000000fff001010011100000000000fff000000000000000000000000000000022200000000000000000000000000ff0000000000001110000f000000f0f0000000000000000000002000000000000000000000f002000111000000000000000000000000000000000000
-- 088:000020200fff000000000000000000000f0f0011100000000000000000000011100000000000000000000000000222000000000000000000000000000f000000000000fff0000f000000fff0000000000000000000002220000000000000000000f020000001000000000000000000000000000000000000
-- 089:00002220000f000000000000000000000fff0000100222000000000000100000100000000000000000000000000202000000000000000000000000000f00000000000011f0000000000000000000000000000000000020200000000000000000000020000010000000000000000000000000000000000000
-- 090:00002020000f000000000000000000000f0f000010020200000000000110000100000000000000000000000000022200000000000000000000000000fff000000000000f000fff00000010100000000000000000000022200000000000000000110000000100000000000000000000000000000000000000
-- 091:000022200000000000000000000000000fff00000002220000000000001000100000000000000000000000fff000000000000000000000000000000000000000000000f2200f0f00000010100000000000000000000000000000000000000000001000000100000000000000000000000000000000000000
-- 092:000000000f0f00000000000000000000000000222000020000000000001000100000000000000000000000f0f0000000000000000ff0000000000000fff00000000000ff200fff000000111000000000000000000000000000000000000000000100000000000000000000000000000000000000000f0f00
-- 093:000000000f0f00fff000000000000000011100202000020000000000011100000000000000000000000000fff0000000000000000fff000000000000f00000000000002220000f00000000100fff0000000000000000000000000000000000000010000002220000000000000000000000000000000f0f00
-- 094:000000000fff00f000000000000000000101002220000000000000000000000220000000ff00000000000000f0000000000000000fff000000000000ff000000000000ff20000f00000000100f0f0000000000000000000000000000000000001100000000020000000000000000000000000000000fff00
-- 095:000000000f0f00ff0000000000000000011100002000000000000000022200200000000000f0000000000000f0000000000000000fff00000000000000f0000000000022f0000000000000000fff000000000000000000000000000000000000000000000020000000000000000000000000000000000f00
-- 096:000000000fff0000f000000000000ff000010000200000000000000002020022200000000f0000000000000000000000000000000fff000f00000000ff0000000000000f00001100000002200f0f000000000000000000000000000000000000222000000200000000000000000000000000000000000f00
-- 097:00000000000f00ff000000000000f0000001000000000000000000000222002020000000f00000000000000ff000000000000000000f00ff000000000000000000000011f0010000000020000fff000000000000000000000000000000000000202000000200000000000000000000000000000000000000
-- 098:0000000000110000000000000000fff00000000000000000000000000002002220000000fff00000000000f000000000000000000ff0000f0000000001000000000000ff00011100000022200000000000000000000000000000000000000000222000000000000000000000000000000000000000010100
-- 099:0000fff0010000fff00000000000f0f0022200000000000000000000000200f00000000000000000000000fff00000000000000000ff000f00000000110000000000000100010100000020200ff0000000000000000000000000000000000000002000000000000000000000000000000000000000010100
-- 100:000000f0011100f0f00000000000fff0000200000000000000000000000000ff000000000f000000000000f0f0000ddddddddddddddddddddddddddddddddddddddddddddddddddddd002220000f000000000000000000000000000000000000002000000000000000000000000000000000000000011100
-- 101:ff000f00010100fff00000000000000000200000000000000000000000000000f0000000ff000000000000fff000ddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000100
-- 102:00f0fff001110000f00000000000fff0020000000000000000000000000000ff000000000f000000000000000000ddddddddddddddddddddddddddddddddddddddddddddddddddddddd00000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000100
-- 103:0f00fff00f000000f00ff0000000f0f002000000000000000000000000000000000000000f000000000000111000ddddddddddddddddddddddddddddddddddddddddddddddddddddddd000000ff0000000000000000000000000000000000000fff000000000000000000000000000000000000000000000
-- 104:f000fff0022f000000000f000000fff00000000000000000000000000000001110000000fff00000000000101000dddddddddddddddddddddddddddddccddccdddddddddddddddddddd000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000022200
-- 105:fff011f0000200110000f0000000f0f0000000000000000000000000000000101000000000000000000000111000ddddddddddddddddddccccdccddcddddcccccdddddddddddddddddd000000110000000000000000000000000000000000000ff0000000000000000000000000000000000000000020200
-- 106:000000f001210000100f00000000fff0000000000000000000000000000000111000000011000000000000001000dddddddddddddddddcddccdccddcdccddccdddddddddddddddddddd00000000100000000000000000000000000000000000000f000000f0f000000000000000000000000000000022200
-- 107:f0f0110001020001000fff0000000000000000000000000000000000000000001000000000100000000000001000dddddddddddddddddcddccdccddcdccddccdddddddddddddddddddd000000010000000000000000000000000000000000000ff0000000f0f000000000000000000000000000000000200
-- 108:f0f01ff0022100001000000000001010000000000000000000000000000000001000000001000000000000000000ddddddddddddddddddccccddcccddccdddcccdddddddddddddddddd000000001000000000000000000000000000000000000000000000fff000000000000000000000000000000000200
-- 109:fff0f11000010011000ff00000001010000000000000000000000000000000000000000010000000000000222000ddddddddddddddddddddccddddddddddddddddddddddddddddddddd000000110000000000000000000000000000000000000fff00000000f000000000000000000000000000000000000
-- 110:00f0fff00001000000000f0000001110000000000000000000000000000000222000000011100000000000202000ddddddddddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000f00000000f000000000000000000000ff0000000000000
-- 111:00f0f2f0000000222000f00000000010000000000000000000000000000000201000000000000000000000222000ddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000002220000000000000000000000000000000000000f000000000000000000000000000000000f000000000000
-- 112:0000fff00222002020000f0000000010000000000000000000000000000000220000000022200000000000002000fdddddddddddddddddddddddddddddddddddddddddddddddddddddf000000002000000000000000000000000000000000000f000000000110000000000000000000000f0000000000000
-- 113:0100022002020022200ff00000000000000000000000000000000000000000102000000020200000000000002000fffffffffffffffffffffffffffffffffffffffffffffffffffffff000000020000000000000000000000000000000000000f0000000010000000000000000000000000f000000000000
-- 114:110011000222000020000000000002200000000000000000000000000000002200000000222000000000000ff000fffffffffffffffffffffffffffffffffffffffffffffffffffffff000000200000000000000000000000000000000000000000000000111000000000000000000000ff0000000000000
-- 115:01002210020200002001110000002000000000000000000000000000000000000000000000200000000000f000000fffffffffffffffffffffffffffffffffffffffffffffffffffff0000000200000000000000000000000000000000000000110000000101000000000000000000000000000000000000
-- 116:010021200222000000000100f0f02220000000000000000000000000000000222000000000200000000000fff0000000000000000000002220001000000000000000000000000000111000000000000000000000000000000000000000000000001000000111000000000000000000000110000000000000
-- 117:111012200000000000001000f0f02020000000000000000000000000000000002000000000000000000000f0f00000000000000000000000f000010000000000000000000000000000100000000000000000000000000000000000000000000001000000000000fff0000000000000000001000000000000
-- 118:000011100000000000010000fff02220000000000000000000000000000000020000000000000000000000fff0000000000000000000000f000110000000000000000000000000000100000000000000000000000000000000000000000000001000000002220000f0000000000000000010000000000000
-- 119:202000f00000000000010000f0f0000000000000000000000000000000000020000000000000000000000000000000000000000000000000f0000000000000000000000000000000100000000000000000000000000000000000000000000000111000000202000f00000000000000000001000000000000
-- 120:202022200000000000000000fff0000000000000000000000000000000000020000000000000000000000011100ff00000000000000000ff0002200000000000000000000000000010000000000000000000000000000000000000000000000000000000022200f00000000000000000011000fff000ff00
-- 121:222020200000000000020200f0f00000000000000000000000000000000000000000000000000000000000fff0000f0000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000020200000020200f0000000000000000000000000f00f0000
-- 122:002022200000000000020200fff00000000000000000000000000000000000000000000000000000000000f1f000f000000000000000001110002000000000000000000000000000220000000000000000000000000000000000000000000000202000000222000000000000000000000222000f000fff00
-- 123:002020200000000000022200f0f00000000000000000000000000000000000000000000000000000000000fff00f0000000000000000001010000200000000000000000000000000002000000000000000000000000000000000000000000000222000000000001110000000000000000ff200f0000f0f00
-- 124:000022200000000000000200f1f0000000000000000000000000000000000000000000000000000000000011f00fff0000000000000000111002200000000000000000000000000002000000000000000000000000000000000000fff000000000200000000000001000000000000000022f00f0000fff00
-- 125:0000f0f0000000000000020011f0000000000000000000000000000000000000000000000000000000000000f0000000000000000000001010000000000000000000000f000000000020000000000000000000000000000000000000f00000000020000000000001000000000000000000f2000000000000
-- 126:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000100000000000000000000f00ff000fff00
-- 127:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000001000000000000000000ff00000f00f0000
-- 128:0ff00000000000000f00000000f000f00000000000000000000000000000f00000ff000ff0f0ff00ff00f000000000f0000000000000f000000000f000000000000ff00ff0ff0000fff00ff0ff00000f0fff00000ff00ff00f0000f000000000000000000000000000000000000000000000000f000ff000
-- 129:f000f0f00ff0ff00fff00ff00ff000ff00f0f000f0f0fff00f00f0f0ff00000ff000f0f0f0000f000f0000ff000f00000ff0000ff00ff0f0f0000f000f00f0f000f000f000f0f000f000f0f000f000f00f000ff000f000f000f000fff0000000000000000000002220000000000000000fff00f000000f00
-- 130:f000ff00f0f00ff00f00f0f0f0f000f0f0f0f000ff00fff0f0f0ff000ff0f0ff000f00fff0f00f000f00f0f0f0f0f0f0ff0000f0f0f0f0f0f000fff0f0f0ff0000f0f00f00f0f000ff00f0f00f0000f00ff000ff00f000f000f00011f0000000000000000000000020000000000000000f0f00fff00ff000
-- 131:f000f000ff00f0f00f00ff00f0f000f0f00ff000f000f0f0f0f0f000f0f0f000f0f000f000f00f000f00f0f0f0f0f0f000f000ff00f0f0f0f0000f00f0f0f00000f0f000f0f0f00000f0f0f000f000f00f000f0f00f000f000f000ff10000000000000000000000200000000ff0000000fff00fff0000000
-- 132:0ff0f0000ff0fff000f00ff00ff000ff0000f000f000f0f00f00f000fff0f0ff00fff00ff0f0fff0fff0f0f0f00f00f0ff00f00ff00ff00ff0000f000f00f000000ff0ff00ff0000ff00ff00ff00000f0f000fff0fff0fff0f000001f000000000000000000000200000000000f000000f0f00f1f0001000
-- 133:00000000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000020000000000f0000000fff00fff0011000
-- 134:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000000000000000000000000f00000f00000000f0011f0001000
-- 135:01000000000000fff00000000120000000000000f00000000000000001100000000fff00000000000000001110010000000000000f0f0000000000000000000000f000f00000000000000000000000000000000000000000000000fff00000000000000000000000000ff000ff0000000ff10000f0001000
-- </SCREEN>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

