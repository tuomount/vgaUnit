unit vga;

interface

(* VGA card base address *)
const VGA_ADDR = $a000;
(* VGA card second base address *)
const VGA_ADDR2 = $b000;
(* VGA width in pixels *)
const VGA_WIDTH = 320;
(* VGA height in pixels *)
const VGA_HEIGHT = 200;

(*
 * Initialize VGA mode.
*)
procedure initializeVgaMode;
(*
 * Initialize Text mode
*)
procedure initializeTextMode;
(*
 * All drawing operations happen on upper part of VGA memory.
 * Requires flipping before those are visible.
*)
procedure setDoubleBufferMode;
(*
 * All drawing operations happen on lower part of VGA memory.
 * These are immediately visible on screen.
*)
procedure setSingleBufferMode;
(*
 * Get ready for drawing. If double buffering is used then
 * this does not do anything. With single buffer this will
 * wait vertical sync.
*)
procedure readyDraw;
(*
 * All drawing is done for this frame.
 * If double buffering is used then that buffer will be shown
 * on screen after vertical sync.
*)
procedure doneDraw;
(*
 * Tells if double buffer mode is in use
*)
function isDoubleBuffer : boolean;
(*
 * Draw Pixel into address. Screen resolution must be 320x200.
 * @param x X coordinate
 * @param y Y coordinate
 * @param color Color value for pixel
 * @param addr Address value in memory where to draw
*)
procedure drawPixel(x, y : integer; color : byte; addr : word);
procedure putPixel(x, y : integer; color : byte);
(*
 * Get Pixel color value from memory address
 * @param x X coordinate
 * @param y Y coordinate
 * @param addr Memory address where to get pixel value.
 * @return Pixel color
*)
function getPixel(x, y : integer; addr : word) : byte;
function fetchPixel(x,y : integer) : byte;
(**
 * Fill VGA size screen with  certain color
 * @param color Color to fill
 * @param addr Address where to fill
*)
procedure clearScreen(color : byte; addr : word);
procedure clearBuffer(color : byte);
(*
 * Draw horizontal line.
 * @param x Starting X coordinate
 * @param y Starting Y coordinate
 * @param length Line length in pixels
 * @param color Which color is used for drawing
 * @param addr Address where to draw
*)
procedure drawHLine(x, y, length : integer;
                    color : byte; addr : word);
procedure putHLine(x, y, length : integer; color : byte);
(*
 * Draw vertical line.
 * @param x Starting X coordinate
 * @param y Starting Y coordinate
 * @param length Line length in pixels
 * @param color Which color is used for drawing
 * @param addr Address where to draw
*)
procedure drawVLine(x, y, length : integer;
                    color : byte; addr : word);
procedure putVLine(x, y, length : integer; color : byte);
(*
 * Draw filled bar.
 * @param x Starting X coordinate
 * @param y Starting Y coordinate
 * @param width Bar width
 * @param height Bar height
 * @param color Which color is used for drawing
 * @param addr Address where to draw
*)
procedure drawBar(x, y, width, height : integer;
                    color : byte; addr : word);
procedure putBar(x, y, width, height : integer; color : byte);
(*
 * Set VGA palette value for single color
 * @param color Color index which palette will be changed
 * @param r Red channel of color. Must be 0-63.
 * @param g Green channel of color. Must be 0-63.
 * @param b Blue channel of color. Must be 0-63.
*)
procedure setPalette(color : byte; r,g,b : byte);
(*
 * Get Palette value from VGA register.
 * @param color Color index which palette to get
 * @param r Red channel value from palette
 * @param g Green channel value from palette
 * @param b Blue channel value from palette
*)
procedure getPalette(color : byte; var r, g, b : byte);
(*
 * Wait for VGA vertical sync and then starting of draw.
*)
procedure waitVSync;


implementation

var doubleBuffer : byte;
(*
 * Initialize VGA mode.
*)
procedure initializeVgaMode; assembler;
asm
  mov  ax, 0013h
  int  10h
end;

(*
 * Initialize Text mode
*)
procedure initializeTextMode; assembler;
asm
  mov  ax, 0003h
  int  10h
end;

(*
 * All drawing operations happen on upper part of VGA memory.
 * Requires flipping before those are visible.
*)
procedure setDoubleBufferMode;
begin
  doubleBuffer := 1;
end;
(*
 * All drawing operations happen on lower part of VGA memory.
 * These are immediately visible on screen.
*)
procedure setSingleBufferMode;
begin
  doubleBuffer := 0;
