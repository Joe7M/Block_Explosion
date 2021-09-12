' SmallBASIC 12.23
' "Block Explosion" by Joerg Siebenmorgen, 2021

delay(100)

if(rinstr(SBVER,"Android"))
  IS_ANDROID = true
else
  w=window()
  w.setSize(680, 850)
  IS_ANDROID = false
endif

'IS_ANDROID = true

      SCREEN_X = XMAX
      SCREEN_Y = YMAX
const BOARD_X = 8
const BOARD_Y = 14
const INFO_X = 4
      PIXELSIZE = 1
      TILESIZE = 16
const FONTSIZE = textheight("Yy")*1.1
const GAME_COLUMN_IS_MOVING = 0
const GAME_COLUMN_IS_FALLING = 1
const GAME_REMOVE_BLOCKS = 2
const GAME_EXPLODE_BLOCKS = 3
const GAME_FALL_BLOCKS = 4
const GAME_PAUSE = 5
const GAME_END = 6
const GAME_SETTINGS = 7
const GAME_COLUMN_FALLING_SPEED = 1
const GAME_COLUMN_SPEED = 1
const NUMBER_OF_MAX_SPECIAL_BLOCKS = 3
const NUMBER_OF_MAX_BLOCKS = 6
      NUMBER_OF_BLOCKS = NUMBER_OF_MAX_BLOCKS + NUMBER_OF_MAX_SPECIAL_BLOCKS
const NUMBER_OF_BLOCKS_ANIMATIONS = 1
const NUMBER_OF_BLOCKS_EXPLOSION_ANIMATIONS = 4
const BLOCKS_EXPLOSION_ANIMATION_SPEED = 0.02
      BLOCKS_EXPLOSION_OFFSET = 0
      BlocksExplosionAnimationFrame = 0
      NUMBER_OF_TILES = (NUMBER_OF_MAX_BLOCKS + NUMBER_OF_MAX_SPECIAL_BLOCKS) * NUMBER_OF_BLOCKS_ANIMATIONS
      NUMBER_OF_TILES = NUMBER_OF_TILES + NUMBER_OF_BLOCKS_EXPLOSION_ANIMATIONS
  dim Tiles[NUMBER_OF_TILES]
const BOARD_BLOCKS = 0
const BOARD_REMOVE = 1
const BOARD_MICROSTEP = 2
const BOARD_ANIMATION_OFFSET = 3
const BOARD_ANIMATION_FRAME = 4
  dim Board[BOARD_X,BOARD_Y,4]
  dim Column[2]
  dim NextColumn[2]
  dim ColorPalette[31]



'Init Game Settings
Randomize(ticks())
GAME_IS_RUNNING = true
SoundOnOff = true
GameStateTemp = 0
GameStateTempPause = 0
Level = 1
StartLevel = 1
Highscore = 0
BlocksTotal = 0
Speed = GAME_COLUMN_SPEED * 0.02
TimeStep = 0
MicroStep = 0
MouseX = 0
MouseY = 0
PointsTotal = 0
PointsTemp = 0
PointsMultiplier = 1
NextColumn[0] = int(rnd() * NUMBER_OF_BLOCKS) + 1
NextColumn[1] = int(rnd() * NUMBER_OF_BLOCKS) + 1
NextColumn[2] = int(rnd() * NUMBER_OF_BLOCKS) + 1
ColumnPositionX = 4
ColumnPositionY = 0
ColumnPositionNewX = -1
ColumnPositionNewY = -1

'Init
LoadSettings()
InitScreen()
InitButtonClass()
CreateColorPalette()
CreateBoard()
CreateButtons()
CreateTiles()
CreateColumn()
DrawEverything()

definekey(32, Callback_Key_SPACE)
definekey(13, Callback_Key_RETURN)
definekey(0xFF04, Callback_Left)
definekey(0xFF05, Callback_Right) 
definekey(0xFF09, Callback_Cycle) 'Up
definekey(0xFF0A, Callback_Cycle) 'Down
definekey(112, Callback_Pause)    'P

GAME_STATE = GAME_END
'Start game loop
while GAME_IS_RUNNING
  
  StartTime = ticks()
  
  Select case GAME_STATE
    case GAME_COLUMN_IS_MOVING
      DrawColumn()
      ButtonClass.DoEvents()      
    case GAME_COLUMN_IS_FALLING
      DrawColumn()
      ButtonClass.DoEvents()
    case GAME_REMOVE_BLOCKS
      RemoveBlocks()
      DrawScore()
    case GAME_EXPLODE_BLOCKS
      ExplodeBlocks()
      DrawBoard()
      DrawScore()
    case GAME_FALL_BLOCKS
      FallBlocks()
      DrawBoard()
    case GAME_PAUSE
      ButtonClass.DoEvents()
    case GAME_END
      ButtonClass.DoEvents()
    case GAME_SETTINGS
      GameSettings() 
      ButtonClass.DoEvents()
  end select

  showpage
  EndTime = ticks()
  TimeStep = EndTime - StartTime
  at 1,SCREEN_Y - 4*FONTSIZE: print TimeStep;"ms     "
  'print Status 
  
  if(TimeStep < 20)
    delay(20 - TimeStep)
    TimeStep = 20
  endif
wend


Rem --------------------------------------------

sub PlaySoundExplosion()
  local A 
  if(SoundOnOff)
    A = [213,381,446,251,443,270,120,236,347,331,101,371,125,434,335,401,235,392,156,356,311,338,266,251,462,331,216,311,277,112]
    for ii = 0 to 29
      sound A[ii],10, (30-ii)/30 * 100 BG
    next
  endif
end sub

sub PlaySoundCycle()
  local A 
  if(SoundOnOff)
    A = [3000,1500,1000,750,600,500]
      for ii = 0 to 5
        sound A[ii],10, (5-ii)/5 * 100 BG
      next
   endif
end sub

sub PlaySoundLeftRight()
  local A
  if(SoundOnOff)
    A = [100,200,300,400,500,600]
    for ii = 0 to 5
	  sound A[ii],10 BG
    next
  endif
end sub

sub PlaySoundTouchdown()
  local A
  if(SoundOnOff)
    A = [400,600,450,550,480,500]
    for ii = 0 to 5
	  sound A[ii],20 BG
    next
  endif
end sub

sub LoadSettings()
  local dim SaveArray[3]
  
  if(exist("settings.dat"))
    tload "settings.dat", SaveArray
    Highscore = val(SaveArray[0])
    NUMBER_OF_BLOCKS = val(SaveArray[1])
    StartLevel = val(SaveArray[2])
    SoundOnOff = val(SaveArray[3])
  endif
end sub

sub SaveSettings()
    local dim SaveArray[3]
	SaveArray[0] = Highscore
    SaveArray[1] = NUMBER_OF_BLOCKS
    SaveArray[2] = StartLevel
    SaveArray[3] = SoundOnOff
    tsave "settings.dat", SaveArray
end sub

sub InitButtonClass()

  dim Button

  Button.x1 = 0
  Button.y1 = 0
  Button.x2 = 0
  Button.y2 = 0
  Button.text = ""
  Button.active = true
  Button.cooldown = 0
  Button.Draw = @ButtonDraw()
  dim Button.Callback

sub ButtonDraw()
  local text_x, text_y
  
  rect self.x1+PIXELSIZE, self.y1+PIXELSIZE, self.x2 - PIXELSIZE, self.y2 - PIXELSIZE, ColorPalette[11] filled

  rect self.x1 + 2*PIXELSIZE, self.y1, self.x2 - 2*PIXELSIZE, self.y1 + PIXELSIZE, ColorPalette[13] filled
  rect self.x1 +   PIXELSIZE, self.y1, self.x1 + 2*PIXELSIZE, self.y1 + PIXELSIZE, ColorPalette[12] filled
  rect self.x2 - 3*PIXELSIZE, self.y1, self.x2 - 2*PIXELSIZE, self.y1 + PIXELSIZE, ColorPalette[12] filled
  
  rect self.x1, self.y1 + 2*PIXELSIZE, self.x1 + PIXELSIZE, self.y2 - 3*PIXELSIZE, ColorPalette[13] filled
  rect self.x1, self.y1 +   PIXELSIZE, self.x1 + PIXELSIZE, self.y1 + 2*PIXELSIZE, ColorPalette[12] filled
  rect self.x1, self.y2 - 3*PIXELSIZE, self.x1 + PIXELSIZE, self.y2 - 2*PIXELSIZE, ColorPalette[12] filled
 
  rect self.x2 -   PIXELSIZE, self.y1 +   PIXELSIZE, self.x2              , self.y2 - 2*PIXELSIZE, ColorPalette[10] filled
  rect self.x1 +   PIXELSIZE, self.y2 -   PIXELSIZE, self.x2 - 2*PIXELSIZE, self.y2              , ColorPalette[10] filled 
  rect self.x2 - 2*PIXELSIZE, self.y2 - 2*PIXELSIZE, self.x2 -   PIXELSIZE, self.y2 -   PIXELSIZE, ColorPalette[10] filled

  text_x = self.x1 + (self.x2 - self.x1 - Textwidth(self.text))/2
        text_y = self.y1 + (self.y2 - self.y1 - Textheight(self.text))/2
  color ColorPalette[7], ColorPalette[11]
  at text_x, text_y: print self.text
