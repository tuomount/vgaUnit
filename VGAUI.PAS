unit vgaui;
(*
 * Unit for drawing simple UI in VGA mode. This will require
 * VGA unit and will use procedures that handle double buffering
 * automatically.
*)
interface
uses vga, dos;

const
     (* Memory required for loading monochrome font
      * Fonts contain up to 127 characters size of 8x8 *)
     FONT_MEM_SIZE = 1016;
type
     (* Type definitions for font *)
     fontDataType = array[0..FONT_MEM_SIZE] of byte;
     fontDataPtr = ^fontDataType;
var  (*Pointer to default system font *)
     systemFont : fontDataPtr;

(*
 * Set text color for single color fonts
*)
procedure setColor(color : byte);
(*
 * Set text size in pixels. How many pixels
 * will be between different characters.
*)
procedure setTextSize(size : integer);
(*
 * Set font text pointer which is used for drawing text
 * @param ptr Font pointer
*)
procedure setFont(ptr : fontDataPtr);
(*
 * Initialize VGA UI. Reserved memory for all which is required
 * to use VGA UI unit. Assumes that VGA has initialized.
*)
procedure initVGAUI;
(*
 * Frees memory reserved for VGA UI. After calling this
 * VGA UI does not work anylonger.
*)
procedure shutdownVGAUI;
(*
 * Load font from the disk. Fonts are 127 characters 8x8
 * monochrome fonts.
 * @param buf Buffer where to load font
 * @param s Font file name
*)
procedure loadFont(var buf; s : string);
(*
 * Draws text to VGA. Uses previously loaded font.
 * @param x X coordinate, where drawing starts.
 * @param y Y coordinate where drawing starts.
 * @param s Text what to write.
*)
procedure putText(x,y : integer; s : string);
(*
 * Draws rectangle to vga.
 * @param x X coordinate
 * @param y Y coordinate
 * @param width Rectangle width
 * @param height Rectangle height
 * @param color Rectangle color
*)
procedure putRectangle(x, y, width, height : integer; color : byte);

implementation

var textColor : byte;
    textSize : byte;
    textFont : fontDataPtr;

procedure initVGAUI;
begin
  getmem(systemFont, FONT_MEM_SIZE);
  textColor := 15;
  textSize := 11;
end;
procedure shutdownVGAUI;
begin
  freemem(systemFont, FONT_MEM_SIZE);
end;
procedure setColor(color : byte);
begin
  textColor := color;
end;
procedure setTextSize(size : integer);
begin
  textSize := size;
end;
procedure setFont(ptr : fontDataPtr);
begin
  textFont := ptr;
end;
procedure loadFont(var buf; s : string);
var f : file;
begin
  assign(f,s);
  reset(f,FONT_MEM_SIZE);
  blockread(f,buf,1);
  close(f);
end;
procedure putRectangle(x, y, width, height : integer; color : byte);
begin
  putHLine(x,y,width,color);
  putVLine(x,y,height,color);
  putHLine(x,y+height-1,width,color);
  putVLine(x+width-1,y,height,color);
end;

procedure putCharacter(x,y : integer; index : byte);
var i,j : integer;
    offset : byte;
begin
  for j := 0 to 7 do
    for i := 0 to 7 do
    begin
      offset := 1;
      offset := offset shl i;
      if (textFont^[index*8+j] and offset = offset) then
      begin
        putPixel(x+i,y+j,textColor);
      end
    end;
end;

procedure drawCharacter(x,y : integer; index : byte; addr : word);
var textFontSeg, textFontOff : word;
    color : byte;
label nextRow, pixel0, pixel1, pixel2, pixel3, pixel4, pixel5, pixel6, pixel7;
begin
  if (x > -1) and (y > -1) and (x+8 < VGA_WIDTH) and (y+8 < VGA_HEIGHT) then
  begin
    textFontSeg := Seg(textFont^);
    textFontOff := Ofs(textFont^);
    color := textColor;
    asm
      push es
      push ds
      mov  ax,[addr]
      mov  es,ax
      mov  bx,[textFontSeg]
      mov  ds,bx
      (* Calculate pixel position *)
      mov  dx,[y]
      mov  bx,dx
      mov  dh,dl
      xor  dl,dl
      shl  bx,6
      add  dx,bx
      add  dx,[x]
      mov  di,dx
      (* Calculate font offset *)
      mov  bl,[index]
      xor  bh,bh
      shl  bx,3
      add  bx,[textFontOff]
      mov  si,bx
      mov  cl,8
      mov  al,[color]
      nextRow:
      mov  bl,1
      mov  dl,ds:[si]
      test dl,bl
      jz   pixel0
      mov  es:[di],al
      pixel0:
      inc  di
      shl  bl,1
      test dl,bl
      jz   pixel1
      mov  es:[di],al
      pixel1:
      inc  di
      shl  bl,1
      test dl,bl
      jz   pixel2
      mov  es:[di],al
      pixel2:
      inc  di
      shl  bl,1
      test dl,bl
      jz   pixel3
      mov  es:[di],al
      pixel3:
      inc  di
      shl  bl,1
      test dl,bl
      jz   pixel4
      mov  es:[di],al
      pixel4:
      inc  di
      shl  bl,1
      test dl,bl
      jz   pixel5
      mov  es:[di],al
      pixel5:
      inc  di
      shl  bl,1
      test dl,bl
      jz   pixel6
      mov  es:[di],al
      pixel6:
      inc  di
      shl  bl,1
      test dl,bl
      jz   pixel7
      mov  es:[di],al
      pixel7:
      add  di,313
      inc  si
      dec  cl
      cmp  cl,0
      jne  nextRow
      pop  ds
      pop  es
    end;
  end;
end;
procedure drawChar(x,y : integer; index : byte);
begin
  if isDoubleBuffer then
  begin
    drawCharacter(x,y,index,VGA_ADDR2);
  end
  else
  begin
    drawCharacter(x,y,index,VGA_ADDR);
  end;
end;


procedure putText(x,y : integer; s : string);
var a,i,index : byte;
begin
  i := 0;
  for a := 1 to length(s) do
  begin
    index := ord(s[a]);
    if (index < 127) then
    begin
      drawChar(x+i*textSize,y,index);
    end;
    inc(i);
  end;
end;

end.