end;
(*
 * Draw Pixel into address. Screen resolution must be 320x200.
 * @param x X coordinate
 * @param y Y coordinate
 * @param color Color value for pixel
 * @param addr Address value in memory where to draw
*)
procedure drawPixel(x, y : integer; color : byte; addr : word);
begin
  if (x > -1) and (y > -1) and (x < VGA_WIDTH) and (y < VGA_HEIGHT) then
  begin
    asm
      push es
      mov  ax,[addr]
      mov  es,ax
      mov  dx,[y]
      mov  bx,dx
      mov  dh,dl
      xor  dl,dl
      shl  bx,6
      add  dx,bx
      add  dx,[x]
      mov  di,dx
      mov  al,[color]
      mov  es:[di], al
      pop  es
    end;
  end;
end;
procedure putPixel(x, y : integer; color : byte);
begin
  if (doubleBuffer = 0) then
  begin
    drawPixel(x,y,color,VGA_ADDR);
  end
  else
  begin
    drawPixel(x,y,color,VGA_ADDR2);
  end;
end;


(*
 * Get Pixel color value from memory address
 * @param x X coordinate
 * @param y Y coordinate
 * @param addr Memory address where to get pixel value.
 * @return Pixel color
*)
function getPixel(x, y : integer; addr : word) : byte;
var color : byte;
begin
  if (x > -1) and (y > -1) and (x < VGA_WIDTH) and (y < VGA_HEIGHT) then
  begin
    asm
      push es
      mov  ax,[addr]
      mov  es,ax
      mov  dx,[y]
      mov  bx,dx
      mov  dh,dl
      xor  dl,dl
      shl  bx,6
      add  dx,bx
      add  dx,[x]
      mov  di,dx
      mov  al,es:[di]
      mov  [color], al
      pop  es
    end;
  end;
  getPixel := color;
end;
function fetchPixel(x, y : integer) : byte;
begin
  if (doubleBuffer = 1) then
  begin
    fetchPixel := getPixel(x,y,VGA_ADDR2);
  end
  else
  begin
    fetchPixel := getPixel(x,y,VGA_ADDR);
  end;
end;
(**
 * Fill VGA size screen with  certain color
 * @param color Color to fill
 * @param addr Address where to fill
*)
procedure clearScreen(color : byte; addr : word); assembler;
asm
  push es
  mov  cx, 32000
  cld
  mov  es, [addr]
  xor  di, di
  mov  al, [color]
  mov  ah, al
  rep  stosw
  pop  es
end;
procedure clearBuffer(color : byte);
begin
  if (doubleBuffer = 1) then
  begin
    clearScreen(color, VGA_ADDR2);
  end
  else
  begin
    clearScreen(color, VGA_ADDR);
  end;
end;
(*
 * Draw horizontal line.
 * @param x Starting X coordinate
 * @param y Starting Y coordinate
 * @param length Line length in pixels
 * @param color Which color is used for drawing
 * @param addr Address where to draw
*)
procedure drawHLine(x, y, length : integer;
                    color : byte; addr : word);
var len : integer;
begin
  if (x > -1) and (y > -1) and (x < VGA_WIDTH) and (y < VGA_HEIGHT) then
  begin
    len := length;
    if (len + x >= VGA_WIDTH) then
    begin
      len := VGA_WIDTH - x;
    end;
    asm
      push es
      mov  cx, [len]
      cld
      mov  es, [addr]

      (* Calculate correct position *)
      mov  dx,[y]
      mov  bx,dx
      mov  dh,dl
      xor  dl,dl
      shl  bx,6
      add  dx,bx
      add  dx,[x]
      mov  di,dx
      mov  al, [color]
      rep  stosb
      pop  es
    end;
  end;
end;
procedure putHLine(x, y, length : integer; color : byte);
begin
  if (doubleBuffer = 1) then
  begin
    drawHLine(x,y,length,color, VGA_ADDR2);
  end
  else
  begin
    drawHLine(x,y,length,color, VGA_ADDR);
  end;
end;
(*
 * Draw vertical line.
 * @param x Starting X coordinate
 * @param y Starting Y coordinate
 * @param length Line length in pixels
 * @param color Which color is used for drawing
 * @param addr Address where to draw
*)
procedure drawVLine(x, y, length : integer;
                    color : byte; addr : word);
label loop;
var len : integer;
begin
  if (x > -1) and (y > -1) and (x < VGA_WIDTH) and (y < VGA_HEIGHT) then
  begin
    len := length;
    if (len + y >= VGA_HEIGHT) then
    begin
      len := VGA_HEIGHT - y;
    end;
    asm
      push es
      mov  cx, [len]
      mov  es, [addr]

      (* Calculate correct position *)
      mov  dx,[y]
      mov  bx,dx
      mov  dh,dl
      xor  dl,dl
      shl  bx,6
      add  dx,bx
      add  dx,[x]
      mov  di,dx
      mov  al, [color]

      loop:
      mov  es:[di], al
      dec  cx
      add  di, 320
      cmp  cx, 0
      jnz  loop

      pop  es
    end;
  end;