end sub

	dim ButtonClass.Buttons

	ButtonClass.NumberOfButtons = 0
	ButtonClass.LastTime = ticks()
	ButtonClass.AddButton = @ButtonClassAddButton
	ButtonClass.DrawButtons = @ButtonClassDrawButtons
	ButtonClass.ChangeText = @ButtonClassChangeText
	ButtonClass.SetActive = @ButtonClassSetActive
	ButtonClass.DoEvents = @ButtonClassDoEvents

	func ButtonClassAddButton(x,y,w,h,text, Callback)
		local temp
		temp = Button
		temp.x1 = x
		temp.y1 = y
		temp.x2 = x + w
		temp.y2 = y + h
		temp.text = text
		temp.Callback = CallBack
		self.Buttons << temp
		self.NumberOfButtons++
		ButtonClassAddButton = self.NumberOfButtons - 1        
	end

	sub ButtonClassDrawButtons()
		local ii, temp
		
		for ii = 0 to self.NumberOfButtons - 1
			temp = self.Buttons[ii]
			if(temp.active)
				temp.Draw()
			endif
		next
	end sub

	sub ButtonClassChangeText(Button, Text)
		self.Buttons[Button].text = text
	end sub
	
	sub ButtonClassSetActive(Button, s)
		if(s == false)
			self.Buttons[Button].active = false
		else
			self.Buttons[Button].active = true
		endif
		
	end sub

sub ButtonClassDoEvents()
  local ii, pressed, TimeStep

  'Do cooldown of buttons to prevent double click
  for ii = 0 to self.NumberOfButtons - 1
    if(self.Buttons[ii].cooldown > 0)
      TimeStep = ticks() - self.LastTime
      self.LastTime = ticks()
      self.Buttons[ii].cooldown = self.Buttons[ii].cooldown - TimeStep
    endif
  next

  'Detect mouse click and call callbacks of the buttons     
  if(Pen(3))
    MouseX = Pen(1)
    MouseY = Pen(2)

    for ii = 0 to self.NumberOfButtons - 1
      if(self.Buttons[ii].cooldown <= 0 and self.Buttons[ii].active)
        'AABB Collision Detection
        pressed = 1
        if(MouseX < self.Buttons[ii].x1)
          pressed = 0
        elseif(MouseX > self.Buttons[ii].x2)
          pressed = 0
        elseif(MouseY < self.Buttons[ii].y1)
          pressed = 0
        elseif(MouseY > self.Buttons[ii].y2)
          pressed = 0
        endif
        'Call Button Callback
        if(pressed == 1)
          self.Buttons[ii].cooldown = 200
          self.LastTime = ticks()
          call self.Buttons[ii].Callback
        endif
      endif
    next
  endif
end sub

end sub

'######################

sub Callback_Left()
  if(ColumnPositionX > 0) 
	if(Board[ColumnPositionX-1,ColumnPositionY,BOARD_BLOCKS] == 0)
	  if(Board[ColumnPositionX-1,ColumnPositionY+1,BOARD_BLOCKS] == 0)
		if(Board[ColumnPositionX-1,ColumnPositionY+2,BOARD_BLOCKS] == 0)
		  if(Board[ColumnPositionX-1,ColumnPositionY+3,BOARD_BLOCKS]==0)
		    PlaySoundLeftRight()
		    ColumnPositionNewX = ColumnPositionX - 1
		  endif
		endif
	  endif
	endif 
  endif
end sub

sub Callback_Right()
  if(ColumnPositionX < BOARD_X)
	if(Board[ColumnPositionX+1,ColumnPositionY,BOARD_BLOCKS] == 0)
	  if(Board[ColumnPositionX+1,ColumnPositionY+1,BOARD_BLOCKS] == 0)
		if(Board[ColumnPositionX+1,ColumnPositionY+2,BOARD_BLOCKS] == 0)
		  if(Board[ColumnPositionX+1,ColumnPositionY+3,BOARD_BLOCKS]==0)
		    PlaySoundLeftRight()
			ColumnPositionNewX = ColumnPositionX + 1
		  endif
		endif
	  endif
	endif 
  endif
end sub


sub Callback_Key_SPACE()
  if(GAME_STATE == GAME_COLUMN_IS_MOVING)
    Callback_Drop()
  elseif(GAME_STATE == GAME_END)
	Callback_GameStart()
  endif
end

sub Callback_Key_RETURN()
  if(GAME_STATE == GAME_END)
	Callback_GameStart()
  endif	
end



sub Callback_Drop()
	GAME_STATE = GAME_COLUMN_IS_FALLING
    Speed = GAME_COLUMN_FALLING_SPEED
end sub

sub Callback_Cycle()
  PlaySoundCycle()
  CycleColumn()
end sub

sub Callback_Pause()
  if(GAME_STATE = GAME_PAUSE)
    GAME_STATE = GameStateTempPause
  else
    GameStateTempPause = GAME_STATE
    GAME_STATE = GAME_PAUSE
  endif
end sub

sub Callback_SettingsSound()
  SoundOnOff = not SoundOnOff
  if(SoundOnOff) then 
    ButtonClass.ChangeText(B_SettingsSound, "ON")
  else
    ButtonClass.ChangeText(B_SettingsSound, "OFF")
  endif
  ButtonClass.DrawButtons()
end sub

sub Callback_GameStart()
  ButtonClass.SetActive(B_GameStart, false)
  Level = StartLevel
  BlocksTotal = 0
  Speed = GAME_COLUMN_SPEED * 0.02
  MicroStep = 0
  PointsTotal = 0
  PointsTemp = 0
  PointsMultiplier = 1
  NextColumn[0] = int(rnd() * NUMBER_OF_BLOCKS) + 1
  NextColumn[1] = int(rnd() * NUMBER_OF_BLOCKS) + 1
  NextColumn[2] = int(rnd() * NUMBER_OF_BLOCKS) + 1
  GameStateTemp = 0
  CreateBoard()
  CreateColumn()
  DrawEverything()
end sub

sub Callback_Menu()
  local xx,yy
  GameStateTemp = GAME_STATE
  GAME_STATE = GAME_SETTINGS
  if(IS_ANDROID)
    ButtonClass.SetActive(B_Drop, false)
    ButtonClass.SetActive(B_Cycle, false)
    ButtonClass.SetActive(B_Left, false)
    ButtonClass.SetActive(B_Right, false)
  endif
  ButtonClass.SetActive(B_Menu, false)
  ButtonClass.SetActive(B_Pause, false)
  ButtonClass.SetActive(B_GameStart, false)
  ButtonClass.SetActive(B_SettingsLevelUp, true)
  ButtonClass.SetActive(B_SettingsLevelDown, true)
  ButtonClass.SetActive(B_SettingsNumberOfBlocksUp, true)
  ButtonClass.SetActive(B_SettingsNumberOfBlocksDown, true)
  ButtonClass.SetActive(B_SettingsSound, true)
  ButtonClass.SetActive(B_SettingsClose, true)
  
  DrawBackground() 
   
  rect 1*TILESIZE, 1*TILESIZE, (TILES_X-1)*TILESIZE, (TILES_Y - 1)*TILESIZE, ColorPalette[11] filled

  for yy = 1 to TILES_Y-3
    FRAME_LEFT_TILE.draw(0, yy*TILESIZE)
    FRAME_RIGHT_TILE.draw((TILES_X-1)*TILESIZE, yy*TILESIZE)
  next
  
  for xx = 1 to TILES_X-1
    FRAME_BOTTOM_TILE.draw(xx*TILESIZE, (TILES_Y-2) * TILESIZE)
    FRAME_TOP_TILE.draw(xx*TILESIZE, 0)
  next
  
  FRAME_CORNER_TOP_LEFT_TILE.draw(0,0)
  FRAME_CORNER_TOP_RIGHT_TILE.draw((TILES_X-1)*TILESIZE, 0)
  FRAME_CORNER_BOTTOM_LEFT_TILE.draw(0,(TILES_Y-2) * TILESIZE)
  FRAME_CORNER_BOTTOM_RIGHT_TILE.draw((TILES_X-1)*TILESIZE, (TILES_Y-2)*TILESIZE)
    
  
  ButtonClass.DrawButtons()
end sub

sub Callback_SettingsLevelUp()
   StartLevel = StartLevel + 1
end sub

sub Callback_SettingsLevelDown()
  if(StartLevel > 1)
    StartLevel = StartLevel - 1
  endif
end sub

sub Callback_SettingsNumberOfBlocksUp()
  NUMBER_OF_BLOCKS = NUMBER_OF_BLOCKS + 1
  if(NUMBER_OF_BLOCKS > NUMBER_OF_MAX_BLOCKS + NUMBER_OF_MAX_SPECIAL_BLOCKS)
    NUMBER_OF_BLOCKS = NUMBER_OF_MAX_BLOCKS + NUMBER_OF_MAX_SPECIAL_BLOCKS
  endif
end sub

sub Callback_SettingsNumberOfBlocksDown()
  NUMBER_OF_BLOCKS = NUMBER_OF_BLOCKS - 1
  if(NUMBER_OF_BLOCKS < 2)
    NUMBER_OF_BLOCKS = 2
  endif
end sub

