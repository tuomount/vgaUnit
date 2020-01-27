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
(*
 * Load VGA palette from file.
 * Each palette value must be on separate row and start #.
 * Channels are in order red,green and blue. Values are 0-ffh
 * @param filename Palette filename to load
*)
procedure loadVGAPalette(filename : string);
(*
 * Loads 256x10x10 tiles to memory.
 * @param s Filename for tile file.
*)
procedure loadTiles(s : string);
(*
 * Draw tile to screen.
 * @param x X Coordinate
 * @param y Y Coordinate
 * @param index Tile index
*)
procedure drawTile(x,y : integer; index : byte);
(*
 * put sprite where color 0 is transparent.
 * @param x X Coordinate
 * @param y Y Coordinate
 * @param index Tile index
*)
procedure drawSprite(x,y : integer; index : byte);

implementation

type TileDataArray = array[0..255*10*10] of byte;
     TileDataPtr = ^TileDataArray;

var textColor : byte;
    textSize : byte;
    textFont : fontDataPtr;
    tileData : TileDataPtr;

procedure initVGAUI;
begin
  getmem(systemFont, FONT_MEM_SIZE);
  getMem(tileData, 256*10*10);
  fillChar(tileData^, 256*10*10, 0);
  textColor := 15;
  textSize := 11;
end;
procedure shutdownVGAUI;
begin
  freemem(tileData, 256*10*10);
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

procedure drawCharacter(x,y : integer; index : byte; addr : word);
var textFontSeg, textFontOff : word;
    color : byte;
label nextRow, pixel0, pixel1, pixel2, pixel3, pixel4, pixel5, pixel6, pixel7;
begin
  if (x > -1) and (y > -1) and (x+7 < VGA_WIDTH) and (y+7 < VGA_HEIGHT) then
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

function hexToByte(hex : char) : byte;
begin
  hex := upCase(hex);
  case hex of
  '0': hexToByte := 0;
  '1': hexToByte := 1;
  '2': hexToByte := 2;
  '3': hexToByte := 3;
  '4': hexToByte := 4;
  '5': hexToByte := 5;
  '6': hexToByte := 6;
  '7': hexToByte := 7;
  '8': hexToByte := 8;
  '9': hexToByte := 9;
  'A': hexToByte := 10;
  'B': hexToByte := 11;
  'C': hexToByte := 12;
  'D': hexToByte := 13;
  'E': hexToByte := 14;
  'F': hexToByte := 15;
  end;
end;
procedure loadVGAPalette(filename : string);
var f : Text;
    s : string;
    i,r,g,b : byte;
begin
  assign(f,filename);
  reset(f);
  i := 0;
  while not eof(f) do
  begin
    readln(f,s);
    if (pos('#',s) = 1) and (Length(s) = 7) then
    begin
      r :=  hexToByte(s[2]) shl 4;
      r := r + hexToByte(s[3]);
      g :=  hexToByte(s[4]) shl 4;
      g := g + hexToByte(s[5]);
      b :=  hexToByte(s[6]) shl 4;
      b := b + hexToByte(s[7]);
      r := r shr 2;
      g := g shr 2;
      b := b shr 2;
      setPalette(i,r,g,b);
      i := i +1;
    end;
  end;
  close(f);
end;
procedure loadTiles(s : string);
var f : file;
begin
  assign(f,s);
  {$I-}
  reset(f,sizeOf(TileDataArray));
  {$I+}
  if IoResult = 0 then
  begin
    blockread(f,tileData^,1);
    close(f);
  end;
end;
procedure putTile(x,y : integer; index : byte; addr : word);
label startRow, column;
var tileSeg, tileOff : word;
begin
  if (x > -1) and (y > -1) and (x+9 < VGA_WIDTH) and (y+9 < VGA_HEIGHT) then
  begin
    tileSeg := Seg(tileData^);
    tileOff := Ofs(tileData^);
    asm
      push es
      push ds
      mov  ax,[addr]
      mov  es,ax
      mov  bx,[tileSeg]
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
      (* Calculate tile offset *)
      mov  bl,[index]
      xor  bh,bh
      shl  bx,6
      mov  cl,[index]
      xor  ch,ch
      shl  cx,5
      add  bx,cx
      mov  cl,[index]
      xor  ch,ch
      shl  cx,2
      add  bx,cx
      (*With multiplication*)
      (*mov  al,[index]
      xor  ah,ah
      mov  cx,100
      mul  cx
      mov  bx,ax*)
      add  bx,[tileOff]
      mov  si,bx
      mov  ch,10
      startRow:
      mov  cl,5
      column:
      mov  ax,ds:[si]
      mov  es:[di],ax
      add  si,2
      add  di,2
      dec  cl
      cmp  cl,0
      jnz  column
      add  di,310
      dec  ch
      cmp  ch,0
      jnz  startRow
      pop  ds
      pop  es
    end;
  end;
end;
procedure drawTile(x,y : integer; index : byte);
var i,j : integer;
    drawColor : byte;
    addr : word;
begin
  if isDoubleBuffer then
  begin
    addr := VGA_ADDR2;
  end
  else
  begin
    addr := VGA_ADDR;
  end;
  putTile(x,y,index,addr);
(*  for j := 0 to 9 do
    for i := 0 to 9 do
    begin
      drawColor := tileData^[index*100+j*10+i];
      drawPixel(x+i,y+j,drawColor,addr);
    end;*)
end;
procedure putSprite(x,y : integer; index : byte; addr : word);
label startRow, column, transparent;
var tileSeg, tileOff : word;
begin
  if (x > -1) and (y > -1) and (x+9 < VGA_WIDTH) and (y+9 < VGA_HEIGHT) then
  begin
    tileSeg := Seg(tileData^);
    tileOff := Ofs(tileData^);
    asm
      push es
      push ds
      mov  ax,[addr]
      mov  es,ax
      mov  bx,[tileSeg]
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
      (* Calculate tile offset *)
      mov  bl,[index]
      xor  bh,bh
      shl  bx,6
      mov  cl,[index]
      xor  ch,ch
      shl  cx,5
      add  bx,cx
      mov  cl,[index]
      xor  ch,ch
      shl  cx,2
      add  bx,cx
      (*With multiplication*)
      (*mov  al,[index]
      xor  ah,ah
      mov  cx,100
      mul  cx
      mov  bx,ax*)
      add  bx,[tileOff]
      mov  si,bx
      mov  ch,10
      startRow:
      mov  cl,10
      column:
      mov  al,ds:[si]
      cmp  al,0
      je   transparent
      mov  es:[di],al
      transparent:
      add  si,1
      add  di,1
      dec  cl
      cmp  cl,0
      jnz  column
      add  di,310
      dec  ch
      cmp  ch,0
      jnz  startRow
      pop  ds
      pop  es
    end;
  end;
end;
procedure drawSprite(x,y : integer; index : byte);
var i,j : integer;
    drawColor : byte;
    addr : word;
begin
  if isDoubleBuffer then
  begin
    addr := VGA_ADDR2;
  end
  else
  begin
    addr := VGA_ADDR;
  end;
  putSprite(x,y,index,addr);
(*  for j := 0 to 9 do
    for i := 0 to 9 do
    begin
      drawColor := tileData^[index*100+j*10+i];
      if (drawColor <> 0) then
        drawPixel(x+i,y+j,drawColor,addr);
    end;*)
end;

end.