end;
procedure putVLine(x, y, length : integer; color : byte);
begin
  if (doubleBuffer = 1) then
  begin
    drawVLine(x,y,length,color, VGA_ADDR2);
  end
  else
  begin
    drawVLine(x,y,length,color, VGA_ADDR);
  end;
end;

(*
 * Draw filled bar.
 * @param x Starting X coordinate
 * @param y Starting Y coordinate
 * @param width Bar width
 * @param height Bar height
 * @param color Which color is used for drawing
 * @param addr Address where to draw
*)
procedure drawBar(x, y, width, height : integer;
                    color : byte; addr : word);
label loop;
var wid, hei, lineOffset : integer;
begin
  if (x > -1) and (y > -1) and (x < VGA_WIDTH) and (y < VGA_HEIGHT) then
  begin
    wid := width;
    hei := height;
    if (hei + y >= VGA_HEIGHT) then
    begin
      hei := VGA_HEIGHT - y;
    end;
    if (wid + x >= VGA_WIDTH) then
    begin
      wid := VGA_WIDTH - x - 1;
    end;
    lineOffset := VGA_WIDTH - wid;
    asm
      push es
      mov  es, [addr]

      (* Calculate correct position *)
      mov  dx,[y]
      mov  bx,dx
      mov  dh,dl
      xor  dl,dl
      shl  bx,6
      add  dx,bx
      add  dx,[x]
      mov  di,dx
      mov  al, [color]

      mov  bx, [hei]
      loop:
      mov  cx, [wid]
      rep  stosb
      dec  bx
      add  di, [lineOffset]
      cmp  bx, 0
      jnz  loop

      pop  es
    end;
  end;
end;
procedure putBar(x,y,width,height : integer; color : byte);
begin
  if (doubleBuffer = 1) then
  begin
    drawBar(x,y,width,height,color,VGA_ADDR2);
  end
  else
  begin
    drawBar(x,y,width,height,color,VGA_ADDR);
  end;
end;
(*
 * Set VGA palette value for single color
 * @param color Color index which palette will be changed
 * @param r Red channel of color. Must be 0-63.
 * @param g Green channel of color. Must be 0-63.
 * @param b Blue channel of color. Must be 0-63.
*)
procedure setPalette(color : byte; r,g,b : byte); assembler;
asm
  mov  dx, 3c8h
  mov  al, [color]
  out  dx, al
  inc  dx
  mov  al, [r]
  out  dx, al
  mov  al, [g]
  out  dx, al
  mov  al, [b]
  out  dx, al
end;

(*
 * Get Palette value from VGA register.
 * @param color Color index which palette to get
 * @param r Red channel value from palette
 * @param g Green channel value from palette
 * @param b Blue channel value from palette
*)
procedure getPalette(color : byte; var r, g, b : byte);
var tr, tg, tb : byte;
begin
  asm
    mov  dx, 3c7h
    mov  al, [color]
    out  dx, al
    inc  dx
    inc  dx
    in   al, dx
    mov  [tr], al
    in   al, dx
    mov  [tg], al
    in  al, dx
    mov  [tb], al
  end;
  r := tr;
  g := tg;
  b := tb;
end;

(*
 * Wait for VGA vertical sync and then starting of draw.
*)
procedure waitVSync; assembler;
label vretrace, waitDraw;
asm
  mov  dx, 3dah
  vretrace:
  in   al, dx
  test al, 09h
  jnz  vretrace
  waitDraw:
  in   al, dx
  test al, 08h
  jz   waitDraw
end;

(*
 * Get ready for drawing. If double buffering is used then
 * this does not do anything. With single buffer this will
 * wait vertical sync.
*)
procedure readyDraw;
begin
  if (doubleBuffer = 0) then
  begin
    waitVSync;
  end;
end;
(*
 * All drawing is done for this frame.
 * If double buffering is used then that buffer will be shown
 * on screen after vertical sync.
*)
procedure doneDraw;
begin
  if (doubleBuffer = 1) then
  begin
    waitVSync;
    move (mem[VGA_ADDR2:0], mem[VGA_ADDR:0], 64000);
  end;
end;
function isDoubleBuffer : boolean;
begin
  isDoubleBuffer := false;
  if doubleBuffer = 1 then
  begin
    isDoubleBuffer := true;
  end;
end;

end.