sub Callback_SettingsClose()

  SaveSettings()

  GAME_STATE = GameStateTemp

  if(IS_ANDROID)
    ButtonClass.SetActive(B_Drop, true)
    ButtonClass.SetActive(B_Cycle, true)
    ButtonClass.SetActive(B_Left, true)
    ButtonClass.SetActive(B_Right, true)
  endif
  ButtonClass.SetActive(B_Menu, true)
  ButtonClass.SetActive(B_Pause, true)
  if(GAME_STATE == GAME_END) then ButtonClass.SetActive(B_GameStart, true)
  ButtonClass.SetActive(B_SettingsLevelUp, false)
  ButtonClass.SetActive(B_SettingsLevelDown, false)
  ButtonClass.SetActive(B_SettingsNumberOfBlocksUp, false)
  ButtonClass.SetActive(B_SettingsNumberOfBlocksDown, false)
  ButtonClass.SetActive(B_SettingsClose, false)  
  ButtonClass.SetActive(B_SettingsSound, false)  
  
  DrawEverything()

end sub


sub GameSettings()

  at (SCREEN_X - textwidth("BLOCK EXPLOSION by Pixelguy") )/ 2  , TILESIZE
  print "BLOCK EXPLOSION by Pixelguy"

  at 2*TILESIZE, 3*TILESIZE - FONTSIZE/2
  print "Start Level: "; StartLevel 
  
  at 2*TILESIZE, 6*TILESIZE - FONTSIZE/2
  print "Number of Blocks: "; NUMBER_OF_BLOCKS
  
  at 2*TILESIZE, 9*TILESIZE - FONTSIZE/2
  print "Sound: "
  
  
  
end


sub DrawEverything()
  color ColorPalette[10], ColorPalette[10]
  cls
  DrawBackground()
  'DrawColorPalette()
  DrawBoard()
  DrawScore()
  ButtonClass.DrawButtons() 
end

sub DrawScore()
  local posx
  posx = (BOARD_X+1.2)*TILESIZE + BOARD_OFFSET_X
  
  color ColorPalette[7], ColorPalette[10]
   
  at posx,BOARD_OFFSET_Y: print "HIGHSCORE" 
  at posx,BOARD_OFFSET_Y + FONTSIZE: print Highscore 
   
  at posx,BOARD_OFFSET_Y + 3*FONTSIZE: print "SCORE"
  
  rect posx, BOARD_OFFSET_Y + 4*FONTSIZE, posx + (INFO_X-1.2)*TILESIZE, BOARD_OFFSET_Y + 5*FONTSIZE, ColorPalette[10] filled
  
  if(PointsTemp > 0) then
    at posx,BOARD_OFFSET_Y + 4*FONTSIZE:print PointsTotal; " + "; PointsTemp
  else
    at posx,BOARD_OFFSET_Y + 4*FONTSIZE:print PointsTotal
  endif
  
  at posx,BOARD_OFFSET_Y + 6*FONTSIZE: print "LEVEL"
  at posx,BOARD_OFFSET_Y + 7*FONTSIZE: print Level
  
  at posx,BOARD_OFFSET_Y + 9*FONTSIZE: print "BLOCKS"
  at posx,BOARD_OFFSET_Y + 10*FONTSIZE: print BlocksTotal
  
  'Draw next column
  rect posx+0.5*TILESIZE, BOARD_OFFSET_Y+13*FONTSIZE, posx + 1.5*TILESIZE, BOARD_OFFSET_Y+13*FONTSIZE + 3*TILESIZE, ColorPalette[10] filled
  TempImg = Tiles[NextColumn[0]]
  TempImg.draw(posx+0.5*TILESIZE, BOARD_OFFSET_Y+13*FONTSIZE)
  TempImg = Tiles[NextColumn[1]]
  TempImg.draw(posx+0.5*TILESIZE, BOARD_OFFSET_Y+13*FONTSIZE+TILESIZE)
  TempImg = Tiles[NextColumn[2]]
  TempImg.draw(posx+0.5*TILESIZE, BOARD_OFFSET_Y+13*FONTSIZE+2*TILESIZE)
  
end


sub FallBlocks()
  local xx,yy,ii,finished = true
  
  MicroStep = MicroStep + 1 * TimeStep
  if(MicroStep >= TILESIZE)
    MicroStep = 0
    for xx = 0 to BOARD_X
      for yy = BOARD_Y-1 to 0 Step -1
        if( Board[xx,yy,BOARD_MICROSTEP] > 0) then
          Board[xx,yy+1,BOARD_MICROSTEP] = 0
          Board[xx,yy+1,BOARD_REMOVE] = Board[xx,yy,BOARD_REMOVE]
          Board[xx,yy+1,BOARD_BLOCKS] = Board[xx,yy,BOARD_BLOCKS]
          Board[xx,yy,BOARD_BLOCKS] = 0
          Board[xx,yy,BOARD_REMOVE] = 0
          Board[xx,yy,BOARD_MICROSTEP] = 0
        endif
      next
    
    next
  endif
  
  for xx = 0 to BOARD_X
    for yy = BOARD_Y to 1 Step -1
      if(Board[xx,yy,BOARD_REMOVE] == 1) then
        finished = false
        for ii = yy-1 to 0 Step -1
           Board[xx,ii,BOARD_MICROSTEP] = MicroStep
        next
      
        exit
        
      endif
    next
  next 
  
  if(finished) then
    GAME_STATE = GAME_REMOVE_BLOCKS
  endif
    
  
end sub

sub ExplodeBlocks()
  local Explosions = 0
  local xx,yy
   
  for yy = 0 to BOARD_Y
     for xx = 0 to BOARD_X
       if(Board[xx,yy,BOARD_REMOVE] == 1) then
         Explosions++
         Board[xx,yy,BOARD_BLOCKS] = BLOCKS_EXPLOSION_OFFSET + floor(BlocksExplosionAnimationFrame)  
       endif
     next
  next
  
  BlocksExplosionAnimationFrame = BlocksExplosionAnimationFrame + TimeStep * BLOCKS_EXPLOSION_ANIMATION_SPEED
  if(BlocksExplosionAnimationFrame > NUMBER_OF_BLOCKS_EXPLOSION_ANIMATIONS) then
    BlocksExplosionAnimationFrame = 0
    
    if(Explosions > 0) then
	  PlaySoundExplosion()
      GAME_STATE = GAME_FALL_BLOCKS
      MicroStep = 0
    else
      CreateColumn()
    endif
    
    for yy = 0 to BOARD_Y
      for xx = 0 to BOARD_X
        if(Board[xx,yy,BOARD_REMOVE] == 1) then
          Board[xx,yy,BOARD_BLOCKS] = 0
        endif
      next
    next
  endif
  
end


sub RemoveBlocks()
  local xx,yy,ii,bb,block,count
  
  for yy = 0 to BOARD_Y 
     for xx = 0 to BOARD_X 
       Board[xx,yy,BOARD_REMOVE] = 0
     next
  next
   
  'in a row
  for yy = 0 to BOARD_Y
    for xx = 1 to BOARD_X - 1
      if(Board[xx,yy,BOARD_BLOCKS] > 0) THEN
        if(Board[xx,yy,BOARD_BLOCKS] == Board[xx-1,yy,BOARD_BLOCKS]) then
          if(Board[xx,yy,BOARD_BLOCKS] == Board[xx+1,yy,BOARD_BLOCKS]) then
            Board[xx-1,yy,BOARD_REMOVE] = 1
            Board[xx  ,yy,BOARD_REMOVE] = 1
            Board[xx+1,yy,BOARD_REMOVE] = 1
            
            select Board[xx,yy,BOARD_BLOCKS]
              case BLOCKS_EXPLODE_X
                for bb = 0 to BOARD_X
                  Board[bb,yy,BOARD_REMOVE] = 1
                next
               
              case BLOCKS_EXPLODE_R
                if(yy>0)
                  Board[xx-1,yy-1,BOARD_REMOVE] = 1
                  Board[xx,yy-1,  BOARD_REMOVE] = 1
                  Board[xx+1,yy-1,BOARD_REMOVE] = 1
                endif
                if(yy < BOARD_Y-1)
                  Board[xx-1,yy+1,BOARD_REMOVE] = 1
                  Board[xx,yy+1,  BOARD_REMOVE] = 1
                  Board[xx+1,yy+1,BOARD_REMOVE] = 1
                endif
                
            end select
            
          endif
        endif
      endif 
    next xx
  next yy 
  
  'in a column    
  for yy = 1 to BOARD_Y-1
    for xx = 0 to BOARD_X
      if(Board[xx,yy,BOARD_BLOCKS] > 0) then    
        if(Board[xx,yy,BOARD_BLOCKS] == Board[xx,yy-1,BOARD_BLOCKS]) then
          if(Board[xx,yy,BOARD_BLOCKS] == Board[xx,yy+1,BOARD_BLOCKS]) then
            Board[xx,yy-1,BOARD_REMOVE] = 1
            Board[xx,yy  ,BOARD_REMOVE] = 1
            Board[xx,yy+1,BOARD_REMOVE] = 1
            
            select Board[xx,yy,BOARD_BLOCKS] 
              case BLOCKS_EXPLODE_Y
                for bb = 0 to BOARD_Y
                  Board[xx,bb,  BOARD_REMOVE] = 1
                next
              case BLOCKS_EXPLODE_R
                if(xx>0)
                  Board[xx-1,yy+1,BOARD_REMOVE] = 1
                  Board[xx-1,yy , BOARD_REMOVE] = 1
                  Board[xx-1,yy-1,BOARD_REMOVE] = 1
                endif
                if(xx < BOARD_X)
                   Board[xx+1,yy+1, BOARD_REMOVE] = 1
                   Board[xx+1,yy  , BOARD_REMOVE] = 1
                   Board[xx+1,yy-1, BOARD_REMOVE] = 1
                endif
            end select
            
          endif
        endif
      endif 
    next xx
 next yy
  
  
  'diagonal
  for yy = 1 to BOARD_Y - 1
    for xx = 1 to BOARD_X - 1
      'LT2RB 
      if(Board[xx,yy,BOARD_BLOCKS] > 0) then
        if(Board[xx,yy,BOARD_BLOCKS] == Board[xx-1,yy-1,BOARD_BLOCKS]) then
          if(Board[xx,yy,BOARD_BLOCKS] == Board[xx+1,yy+1,BOARD_BLOCKS]) then
            Board[xx-1,yy-1,BOARD_REMOVE] = 1
            Board[xx  ,yy,  BOARD_REMOVE] = 1
            Board[xx+1,yy+1,BOARD_REMOVE] = 1
            
            select Board[xx,yy,BOARD_BLOCKS]
               case BLOCKS_EXPLODE_R
                
                  Board[xx,yy-1,  BOARD_REMOVE] = 1
                  Board[xx+1,yy-1,BOARD_REMOVE] = 1
                  Board[xx-1,yy  ,BOARD_REMOVE] = 1
                  Board[xx+1,yy  ,BOARD_REMOVE] = 1
                  Board[xx-1,yy+1,BOARD_REMOVE] = 1
                  Board[xx  ,yy+1,BOARD_REMOVE] = 1
               
            end select
            
          endif
        endif 
        'LB2RT
        if(Board[xx,yy,BOARD_BLOCKS] == Board[xx-1,yy+1,BOARD_BLOCKS]) then
          if(Board[xx,yy,BOARD_BLOCKS] == Board[xx+1,yy-1,BOARD_BLOCKS]) then
            Board[xx-1,yy+1,BOARD_REMOVE] = 1
            Board[xx  ,yy  ,BOARD_REMOVE] = 1
            Board[xx+1,yy-1,BOARD_REMOVE] = 1
            
            select Board[xx,yy,BOARD_BLOCKS]
              case BLOCKS_EXPLODE_R
                Board[xx-1,yy-1,  BOARD_REMOVE] = 1
                Board[xx  ,yy-1,BOARD_REMOVE] = 1
                Board[xx-1,yy  ,BOARD_REMOVE] = 1
                Board[xx+1,yy  ,BOARD_REMOVE] = 1
                Board[xx  ,yy+1,BOARD_REMOVE] = 1
                Board[xx+1,yy+1,BOARD_REMOVE] = 1
            end select
            
          endif
        endif 
      endif  
    next
  next
  
  BlocksRemoved = 0
  for yy = 0 to BOARD_Y
     for xx = 0 to BOARD_X
       if(Board[xx,yy,BOARD_REMOVE] == 1) then
         Board[xx,yy,BOARD_BLOCKS] = 0
         BlocksRemoved++
       endif
     next
  next
  
  if(BlocksRemoved > 0) then
     GAME_STATE = GAME_EXPLODE_BLOCKS
     PointsTemp = PointsTemp + 10*BlocksRemoved * PointsMultiplier
     PointsMultiplier++
     BlocksTotal = BlocksTotal + BlocksRemoved
  else
     CreateColumn()
  endif
