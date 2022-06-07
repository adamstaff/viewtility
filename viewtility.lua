-- viewtility
-- by @adamstaff_producer
-- 
-- for metering norns's
-- audio inputs
--
-- enc1 to change modes
-- enc2 to adjust zoom
-- enc3 to adjust scale
--
-- modes:
-- 1: Lissajous (XY plot)
-- 2: Waveform LR
-- 3: Waveform L
-- 4: Waveform R
--
-- v0.1
-- todo: add spectral plot

start = 2
length = 1/10
window = 128
sampL = {}
sampR = {}
height = 16
zoom = 1
level = 1.5
level_timer = 20
mode_timer = 20
zoom_timer = 20
enc_timer = 0
mode = 2

-- put samples in the arrays
function copy_samples (ch, in2, in3, samples)
  if ch == 1 then
    sampL = samples
  end
  if ch == 2 then
    sampR = samples
  end
  softcut.position(ch,0)
  softcut.voice_sync(1,2,0)
end

function print_position(i,p)
  print(i .. ":" .. p)
end

function init()
  reset()
  softcut.event_render(copy_samples)
  softcut.event_position(print_position)
  r:start()
end

-- all buffer stuff
function reset()
  for i=1,window,1 do sampL[i] = 0 end
  for i=1,window,1 do sampR[i] = 0 end
  for i=1,2 do
    --turn on and assign
    softcut.enable(i,1)
    softcut.buffer(i,i)
    --circular buffer
    softcut.loop(i,1)
    softcut.loop_start(i,start)
    softcut.loop_end(i,start+length)
    --softcut.position(i,start)
    softcut.rate(i,zoom)
    --levels
    softcut.fade_time(i,0)
    softcut.level(i,1.0)
    softcut.level_input_cut(i,i,1.0)
    softcut.rec_level(i,1.0)
    softcut.pre_level(i,0)
    softcut.rec(i,1)
  end
  softcut.buffer_clear()
  audio.level_adc_cut(1)
  print("reset OK")
end

function draw_liz_background()
  -- text
  screen.level(3)
  screen.move(0,10)
  screen.text("L")
  screen.move(128,10)
  screen.text_right("R")
  screen.move(65,5)
  screen.text("C")
  -- diagonals
  screen.level(1)
  screen.move(64,64)
  screen.line(0,0)
  screen.move(63,64)
  screen.line(127,0)
  screen.stroke()
   -- vertical
  screen.move(64,64)
  screen.line(64,0)
  screen.stroke()
  -- bottom line
  screen.level(4)
  screen.move(0,64)
  screen.line(127,64)
  screen.stroke()
end

function redraw()
  screen.clear()
  --draw level display
  if level_timer > 0 then
    screen.level(8)
    screen.move(127,60)
    screen.text_right("Amp: " .. level)
    level_timer = level_timer - 1
  end
  --draw zoom display
  if zoom_timer > 0 then
    screen.level(8)
    screen.move(100,60)
    screen.text_right("Zoom: " .. zoom)
    zoom_timer = zoom_timer - 1
  end
  
  --lissajueueu view
  if mode == 1 then
    window = 256;
    draw_liz_background()
    --draw waveform / pixels
    screen.level(15)
    for i=1, window, 1 do
      screen.pixel(
        --x
        util.round(63 + 64 * level * (sampR[i] - sampL[i])),
        --y
        math.abs(util.round(64 - 64 * level * (sampR[i] + sampL[i]))))
    end
  end
  
  -- LR waveform view
  if mode == 2 then
    screen.level(3)
    screen.move(0,5)
    screen.text("L")
    screen.move(0,64)
    screen.text("R")
    screen.move(0,2*height +1)
    screen.line(127,2*height +1)
    screen.stroke()
    screen.level(1)
    screen.move(0,height + 1)
    screen.line(127,height + 1)
    screen.move(0,3*height + 1)
    screen.line(127,3*height + 1)
    screen.stroke()
    screen.level(15)
    for i=1, window, 1 do
      screen.pixel(i, util.round((height + sampL[i] * height * level),1))
      screen.pixel(i, util.round((height * 3 + sampR[i] * height * level),1))
    end
  end

  -- L waveform view
  if mode == 3 then
    screen.level(3)
    screen.move(0,5)
    screen.text("L")
    screen.level(1)
    screen.move(0,2*height +1)
    screen.line(127,2*height +1)
    screen.stroke()
    screen.level(15)
    for i=1, window, 1 do
      screen.pixel(i, util.round((2 * height + sampL[i] * height * level * 2),1))
    end
  end
  
  -- R waveform view
  if mode == 4 then
    screen.level(3)
    screen.move(127,5)
    screen.text_right("R")
    screen.level(1)
    screen.move(0,2*height +1)
    screen.line(127,2*height +1)
    screen.stroke()
    screen.level(15)
    for i=1, window, 1 do
      screen.pixel(i, util.round((2 * height + sampR[i] * height * level * 2),1))
    end
  end

  screen.fill()
  
  --mode info overlay
  if mode_timer > 0 then
    screen.level(0)
    screen.rect(0,64,70,-10)
    screen.fill()
    --draw box outline?
    screen.level(15)
    if mode == 1 then screen.rect(1,64,68,-10) end
    if mode == 2 then screen.rect(1,64,82,-10) end
    if mode == 3 then screen.rect(1,64,77,-10) end
    if mode == 4 then screen.rect(1,64,78,-10) end
    screen.stroke()
    --draw text
    screen.level(8)
    screen.move(2,61)
    if mode == 1 then screen.text("Mode: Lissajous") end
    if mode == 2 then screen.text("Mode: LR Waveform") end
    if mode == 3 then screen.text("Mode: L Waveform") end
    if mode == 4 then screen.text("Mode: R Waveform") end
    mode_timer = mode_timer - 1
  end
  
  screen.update()
end

--timing
r = metro.init()
r.time = length --1/fps
r.event = function ()
  for i = 1,2 do 
    softcut.render_buffer(i,start,length,window)
  end
  redraw()
  enc_timer = enc_timer - 1
  if enc_timer < -1 then enc_timer = 0 end
end

function enc(n,d)
  if n==3 then
    level = level + d/10
    if level < 0.1 then level = 0.1 end
    level_timer = 20
  end
  if n==2 then
    for i=1,2 do zoom = zoom + d/10  end
    if zoom < 1 then zoom = 1 end
    for i=1,2 do softcut.rate(i,zoom) end
    zoom_timer = 20
  end
  if n==1 then
    if enc_timer < 0 then
      if d > 0 then
        mode = mode + 1
      elseif d < 0 then
        mode = mode -1
      end
      enc_timer = 3
    end
    mode_timer = 20
  end
  if mode < 1 then mode = 1 end
  if mode > 4 then mode = 4 end
end
