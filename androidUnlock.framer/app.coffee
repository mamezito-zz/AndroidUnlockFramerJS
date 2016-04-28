# Import file "androidUnlock" (sizes and positions are scaled 1:3)
# sketch file by @Hanii
# http://www.sketchappsources.com/free-source/1905-android-m-ui-kit-sketch-app-freebie-resource.html
# pointer module by #jordandobson

sketch = Framer.Importer.load("imported/androidUnlock@3x")
{Pointer} = require 'Pointer'

Utils.globalLayers sketch

homescreen.opacity=0
wrongkey.opacity=0

background = new BackgroundLayer
	backgroundColor: "rgba(0,0,0,1)"

bg.opacity=0.7

area= new Layer
	width: Screen.width
	height: Screen.height
	backgroundColor: "null"
area.style=
	"stroke":"rgb(255,255,255)"
area.visible=false


# variables
dots=[]
pointX=0
pointY=0

#array that will hold sequence of indexes of connected dots
clicked=[]
savedLine=""

dotMargin=Screen.width/3.6

panoffset=0

#sequence of dots used to unlock the phone(starting from left to right, from top to bottom, 0 is first dot)
key=[6,3,0,4,2,5,8]
locked=true
candraw=false
started=false

# array of some sketch layers, so i can operate with them in one cycle
lockScreen=[voice,camera,sbar,bg,datetime]




#functions
#function is checking whether variable exist in array, if doesnt exist, we are pushing variable to array
pushNewinArray=(a,array)->
	unique=true
	for obj in array
		if obj==a
			unique=false
	if unique
		array.push a
		return true
	else return false


#here all magic with SVG happens
updatePoints = (event, layer,x,y) ->
	# Get Pointer Position
	pointX=x
	pointY=y
	pos = Pointer.screen event, layer
	
	#we are checking whether current location of pointer overlaps one of the not connected dots
	for dot,i in dots
		if pos.x>dot.minX*0.95 and pos.x<dot.maxX*1.05 and pos.y>dot.minY*0.95 and pos.y<dot.maxY*1.05
		
			#if it overlaps dot that is not connected, we are doing new connection between dots, saving all current lines, and creating new lines with the beginning in center of last connection dot
			if (pushNewinArray i, clicked)
				savedLine=savedLine+'<line x1="'+pointX+'" y1="'+pointY+'" x2="'+dot.midX+'" y2="'+dot.midY+'" style="stroke-width:6" />'
				pointX=dot.midX
				pointY=dot.midY
				dot.states.switch("active")	

				
	currentLine='<line x1="'+pointX+'" y1="'+pointY+'" x2="'+pos.x+'" y2="'+pos.y+'" style="stroke-width:2" />'
	svg=currentLine+savedLine
	area.html='<svg height="'+Screen.height+'" width="'+Screen.width+'">'+svg+'
</svg>'



#we are creating our dots for lock screen
for i in[0...3 ]
	for j in [0...3]
		dot = new Layer
			y: Screen.height/1.9+dotMargin*i
			x: Screen.width/2+(dotMargin*(j-1))-15
			width: 30
			height: 30
			borderRadius: 100
			backgroundColor: "white"
		dot.states.animationOptions =curve: "spring(60, 30, 100)"
		dot.states.add
			active:
				scale:1.2
			error:
				scale:1.2
				backgroundColor: "red"
		#pusing them to array dots, so we can work with our dots in a cycle	
		dots.push dot

#we are hiding dots and moving them more to bottom from default state
for dot in dots
	dot.opacity=0
	dot.y=dot.y+300		

#this cycle is used to trigger svg line drawing event when we touch first dot
for dot,z in dots
	dot.customId = z
	dot.on Events.TouchStart, ->
		started=true
		@.states.switch("active")
		
		#we are adding index of the clicked dot to array of clicked dots
		pushNewinArray @.customId, clicked
		candraw=true
		pointX=this.midX
		pointY=this.midY

#when we are doing Pan to top on whole screen, we are hiding some elements according to how its done on real android, so opacity is modulated on pan offset
mobile.onPan (event) ->
	if locked
		voice.opacity=Utils.modulate(event.offset.y,[0,-200],[1,0],true)
		camera.opacity=Utils.modulate(event.offset.y,[0,-200],[1,0],true)
		sbar.opacity=Utils.modulate(event.offset.y,[-200,-300],[1,0],true)
		bg.opacity=Utils.modulate(event.offset.y,[-100,-300],[0.7,0.4],true)
		datetime.opacity=Utils.modulate(event.offset.y,[-100,-300],[1,0],true)
		datetime.scale=Utils.modulate(event.offset.y,[-100,-300],[1,0.6],true)
	
		#saving offset to variable
		panoffset=event.offset.y

#when we are finishing pan event on screen, we are checking offset
mobile.onPanEnd (event) ->
	if locked
		#if its big enough we are showing graphic lock screen
		if panoffset<-300
			area.visible=true
			lock1.animate
				properties:
					opacity: 0
				time:0.1
			
			#using array of dots we are moving them up to screen with changing of opacity
			for dot,i in dots
				dot.animate
					properties:
						opacity:1
						y:dots[i].y-300
					time:0.2
					#delaying each new row on 0.1 of second
					delay:(Math.floor i/3)*0.1
						
		#if offset is small we are returning our locked screen to default view
		else
			for layer in lockScreen
				layer.opacity=1
				datetime.scale=1
				bg.opacity=0.7

#when we are touching the whole screen area, if one of the dots we already clicked, we are triggering draw svg function
area.on Events.TouchMove, (event, layer) ->
	if candraw
		updatePoints event, layer,pointX,pointY


#when we are finishing touch event on whole are, we are deleting unconnected line
area.on Events.TouchEnd, ->
	candraw=false
	svg=savedLine
	area.html='<svg height="'+Screen.height+'" width="'+Screen.width+'">'+svg+'
</svg>'
	
	#comparing unlock key array with array of indexes of clicked dots
	is_same = key.length == clicked.length and key.every((element, index) ->
		element == clicked[index]
	)
	#if they are the same, we are hiding our dots and opening unlocked home screen of the phone
	if is_same
		for dot,i in dots
			dot.animate
				properties:
					opacity:0
					y:dots[i].y-400
				time:0.2
				delay:(Math.floor i/3)*0.1
		area.visible=false
		locked=false
		panoffset=0
		homescreen.animate
			properties:
				opacity: 1
			time:0.2
			delay:0.3
		sbar.animate
			properties:
				opacity: 1
			time:0.2
			delay:0.3
		bg.animate
			properties:
				opacity: 1
			time:0.2
			delay:0.3
			
	#if combination is wrong, we are highlighting wrong path with red color, and restarting unlocking functionality, killing all SVG that was added to area.html
	else
		if started
			Utils.delay 2.5, ->
				area.style="stroke":"rgb(255,255,255)"
				for dot in dots
					dot.states.switch("default")
				area.html=savedLine=currentLine=""
				clicked=[]
				candraw=false
				started=false
			Utils.delay 4.5, ->
				wrongkey.animate
					properties:
						opacity: 0
					time:0.2
			wrongkey.animate
				properties:
					opacity: 1
				time:0.2
				delay:0.3
			area.style=
				"stroke":"rgb(255,0,0)"
			for i in clicked
				dots[i].states.switch("error", time: 0.1, curve: "ease")