end



sub CalcColumnTouchDown()
  local ii
  for ii = ColumnPositionY to BOARD_Y - 1
    if(Board[ColumnPositionX,ii,BOARD_BLOCKS] > 0)
       exit
    endif
    
  NEXT ii
  
  COLUMM_TOUCH_DOWN = ii - 4
end


sub DrawBoard()
  local xx,yy,TempImg,posy

  'Draw Tiles
  for xx = 0 to BOARD_X
    for yy = 0 to BOARD_Y-1
     
      posy = yy * TILESIZE + BOARD_OFFSET_Y
      TempImg = Tiles[0]
      TempImg.draw(xx*TILESIZE + BOARD_OFFSET_X, posy)
      
      if(Board[xx,yy,BOARD_BLOCKS] > 0)
        posy = yy * TILESIZE + Board[xx,yy,BOARD_MICROSTEP] + BOARD_OFFSET_Y
        TempImg =Tiles[Board[xx,yy,BOARD_BLOCKS]]
        TempImg.draw(xx*TILESIZE + BOARD_OFFSET_X, posy)
      end if
    next yy
  next xx
  
end

sub CycleColumn()
  local temp
  temp = Column[0]
  Column[0] = Column[2]
  Column[2] = Column[1]
  Column[1] = temp
end


sub CreateButtons()
  if(ScreenMode = 0) 'Portrait
	if(IS_ANDROID)
		B_Cycle = ButtonClass.AddButton(0, BOARD_Y * TILESIZE + BOARD_OFFSET_Y + 1*TILESIZE            , SCREEN_X/10*4.5-5*PIXELSIZE, 3*TILESIZE - PIXELSIZE, "Cycle", @Callback_Cycle)
		B_Drop  = ButtonClass.AddButton(0, BOARD_Y * TILESIZE + BOARD_OFFSET_Y + 4*TILESIZE + PIXELSIZE, SCREEN_X/10*4.5-5*PIXELSIZE, 3*TILESIZE - PIXELSIZE, "Drop", @Callback_Drop)
		B_Right = ButtonClass.AddButton(SCREEN_X/10*5.5+5*PIXELSIZE, BOARD_Y * TILESIZE + BOARD_OFFSET_Y + 1*TILESIZE, SCREEN_X/10*4.5 - 5*PIXELSIZE, 3*TILESIZE - PIXELSIZE, ">", @Callback_Right)
		B_Left  = ButtonClass.AddButton(SCREEN_X/10*5.5+5*PIXELSIZE, BOARD_Y * TILESIZE + BOARD_OFFSET_Y + 4*TILESIZE + PIXELSIZE, SCREEN_X/10*4.5-5*PIXELSIZE, 3*TILESIZE - PIXELSIZE, "<", @Callback_Left) 
		B_Pause = ButtonClass.AddButton(SCREEN_X/10*4.5, BOARD_Y * TILESIZE + BOARD_OFFSET_Y + 1*TILESIZE, SCREEN_X/10*1, 3*TILESIZE - PIXELSIZE, "Pause", @Callback_Pause)
		B_Menu  = ButtonClass.AddButton(SCREEN_X/10*4.5, BOARD_Y * TILESIZE + BOARD_OFFSET_Y + 4*TILESIZE + PIXELSIZE, SCREEN_X/10*1, 3*TILESIZE - PIXELSIZE, "Menu", @Callback_Menu)
	else
		B_Pause = ButtonClass.AddButton(SCREEN_X/10*3 - 5*PIXELSIZE, SCREEN_Y - 1.8*TILESIZE, SCREEN_X/10*2, 1.5*TILESIZE, "Pause", @Callback_Pause)
		B_Menu  = ButtonClass.AddButton(SCREEN_X/10*5 + 5*PIXELSIZE, SCREEN_Y - 1.8*TILESIZE, SCREEN_X/10*2, 1.5*TILESIZE, "Menu", @Callback_Menu)
	endif
	
  else 'Lanscape
  	
	B_Cycle = ButtonClass.AddButton(0, SCREEN_Y/2 - 3*TILESIZE                           , 4*TILESIZE, 3*TILESIZE, "Cycle", @Callback_Cycle)
	B_Drop  = ButtonClass.AddButton(0, SCREEN_Y/2 - 3*TILESIZE + 3*TILESIZE + 5*PIXELSIZE, 4*TILESIZE, 3*TILESIZE, "Drop", @Callback_Drop)
	B_Right = ButtonClass.AddButton(SCREEN_X - 4*TILESIZE, SCREEN_Y/2 - 3*TILESIZE                           , 4*TILESIZE, 3*TILESIZE, ">", @Callback_Right)
	B_Left  = ButtonClass.AddButton(SCREEN_X - 4*TILESIZE, SCREEN_Y/2 - 3*TILESIZE + 3*TILESIZE + 5*PIXELSIZE, 4*TILESIZE, 3*TILESIZE, "<", @Callback_Left) 
  	B_Pause = ButtonClass.AddButton(0                    , SCREEN_Y - 3*TILESIZE, 2*TILESIZE, 2*TILESIZE, "Pause", @Callback_Pause)
	B_Menu  = ButtonClass.AddButton(SCREEN_X - 2*TILESIZE, SCREEN_Y - 3*TILESIZE, 2*TILESIZE, 2*TILESIZE, "Menu", @Callback_Menu)
	
  endif
  
	B_GameStart  = ButtonClass.AddButton(0.5*TILESIZE + BOARD_OFFSET_X, (BOARD_Y/2 - 1.5 ) * TILESIZE + BOARD_OFFSET_Y, (BOARD_X) * TILESIZE, 4*TILESIZE, "START NEW GAME", @Callback_GameStart)
	
	'Settings
	B_SettingsLevelDown            = ButtonClass.AddButton((TILES_X-6)*TILESIZE, 2*TILESIZE, 2*TILESIZE-2*PIXELSIZE, 2*TILESIZE, "-", @Callback_SettingsLevelDown)
	B_SettingsLevelUp          = ButtonClass.AddButton((TILES_X-4)*TILESIZE, 2*TILESIZE, 2*TILESIZE-2, 2*TILESIZE, "+", @Callback_SettingsLevelUp)
	B_SettingsNumberOfBlocksDown   = ButtonClass.AddButton((TILES_X-6)*TILESIZE, 5*TILESIZE, 2*TILESIZE-2*PIXELSIZE, 2*TILESIZE, "-", @Callback_SettingsNumberOfBlocksDown)
    B_SettingsNumberOfBlocksUp = ButtonClass.AddButton((TILES_X-4)*TILESIZE, 5*TILESIZE, 2*TILESIZE-2*PIXELSIZE, 2*TILESIZE, "+", @Callback_SettingsNumberOfBlocksUp)
    if(SoundOnOFF)
		B_SettingsSound = ButtonClass.AddButton((TILES_X-4)*TILESIZE, 8*TILESIZE, 2*TILESIZE-2*PIXELSIZE, 2*TILESIZE, "ON", @Callback_SettingsSound)
    else
		B_SettingsSound = ButtonClass.AddButton((TILES_X-4)*TILESIZE, 8*TILESIZE, 2*TILESIZE-2*PIXELSIZE, 2*TILESIZE, "OFF", @Callback_SettingsSound)
    endif
    
    B_SettingsClose              = ButtonClass.AddButton(((TILES_X-3)/2)*TILESIZE, (TILES_Y - 5)*TILESIZE, 4*TILESIZE, 2*TILESIZE, "CLOSE", @Callback_SettingsClose)
    
    
    ButtonClass.SetActive(B_SettingsLevelUp, false)
    ButtonClass.SetActive(B_SettingsLevelDown, false)
    ButtonClass.SetActive(B_SettingsNumberOfBlocksUp, false)
    ButtonClass.SetActive(B_SettingsNumberOfBlocksDown, false)
    ButtonClass.SetActive(B_SettingsSound, false)
    ButtonClass.SetActive(B_SettingsClose, false)
    
