-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

math.randomseed(os.time())

---@alias frames number

W=240
H=136
F=0

function TIC()
	local left=btnp(2)
	local right=btnp(3)

	if left then Screen:move(5,0)
	elseif right then Screen:move(-5,0)
	else Screen:reset() end

	Screen:update()

	cls(13)
	spr(1+F%60//30*2,W/2,H/2,14,3,0,0,2,2)
	print("HELLO WORLD!",84,84)
	F=F+1
end

---@class Screen
Screen={
	memX=0x3FF9,
	memY=0x3FF9+1,
	x=0,
	y=0,
	update=function(s)
		poke(s.memX,s.x)
		poke(s.memY,s.y)
	end,
	---@param x number
	---@param y number
	move=function(s,x,y)
		s.x=x
		s.y=y
	end,
	reset=function(s)
		s:move(0,0)
	end,
	---@param t frames Shake duration
	---@param i number Shake intensity
	---@returns Monoid
	shaker=function(s, t, i)
		return MonoidFactory.gen(t, function()
			s.x=math.random(-i,i)
			s.y=math.random(-i,i)
		end)
	end
}

---@class Monoid
---@field t frames Time to death
---@field f fun(s: Monoid) Change function for Monoid

---@class MonoidFactory
MonoidFactory={
	---@type {[string]: Monoid}
	monoids={},
	---@param t frames Duration of monoid (in frames)
	---@param f fun()
	gen=function(t,f)
		---@type Monoid
		return {
			t=t,
			f=function(s)
				s.t=s.t-1
				f()
			end
		}
	end,
	---@param mf MonoidFactory
	run=function(mf)
		for name,m in ipairs(mf.monoids) do
			if m.t<0 then mf.monoids[name]=nil
			else m:f() end
		end
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

