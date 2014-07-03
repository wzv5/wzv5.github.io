hitTest = (o1, o2) ->
	# 保证o1在o2左边
	if o1.x > o2.x
		[o1, o2] = [o2, o1]
	if o1.x + o1.w <= o2.x
		return false

	# 再保证o1在o2上面
	if o1.y > o2.y
		[o1, o2] = [o2, o1]
	return o1.y + o1.h > o2.y

class Game
	constructor: () ->
		@enemy = []
		@timerID = 0
		@timerID2 = 0
		@keyStatus = [false, false, false, false]
		@keyAttack = false

	init: (element) ->
		@w = element.width
		@h = element.height
		@canvas = element.getContext("2d")
		@player = new Plane(30, 30, 100, 50, true)
		@player.x = (@w - @player.w) / 2
		@player.y = (@h - @player.h) * 0.8
		window.addEventListener("keydown", (e) =>
			key = e.keyCode
			# ↑: 38
			# ↓: 40
			# ←: 37
			# →: 39
			if (37 <= key <= 40)
				@keyStatus[key-37] = true
			else if (key == 32)  # 空格，攻击
				@keyAttack = true
		)
		window.addEventListener("keyup", (e) =>
			key = e.keyCode
			if (37 <= key <= 40)
				@keyStatus[key-37] = false
			else if (key == 32)
				@keyAttack = false
		)
		@canvas.clearRect(0, 0, @w, @h);
	
	flushEnemy: () =>
		@enemy = (e for e in @enemy when e.y < @h)
		if (@enemy.length < 5)
			if (Math.random() > 0.5)
				e = new Plane(30, 30, 100, 1)
				e.x = Math.random() * (@w - e.w)
				e.y = -e.h
				@enemy.push(e)
		for i in @enemy
			i.cleanBullet(@h)
			if (Math.random() > 0.5)
				i.fire()
		@player.fire() if @keyAttack
		@player.cleanBullet(@h)

	start: () ->
		@timerID = setInterval(@onTimer, 30)
		@timerID2 = setInterval(@flushEnemy, 300)
	pause: () ->
		clearInterval(@timerID)
		clearInterval(@timerID2)
		@timerID = 0
		@timerID2 = 0
	stop: () ->
		@pause()
	onTimer: () =>
		@canvas.clearRect(0, 0, @w, @h);

		# 移动敌人及其子弹，并绘制
		for i in @enemy
			i.y += 5
			i.draw(@canvas)
			for j in i.bullet
				j.y += j.speed

		# 移动玩家及其子弹，并绘制
		@player.x -= 5 if @player.x > 0 and @keyStatus[0]
		@player.y -= 5 if @player.y > 0 and @keyStatus[1]
		@player.x += 5 if @player.x + @player.w < @w and @keyStatus[2]
		@player.y += 5 if @player.y + @player.h < @h and @keyStatus[3]
		for i in @player.bullet
			i.y -= i.speed
		@player.draw(@canvas)

		# 碰撞判定，碰撞一击致命
		for i in @enemy
			if (@player.hitTest(i))
				@onGameOver()
				return

		# 子弹判定
		for i in @enemy
			for j in i.bullet
				if j.hitTest(@player)
					@player.hp -= j.attack
					console.log("玩家被攻击：#{j.attack}，#{@player.hp}")
					j.aaa = true
			i.bullet = (o for o in i.bullet when o.aaa != true)

		for i in @player.bullet
			for j in @enemy
				if i.hitTest(j)
					j.hp -= i.attack
					i.aaa = true
		@player.bullet = (o for o in @player.bullet when o.aaa != true)

		if @player.hp <=0
			@onGameOver()
			return

		@enemy = (e for e in @enemy when e.hp > 0)
	onGameOver: () ->
		@stop()
		alert "Game Over"
		

class Plane
	constructor: (@w, @h, @hp, @attack, @isPlayer = false) ->
		@x = 0
		@y = 0
		@bullet = []
		@hp0 = @hp

	hitTest: (other) ->
		return hitTest(this, other)

	fire: () ->
		o = new Buttle(@x+@w/2, @y, @attack, 10)
		o.y += @h if not @isPlayer
		@bullet.push(o)

	cleanBullet: (maxh) ->
		@bullet = (o for o in @bullet when o.y < maxh)

	draw: (c) ->
		c.save()
		a = parseInt(@hp*100/@hp0)
		s = "#{a}%"
		if (@isPlayer)
			c.fillStyle = "#ff0000"
			#s = "玩家"
		else
			c.fillStyle = "#0000ff"
			#s = "敌人"
		c.fillRect(@x, @y, @w, @h)
		c.strokeRect(@x, @y, @w, @h);
		c.textBaseline = "top"
		c.font="10px Arial";
		c.textAlign="center";
		c.fillText(s, @x+@w/2, @y+@h+2);
		c.restore()
		for i in @bullet
			i.draw(c)

	onAttack: (o) ->

class Buttle
	constructor: (@x, @y, @attack, @speed) ->

	hitTest: (other) ->
		return other.x < @x < other.x + other.w and other.y < @y < other.y + other.y

	draw: (c) ->
		c.save()
		c.fillStyle = "#ff00ff"
		c.beginPath()
		c.arc(@x, @y, 5, 0, Math.PI*2, true)
		c.fill()
		c.restore()

window.Game = Game