end



sub DrawBackground()
  local xx,yy
  
  for xx = 1 to SCREEN_X step TILESIZE
    for yy = 1 to SCREEN_Y step TILESIZE
      BACKGROUND_TILE.draw(xx,yy)
    next
  next
  
  rect BOARD_OFFSET_X, BOARD_OFFSET_Y, BOARD_OFFSET_X + (BOARD_X + INFO_X) * TILESIZE, BOARD_OFFSET_Y + BOARD_Y * TILESIZE, ColorPalette[10] filled
  
  for yy = 0 to BOARD_Y - 1
    FRAME_LEFT_TILE.draw(BOARD_OFFSET_X - TILESIZE, BOARD_OFFSET_Y + yy * TILESIZE)
    FRAME_RIGHT_TILE.draw(BOARD_OFFSET_X + (BOARD_X + INFO_X) * TILESIZE, BOARD_OFFSET_Y + yy * TILESIZE)
  next
  
  for xx = 0 to BOARD_X + INFO_X - 1
	FRAME_BOTTOM_TILE.draw(BOARD_OFFSET_X + xx*TILESIZE, BOARD_OFFSET_Y + BOARD_Y * TILESIZE)
	FRAME_TOP_TILE.draw(BOARD_OFFSET_X + xx*TILESIZE, BOARD_OFFSET_Y - TILESIZE)
	
  next
  
  FRAME_CORNER_TOP_LEFT_TILE.draw(BOARD_OFFSET_X - TILESIZE, BOARD_OFFSET_Y - TILESIZE)
  FRAME_CORNER_TOP_RIGHT_TILE.draw(BOARD_OFFSET_X + (BOARD_X + INFO_X)*TILESIZE, BOARD_OFFSET_Y - TILESIZE)
  FRAME_CORNER_BOTTOM_LEFT_TILE.draw(BOARD_OFFSET_X - TILESIZE, BOARD_OFFSET_Y + BOARD_Y * TILESIZE)
  FRAME_CORNER_BOTTOM_RIGHT_TILE.draw(BOARD_OFFSET_X + (BOARD_X + INFO_X)*TILESIZE, BOARD_OFFSET_Y + BOARD_Y*TILESIZE)
end


sub DrawColumn()
  local px, py
  
  px = ColumnPositionX * TILESIZE + BOARD_OFFSET_X
  py = ColumnPositionY * TILESIZE + BOARD_OFFSET_Y
  
  if(ColumnPositionNewX > -1) then
    
    TempImg =Tiles[0]  'Background Tile
    TempImg.draw(px,ColumnPositionY*TILESIZE + BOARD_OFFSET_Y)
    TempImg.draw(px,(ColumnPositionY+1)*TILESIZE + BOARD_OFFSET_Y)
    TempImg.draw(px,(ColumnPositionY+2)*TILESIZE + BOARD_OFFSET_Y)
    TempImg.draw(px,(ColumnPositionY+3)*TILESIZE + BOARD_OFFSET_Y)
      
    ColumnPositionX = ColumnPositionNewX
    ColumnPositionNewX = -1
    CalcColumnTouchDown()
    
    px = ColumnPositionX * TILESIZE + BOARD_OFFSET_X
      
  else
    TempImg =Tiles[0]  'Background Tile
    TempImg.draw(px,py)
  endif
  
  MicroStep = MicroStep + Speed * TimeStep
  if(MicroStep >= TILESIZE)
    MicroStep = 0
    ColumnPositionY++
    py = ColumnPositionY * TILESIZE + BOARD_OFFSET_Y

    if(ColumnPositionY > COLUMM_TOUCH_DOWN) then
	  Board[ColumnPositionX,ColumnPositionY,BOARD_BLOCKS]= Column[0]
      Board[ColumnPositionX,ColumnPositionY+1,BOARD_BLOCKS]= Column[1]
      Board[ColumnPositionX,ColumnPositionY+2,BOARD_BLOCKS]= Column[2]
      GAME_STATE = GAME_REMOVE_BLOCKS
    endif
    
    TempImg =Tiles[0]  'Background Tile
    TempImg.draw(px,py)
    TempImg.draw(px,py + TILESIZE)
    TempImg.draw(px,py + 2*TILESIZE)

  else

     TempImg =Tiles[0]  'Background Tile
     'TempImg.draw(px,py)
     TempImg.draw(px,py + TILESIZE)
     TempImg.draw(px,py + 2*TILESIZE)
     TempImg.draw(px,py + 3*TILESIZE)
  endif
  
  py = py +  MicroStep
  py = floor(py / PIXELSIZE) * PIXELSIZE
  

  
  TempImg =Tiles[Column[0]]
  TempImg.draw(px,py)
  TempImg = Tiles[Column[1]]
  TempImg.draw(px, py + TileSize)
  TempImg = Tiles[Column[2]]
  TempImg.draw(px, py + 2*TileSize)
  

  
end sub
 

sub CreateColumn()
  
  ColumnPositionY = 0
  ColumnPositionX = 4
  GAME_STATE = GAME_COLUMN_IS_MOVING
  Speed = GAME_COLUMN_SPEED * Level * 0.02
  Column = NextColumn 
  NextColumn[0] = int(rnd() * (NUMBER_OF_BLOCKS)) + 1
  NextColumn[1] = int(rnd() * (NUMBER_OF_BLOCKS)) + 1
  NextColumn[2] = int(rnd() * (NUMBER_OF_BLOCKS)) + 1
  MicroStep = 0
  CalcColumnTouchDown()
  
  if(PointsTemp > 0) then
    PointsTotal = PointsTotal + PointsTemp
    PointsMultiplier = 1
    PointsTemp = 0
    
    'LevelUp?
    TempLevel = ceil(BlocksTotal / (45+Level*5))
    if(Level < TempLevel) then Level = TempLevel
  endif
  
  if(Board[ColumnPositionX,3,BOARD_BLOCKS] > 0)
    ButtonClass.SetActive(B_GameStart, true)
    DrawEverything()
    if(PointsTotal > Highscore) then 
      Highscore = PointsTotal
      'Save Settings to save Highscore
      SaveSettings()
    endif
    GAME_STATE = GAME_END
  endif
  
end sub

sub CreateBoard()
  local xx,yy

   for xx = 0 to BOARD_X
    for yy = 0 to BOARD_Y
      Board[xx,yy,BOARD_BLOCKS] = 0
      Board[xx,yy,BOARD_MICROSTEP] = 0
      Board[xx,yy,BOARD_REMOVE] = 0
      Board[xx,yy,BOARD_ANIMATION_OFFSET] = 0
      Board[xx,yy,BOARD_ANIMATION_FRAME] = 0
    next yy
  next xx
end sub


sub InitScreen()

  if(SCREEN_X < SCREEN_Y) 'portrait mode

    if(IS_ANDROID)
       TILES_X = BOARD_X + INFO_X + 2
       TILES_Y = BOARD_Y -1 + 1 + 3 + 3 + 2 + 1
    else
       TILES_X = BOARD_X + INFO_X + 2
       TILES_Y = BOARD_Y + 3
    endif
  
    ScreenMode = 0
    'Calculate Tilesize depending on screen size
    A = SCREEN_X /(TILES_X)
    if(A*(TILES_Y) > SCREEN_Y) then
      A = SCREEN_Y / (TILES_Y)
    endif
  else 'landscape mode
    ScreenMode = 1
    if(IS_ANDROID)
      TILES_X = BOARD_X + INFO_X + 4 + 4 + 1 + 1
      TILES_Y = BOARD_Y + 1
    else
      TILES_X = BOARD_X + INFO_X + 2
      TILES_Y = BOARD_Y + 1
    endif
 
    A = SCREEN_X /(TILES_X)
 
    if(A*(TILES_Y) > SCREEN_Y) then
      A = SCREEN_Y / (TILES_Y)
    endif
  endif

  TILESIZE = floor(A/16)*16
  PIXELSIZE = TILESIZE/16
  TILES_X = round(SCREEN_X / TILESIZE)
  TILES_Y = round(SCREEN_Y / TILESIZE)
  BOARD_OFFSET_X = floor(((SCREEN_X - (BOARD_X + INFO_X)*TILESIZE)/2)/TILESIZE)*TILESIZE
  BOARD_OFFSET_Y = TILESIZE
end sub

sub CreateColorPalette()
  ColorPalette[0] = rgb(36,38,114) 'Blue to white
  ColorPalette[1] = rgb(43,89,183) 
  ColorPalette[2] = rgb(53,174,235)
  ColorPalette[3] = rgb(126,213,233)
  ColorPalette[4] = rgb(244,233,233) 'White to sand
  ColorPalette[5] = rgb(249,210,168) 
  ColorPalette[6] = rgb(249,184,124)
  ColorPalette[7] = rgb(217,129,72)
  ColorPalette[8] = rgb(141,105,112) 'RedGray
  ColorPalette[9] = rgb(101,78,104)
  ColorPalette[10] = rgb(25,13,20) 'Gray to metallic
  ColorPalette[11] = rgb(57,50,56)
  ColorPalette[12] = rgb(97,99,107)
  ColorPalette[13] = rgb(145,151,157)
  ColorPalette[14] = rgb(196,208,216)
  ColorPalette[15] = rgb(10,52,34) 'Green to yelliwGreen
  ColorPalette[16] = rgb(32,102,36)
  ColorPalette[17] = rgb(63,156,44)
  ColorPalette[18] = rgb(181,206,45)
  ColorPalette[19] = rgb(249,229,84) 'Yellow to red
  ColorPalette[20] = rgb(253,193,26)
  ColorPalette[21] = rgb(255,117,36)
  ColorPalette[22] = rgb(233,54,43)
  ColorPalette[23] = rgb(148,20,45)
  ColorPalette[24] = rgb(84,14,53) 'DarkPurple to pink
  ColorPalette[25] = rgb(127,54,135)
  ColorPalette[26] = rgb(189,85,150)
  ColorPalette[27] = rgb(255,130,124)
  ColorPalette[28] = rgb(249,170,139) 'lightBrown to darkBrown
  ColorPalette[29] = rgb(170,74,38)
  ColorPalette[30] = rgb(116,27,11)
  ColorPalette[31] = rgb(72,14,4)
  
end

sub DrawColorPalette()
  local ii
  for ii = 0 to 31*32 step 32
    rect ii,0,ii+31,31,ColorPalette[ii/32] filled 
  next
end

sub CreateTiles()
  local id = 0
  local ii
  local dim img[TILESIZE, TILESIZE]
  
  local sub CreateArrayFromDATA()
	local xx,yy,xp,yp,c
	
	for xx = 0 to 15 * PIXELSIZE Step PIXELSIZE
      for yy = 0 to 15 * PIXELSIZE Step PIXELSIZE
        Read c
		for xp = 0 to PIXELSIZE - 1
		  for yp = 0 to PIXELSIZE - 1
			if(c == -1)
			   img[xx+xp, yy+yp] = 0x00000000
			else
			  img[xx+xp, yy+yp] = 0xFF000000 - ColorPalette[c]
			endif
		  next
		next
	  next
    next	
  end sub
  
  'Tile 0 - Board
  CreateArrayFromDATA()
  Tiles[id] = image(img)
  
  id++
  BLOCKS_EXPLODE_X = id
  CreateArrayFromDATA()
  Tiles[id] = image(img)
  
  id++
  BLOCKS_EXPLODE_Y = id
  CreateArrayFromDATA()
  Tiles[id] = image(img)
  
  id++
  BLOCKS_EXPLODE_R = id
  CreateArrayFromDATA()
  Tiles[id] = image(img)
  
  id++
  'Normal Blocks
  for ii = 1 to NUMBER_OF_MAX_BLOCKS
    CreateArrayFromDATA()
    Tiles[id] = image(img)
    id++
  next
  
  CreateArrayFromDATA()
  BACKGROUND_TILE = image(img)
  CreateArrayFromDATA()
  FRAME_LEFT_TILE = image(img)
  CreateArrayFromDATA()
  FRAME_RIGHT_TILE = image(img)
  CreateArrayFromDATA()
  FRAME_BOTTOM_TILE = image(img)
  CreateArrayFromDATA()
  FRAME_TOP_TILE = image(img)  
  CreateArrayFromDATA()
  FRAME_CORNER_TOP_LEFT_TILE = image(img)  
  CreateArrayFromDATA()
  FRAME_CORNER_TOP_RIGHT_TILE = image(img) 
  CreateArrayFromDATA()
  FRAME_CORNER_BOTTOM_LEFT_TILE = image(img) 
  CreateArrayFromDATA()
  FRAME_CORNER_BOTTOM_RIGHT_TILE = image(img)  
      

  BLOCKS_EXPLOSION_OFFSET = id
  for ii = 0 to NUMBER_OF_BLOCKS_EXPLOSION_ANIMATIONS-1
    c=255/(NUMBER_OF_BLOCKS_EXPLOSION_ANIMATIONS-1)*ii
    
    rect 0,0,TILESIZE,TILESIZE,rgb(c,c,c) filled
    Tiles[id] = image(0,0,TILESIZE,TILESIZE)
    id++
  next ii
  
end sub


'Tiles data. Every tile is 16x16, color according to color palette, -1 is transparent
'Tile 0 - Background
data 10,12,13,13,13,13,13,13,13,13,13,13,13,12,10,10
data 12,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 13,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 12,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10
data 10,11,11,11,11,11,11,11,11,11,11,11,11,11,10,10
data 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10

'Explode X
data -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
data -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
data -1,-1,-1,17,17,17,17,17,17,17,17,17,17,-1,-1,-1
data -1,-1,17, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,17,-1,-1
data -1,18, 4,15,15,15,15,15,15,15,15,15,15, 4,17,-1
data 18, 4,16,15,15,21,15,15,15, 4,21,15,15,15, 4,17
data 17, 4,15,15,21,20,15,15,15,15,20,21,15,15, 4,17
data 17, 4,15,22,20,19,15, 4,17,15,19,20,22,15, 4,17
data 17, 4,15,22,20,19,15,17,16,15,19,20,22,15, 4,17
data 17, 4,15,15,21,20,15,15,15,15,20,21,15,15, 4,17
data 17, 4,15,15,15,21,15,15,15,15,21,15,15,15, 4,18
data -1,17, 4,15,15,15,15,15,15,15,15,15,15, 4,18,-1
data -1,-1,17, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,17,-1,-1
data -1,-1,-1,17,17,17,17,17,17,17,17,17,17,-1,-1,-1
data -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
data -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1

'Explode Y
data -1,-1,-1,-1,-1, 2, 2, 2, 2, 2, 2,-1,-1,-1,-1,-1
data -1,-1,-1,-1, 3, 4, 4, 4, 4, 4, 4, 2,-1,-1,-1,-1
data -1,-1,-1, 3, 4, 1, 0, 0, 0, 0, 0, 4, 2,-1,-1,-1
data -1,-1, 2, 4, 1, 0, 0,22,22, 0, 0, 0, 4, 2,-1,-1
data -1,-1, 2, 0, 0, 0,21,20,20,21, 0, 0, 0, 2,-1,-1
data -1,-1, 2, 0, 0,21,20,19,19,20,21, 0, 0, 2,-1,-1
data -1,-1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,-1,-1
data -1,-1, 2, 0, 0, 0, 0, 4, 3, 0, 0, 0, 0, 2,-1,-1
data -1,-1, 2, 0, 0, 0, 0, 3, 2, 0, 0, 0, 0, 2,-1,-1
data -1,-1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,-1,-1
data -1,-1, 2, 0, 0,21,20,19,19,20,21, 0, 0, 2,-1,-1
data -1,-1, 2, 0, 0, 0,21,20,20,21, 0, 0, 0, 2,-1,-1
data -1,-1, 2, 4, 0, 0, 0,22,22, 0, 0, 0, 4, 2,-1,-1
data -1,-1,-1, 2, 4,14, 0, 0, 0, 0, 3, 4, 2,-1,-1,-1
data -1,-1,-1,-1, 2, 4, 4, 4, 4, 4, 4, 1,-1,-1,-1,-1
data -1,-1,-1,-1,-1, 2, 2, 2, 2, 2, 1,-1,-1,-1,-1,-1

'Explode R
data -1,-1,-1,-1,-1,26,26,26,26,26,26,-1,-1,-1,-1,-1
data -1,-1,-1,-1,26, 4, 4, 4, 4, 4, 4,26,-1,-1,-1,-1
data -1,-1,-1,26, 4,25,24,24,24,24,24, 4,26,-1,-1,-1
data -1,-1,26, 4,25,24,24,22,22,24,24,24, 4,26,-1,-1
data -1,27, 4,25,24,24,21,20,20,21,24,24,24, 4,26,-1
data 27, 4,25,24,24,24,20,19,19,20,24,24,24,24, 4,26
data 26, 4,24,24,21,20,24,24,24,24,20,21,24,24, 4,26
data 26, 4,24,22,20,19,24, 4,26,24,19,20,22,24, 4,26
data 26, 4,24,22,20,19,24,26,27,24,19,20,22,24, 4,26
data 26, 4,24,24,21,20,24,24,24,24,20,21,24,24, 4,26
data 26, 4,24,24,24,24,20,19,19,20,24,24,24,24, 4,27
data -1,26, 4,24,24,24,21,20,20,21,24,24,24, 4,27,-1
data -1,-1,26, 4,24,24,24,22,22,24,24,24, 4,26,-1,-1
data -1,-1,-1,26, 4,14,24,24,24,24,24, 4,26,-1,-1,-1
data -1,-1,-1,-1,26, 4, 4, 4, 4, 4, 4,27,-1,-1,-1,-1
data -1,-1,-1,-1,-1,26,26,26,26,26,27,-1,-1,-1,-1,-1

'Tile 1 - Diamond blue
data -1,-1,-1,-1, 0, 0, 0, 0, 0, 0, 0, 0,-1,-1,-1,-1
data -1,-1,-1, 0, 4, 4, 2, 3, 3, 2, 2, 1, 0,-1,-1,-1
data -1,-1, 0, 4, 4, 2, 3, 3, 3, 3, 2, 2, 1, 0,-1,-1
data -1, 0, 4, 4, 2, 3, 3, 3, 3, 2, 3, 2, 2, 1, 0,-1
data  1, 4, 4, 2, 3, 3, 3, 3, 2, 3, 2, 3, 2, 2, 1, 0
data  0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0
data  0, 1, 1, 1, 4, 4, 4, 4, 4, 3, 2, 3, 1, 1, 1, 0
data -1, 0, 1, 1, 1, 4, 4, 4, 3, 2, 3, 2, 1, 1, 0,-1
data -1,-1, 0, 1, 1, 1, 4, 3, 2, 3, 2, 1, 1, 0,-1,-1
data -1,-1,-1, 0, 1, 1, 3, 2, 3, 2, 3, 1, 0,-1,-1,-1
data -1,-1,-1, 0, 1, 1, 1, 3, 2, 3, 1, 1, 0,-1,-1,-1
data -1,-1,-1,-1, 0, 1, 1, 2, 3, 4, 1, 0,-1,-1,-1,-1
data -1,-1,-1,-1,-1, 0, 1, 1, 4, 1, 0,-1,-1,-1,-1,-1
data -1,-1,-1,-1,-1,-1, 0, 1, 2, 0,-1,-1,-1,-1,-1,-1
data -1,-1,-1,-1,-1,-1, 0, 1, 1, 0,-1,-1,-1,-1,-1,-1
data -1,-1,-1,-1,-1,-1,-1, 0, 0,-1,-1,-1,-1,-1,-1,-1  

'Tile 2 - gem purple 
data -1,-1,-1,-1,-1,-1, 0, 0, 0, 0,-1,-1,-1,-1,-1,-1
data -1,-1,-1,-1, 0, 0,26,26,26,26, 0, 0,-1,-1,-1,-1
data -1,-1,-1, 0,26,26,26,26,26,26,26,26, 0,-1,-1,-1
data -1,-1, 0, 4,26,26,26,26,26,26,26,26,24, 0,-1,-1
data -1, 0, 4, 4, 4,26,26,26,26,26,26,24,24,24, 0,-1
data -1, 0, 4, 4,27,27,26,26,26,26,24,24,24,24, 0,-1
data  0, 4, 4,27,27,27, 4, 4, 4, 4,24,24,24,24,24, 0
data  0, 4,27,27,27, 4, 4, 4, 4,26,26,24,24,24,24, 0
data  0,27,27,27,27, 4, 4, 4,26,26,26,24,24,24,24, 0
data  0,27,27,27,27,27, 4,26,26,26,24,24,24,24,24, 0
data -1, 0,27,27,27,27,25,25,25,25,24,24,24,24, 0,-1
data -1, 0,27,27, 4,25,25,25,25,25,25,24,24,24, 0,-1
data -1,-1, 0, 4,25,25,25,25,25,25,25,25,24, 0,-1,-1
data -1,-1,-1, 0,25,25,25,25,25,25,25,25, 0,-1,-1,-1
data -1,-1,-1,-1, 0, 0,25,25,25,25, 0, 0,-1,-1,-1,-1
data -1,-1,-1,-1,-1,-1, 0, 0, 0, 0,-1,-1,-1,-1,-1,-1

'Tile 3 - gem brown
data -1,-1,-1,30,30,30,30,30,30,30,30,30,30,-1,-1,-1
data -1,-1,30, 4, 4, 4, 7, 7, 6, 6, 5, 7, 7,30,-1,-1
data -1,30, 4, 4, 4, 4, 7, 6, 6, 5, 5, 7, 7, 7,30,-1
data 30, 4, 4, 4, 4, 4, 6, 6, 5, 5, 4, 7, 7, 7, 7,30
data 30, 4, 4, 4, 4, 4, 6, 5, 5, 4, 4, 7, 7, 7, 7,30
data 30, 7, 7, 7, 6, 6,29,29, 7, 7, 6,29,29,29, 7,30
data 30, 7, 7, 6, 6, 6,29, 7, 7, 6, 6,29,29, 7, 7,30
data 30, 7, 6, 6, 6, 5, 7, 7, 6, 6, 5,29, 7, 7, 7,30
data 30, 6, 6, 6, 5, 5, 7, 6, 6, 5, 5, 7, 7, 7, 6,30
data 30, 6, 6, 5, 5, 5, 6, 6, 5, 5, 4, 7, 7, 6, 6,30
data 30, 6, 5, 5, 5, 5, 6, 5, 5, 4, 4, 7, 6, 6, 6,30
data 30, 7, 7, 7, 7, 7,29,29,29, 6, 6,29,29,29,29,30
data 30, 7, 7, 7, 7, 7,29,29, 6, 6, 5,29,29,29,29,30
data -1,30, 7, 7, 7, 7,29, 6, 6, 5, 5,29,29,29,30,-1
data -1,-1,30, 7, 7, 7, 6, 6, 5, 5, 4,29,29,30,-1,-1
data -1,-1,-1,30,30,30,30,30,30,30,30,30,30,-1,-1,-1

'Tile 4 - Grey stone
data -1,-1,-1,-1,-1,-1,11,11,11,11,-1,-1,-1,-1,-1,-1
data -1,-1,-1,-1,-1,11,14,14,13,13,11,-1,-1,-1,-1,-1
data -1,-1,-1,-1,11,14,14,14,13,13,13,11,-1,-1,-1,-1
data -1,-1,-1,11,14,14,14,14,13,13,13,13,11,-1,-1,-1
data -1,-1,11,14,14,14,14,14,13,13,13,13,13,11,-1,-1
data -1,11,14,14,14,14,14,14,13,13,13,13,13,13,11,-1
data 11,14,14,14,14,14,14,14,13,13,13,13,13,13,13,11
data 11,14,14,14,14,14,14,14,13,13,13,13,13,13,13,11
data 11,12,12,12,12,12,12,12,11,11,11,11,11,11,11,11
data 11,12,12,12,12,12,12,12,11,11,11,11,11,11,11,11
data -1,11,12,12,12,12,12,12,11,11,11,11,11,11,11,-1
data -1,-1,11,12,12,12,12,12,11,11,11,11,11,11,-1,-1
data -1,-1,-1,11,12,12,12,12,11,11,11,11,11,-1,-1,-1
data -1,-1,-1,-1,11,12,12,12,11,11,11,11,-1,-1,-1,-1
data -1,-1,-1,-1,-1,11,12,12,11,11,11,-1,-1,-1,-1,-1
data -1,-1,-1,-1,-1,-1,11,11,11,11,-1,-1,-1,-1,-1,-1

'Tile 5 - gem green
data -1,-1,-1,-1,-1,11,11,11,11,11,11,-1,-1,-1,-1,-1
data -1,-1,-1,-1,11, 4, 4,18,18, 4,18,11,-1,-1,-1,-1
data -1,-1,-1,11, 4, 4,18,18, 4,18,18,18,11,-1,-1,-1
data -1,-1,11, 4, 4,18,18, 4,18,18,18,18,18,11,-1,-1
data -1,11,17,17,18,18, 4,18,18,18,18,18,15,15,11,-1
data 11,17,17,17,17, 4,18,18,18,18,18,15,15,15,15,11
data 11,17,17,17,17,17, 4, 4,19, 4,15,15,15,15,15,11
data 11,17,17,17,17,17, 4,19, 4,19,15,15,15,15,15,11
data 11,17,17,17,17,17,19, 4,19,19,15,15,15,15,15,11
data 11,17,17,17,17,17, 4,19,19,19,15,15,15,15,15,11
data 11,17,17,17,17,16,16,16,16,16,16,15,15,15,15,11
data -1,11,17,17,16,16,16,16,16,16,16,16,15,15,11,-1
data -1,-1,11,16,16,16,16,16,16,16,16,16,16,11,-1,-1
data -1,-1,-1,11,16,16,16,16,16,16,16,16,11,-1,-1,-1
data -1,-1,-1,-1,11,16,16,16,16,16,16,11,-1,-1,-1,-1
data -1,-1,-1,-1,-1,11,11,11,11,11,11,-1,-1,-1,-1,-1

'Tile 6 - Marble orange
data -1,-1,-1,-1,-1,-1,23,23,23,23,-1,-1,-1,-1,-1,-1
data -1,-1,-1,-1,23,23,20,20,20,20,23,23,-1,-1,-1,-1
data -1,-1,-1,23,19,19,21,21,21,21,22,22,23,-1,-1,-1
data -1,-1,23,19,21,21,21,21,21,21,21,22,22,23,-1,-1
data -1,23,19,21,21,21,20,21,21,21,21,21,22,22,23,-1
data -1,23,19,21,21,20,19,20,21,21,21,22,21,22,23,-1
data 23,20,21,21,21,21,20,21,21,21,21,21,22,22,21,23
data 23,20,21,21,21,21,21,21,21,21,21,22,21,22,21,23
data 23,20,21,21,21,21,21,21,21,21,22,21,22,22,21,23
data 23,21,21,21,21,21,21,21,21,22,21,22,21,22,21,23
data -1,23,21,21,22,21,22,21,22,21,22,21,22,21,23,-1
data -1,23,21,22,21,22,21,22,21,22,21,22,22,20,23,-1
data -1,-1,23,21,22,21,22,21,22,21,22,22,19,23,-1,-1
data -1,-1,-1,23,21,22,22,22,22,22,20,20,23,-1,-1,-1
data -1,-1,-1,-1,23,23,21,21,21,21,23,23,-1,-1,-1,-1
data -1,-1,-1,-1,-1,-1,23,23,23,23,-1,-1,-1,-1,-1,-1

'Background tile
data 30,29,29,29,29,29,29,30,29,30,30,30,30,30,30,29
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 30,29,29,29,29,29,29,30,29,30,30,30,30,30,30,29
data 29,30,30,30,30,30,30,29,30,29,29,29,29,29,29,30
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 29,30,30,30,30,30,30,29,30,29,29,29,29,29,29,30

'Background frame left
data 30,29,29,29,29,29,29,30,29,30, 7,20,20,20, 7,11
data 29,29,29,29,29,29,29,29,30,30, 7,20,20,20, 7,11
data 29,29,29,29,29,29,29,29,30,30, 7,20,20,20, 7,11
data 29,29,29,29,29,29,29,29,30,30, 7,20,20,20, 7,11
data 29,29,29,29,29,29,29,29,30,30, 7,20,20,20, 7,11
data 29,29,29,29,29,29,29,29,30,30, 7,20,20,20, 7,11
data 29,29,29,29,29,29,29,29,30,30, 7,20,20,20, 7,11
data 30,29,29,29,29,29,29,30,29,30,29,11,11,11,29,11
data 29,30,30,30,30,30,30,29,30,29, 6,19,19,19, 6,11
data 30,30,30,30,30,30,30,30,29,29, 7,20,20,20, 7,11
data 30,30,30,30,30,30,30,30,29,29, 7,20,20,20, 7,11
data 30,30,30,30,30,30,30,30,29,29, 7,20,20,20, 7,11
data 30,30,30,30,30,30,30,30,29,29, 7,20,20,20, 7,11
data 30,30,30,30,30,30,30,30,29,29, 7,20,20,20, 7,11
data 30,30,30,30,30,30,30,30,29,29, 7,20,20,20, 7,11
data 29,30,30,30,30,30,30,29,30,29, 7,20,20,20, 7,11

'Background frame right
data 11, 7,20,20,20, 7,11,10,11,30,30,30,30,30,30,29
data 11, 7,20,20,20, 7,11,11,10,30,30,30,30,30,30,30
data 11, 7,20,20,20, 7,11,11,10,30,30,30,30,30,30,30
data 11, 7,20,20,20, 7,11,11,10,30,30,30,30,30,30,30
data 11, 7,20,20,20, 7,11,11,10,30,30,30,30,30,30,30
data 11, 7,20,20,20, 7,11,11,10,30,30,30,30,30,30,30
data 11, 7,20,20,20, 7,11,11,10,30,30,30,30,30,30,30
data 11,29,11,11,11,29,11,10,11,30,30,30,30,30,30,29
data 11, 6,19,19,19, 6,10,11,10,29,29,29,29,29,29,30
data 11, 7,20,20,20, 7,10,10,11,29,29,29,29,29,29,29
data 11, 7,20,20,20, 7,10,10,11,29,29,29,29,29,29,29
data 11, 7,20,20,20, 7,10,10,11,29,29,29,29,29,29,29
data 11, 7,20,20,20, 7,10,10,11,29,29,29,29,29,29,29
data 11, 7,20,20,20, 7,10,10,11,29,29,29,29,29,29,29
data 11, 7,20,20,20, 7,10,10,11,29,29,29,29,29,29,29
data 11, 7,20,20,20, 7,10,11,10,29,29,29,29,29,29,30

'Background frame bottom
data 11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
data  7, 7, 7, 7, 7, 7, 7,29, 6, 7, 7, 7, 7, 7, 7, 7
data 20,20,20,20,20,20,20,11,19,20,20,20,20,20,20,20
data 20,20,20,20,20,20,20,11,19,20,20,20,20,20,20,20
data 20,20,20,20,20,20,20,11,19,20,20,20,20,20,20,20
data  7, 7, 7, 7, 7, 7, 7,29, 6, 7, 7, 7, 7, 7, 7, 7
data 11,11,11,11,11,11,11,11,10,10,10,10,10,10,10,10
data 10,11,11,11,11,11,11,10,11,10,10,10,10,10,10,11
data 11,10,10,10,10,10,10,11,10,11,11,11,11,11,11,10
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 29,30,30,30,30,30,30,29,30,29,29,29,29,29,29,30

'Background frame top
data 30,29,29,29,29,29,29,30,29,30,30,30,30,30,30,29
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 30,29,29,29,29,29,29,30,29,30,30,30,30,30,30,29
data 29,30,30,30,30,30,30,29,30,29,29,29,29,29,29,30
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data  7, 7, 7, 7, 7, 7, 7,29, 6, 7, 7, 7, 7, 7, 7, 7
data 20,20,20,20,20,20,20,11,19,20,20,20,20,20,20,20
data 20,20,20,20,20,20,20,11,19,20,20,20,20,20,20,20
data 20,20,20,20,20,20,20,11,19,20,20,20,20,20,20,20
data  7, 7, 7, 7, 7, 7, 7,29, 6, 7, 7, 7, 7, 7, 7, 7
data 11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11

'Background corner top left
data 30,29,29,29,29,29,29,30,29,30,30,30,30,30,30,29
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 30,29,29,29,29,29,29,30,29,30,30,30,30,30,30,29
data 29,30,30,30,30,30,30,29,30,29,29,29,29,29,29,30
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29, 7, 7, 7, 7, 7, 7
data 30,30,30,30,30,30,30,30,29,29, 7,20,20,20,20,20
data 30,30,30,30,30,30,30,30,29,29, 7,20,20,20,20,20
data 30,30,30,30,30,30,30,30,29,29, 7,20,20,20,20,20
data 30,30,30,30,30,30,30,30,29,29, 7,20,20,20, 7, 7
data 29,30,30,30,30,30,30,29,29,29, 7,20,20,20, 7,11

'Background corner top right
data 30,29,29,29,29,29,29,30,29,30,30,30,30,30,30,29
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 29,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30
data 30,29,29,29,29,29,29,30,29,30,30,30,30,30,30,29
data 29,30,30,30,30,30,30,29,30,29,29,29,29,29,29,30
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data  7, 7, 7, 7, 7, 7,30,30,29,29,29,29,29,29,29,29
data 20,20,20,20,20, 7,30,30,29,29,29,29,29,29,29,29
data 20,20,20,20,20, 7,30,30,29,29,29,29,29,29,29,29
data 20,20,20,20,20, 7,10,10,11,29,29,29,29,29,29,29
data  7, 7,20,20,20, 7,10,10,11,29,29,29,29,29,29,29
data 11, 7,20,20,20, 7,10,11,10,29,29,29,29,29,29,30

'Background corner bottom left
data 30,29,29,29,29,29,29,30,29,30, 7,20,20,20, 7,11
data 29,29,29,29,29,29,29,29,30,30, 7,20,20,20,20, 7
data 29,29,29,29,29,29,29,29,30,30, 7,20,20,20,20,20
data 29,29,29,29,29,29,29,29,30,30, 7,20,20,20,20,20
data 29,29,29,29,29,29,29,29,30,30, 7,20,20,20,20,20
data 29,29,29,29,29,29,29,29,30,30, 7, 7, 7, 7, 7, 7
data 29,29,29,29,29,29,29,29,30,30,30,30,30,10,10,10
data 30,29,29,29,29,29,29,30,29,30,30,30,30,10,10,11
data 29,30,30,30,30,30,30,29,30,29,29,29,29,11,11,10
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 29,30,30,30,30,30,30,29,30,29,29,29,29,29,29,30

'Background corner bottom right
data 11, 7,20,20,20, 7,11,10,11,30,30,30,30,30,30,29
data  7,20,20,20,20, 7,11,11,10,30,30,30,30,30,30,30
data 20,20,20,20,20, 7,11,11,10,30,30,30,30,30,30,30
data 20,20,20,20,20, 7,11,11,10,30,30,30,30,30,30,30
data 20,20,20,20,20, 7,11,11,10,30,30,30,30,30,30,30
data  7, 7, 7, 7, 7, 7,11,11,10,30,30,30,30,30,30,30
data 11,11,11,11,11,11,11,11,10,30,30,30,30,30,30,30
data 10,11,11,11,11,11,11,10,11,30,30,30,30,30,30,29
data 11,10,10,10,10,10,10,11,10,29,29,29,29,29,29,30
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 30,30,30,30,30,30,30,30,29,29,29,29,29,29,29,29
data 29,30,30,30,30,30,30,29,30,29,29,29,29,29,29,30
