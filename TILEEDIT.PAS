program Tile_Editor;
uses crt,vga,vgaui,dos;
type TileDataArray = array[0..255*10*10] of byte;
     TileDataPtr = ^TileDataArray;
var
    tileData : TileDataPtr;
    miniFont : fontDataPtr;
    message : array[0..5] of string[30];
    cursorx, cursory : integer;
    color : byte;
    index : byte;
    tagged : byte;
procedure drawBaseUI(ch : char);
var s : string;
    i : integer;
    r,g,b : byte;
begin
  putRectangle(10,10,10*5+2,10*5+2,14);
  setColor(15);
  setFont(systemFont);
  setTextSize(8);
  putText(100,10,'X:');
  Str(cursorx,s);
  putText(130,10,s);
  putText(100,20,'Y:');
  Str(cursory,s);
  putText(130,20,s);
  putText(100,30,'Index:');
  Str(index,s);
  putText(150,30,s);
  putText(100,40,'CH:');
  Str(ord(ch),s);
  putText(136,40,s);
  putText(100,50,'Tagged:');
  Str(tagged,s);
  putText(160,50,s);
  putRectangle(79,99,220,70,14);
  setFont(miniFont);
  setTextSize(6);
  for i := 0 to 5 do
  begin
    setColor(7);
    putText(85,100+i*10,message[i]);
  end;
  setColor(14);
  getPalette(color,r,g,b);
  putText(10,170,'R:');
  Str(r,s);
  putText(23,170,s);
  putText(10,176,'G:');
  Str(g,s);
  putText(23,176,s);
  putText(10,182,'B:');
  Str(b,s);
  putText(23,182,s);
  putText(40,170,'C:');
  Str(color,s);
  putText(53,170,s);
end;
procedure addNewMessage(s : string);
var i : integer;
begin
  for i := 5 downto 1 do
  begin
    message[i] := message[i-1];
  end;
  message[0] := s;
end;
procedure drawBigImage(x,y,size : integer);
var i,j : integer;
    drawColor : byte;
begin
  for j := 0 to 9 do
    for i := 0 to 9 do
    begin
      drawColor := tileData^[index*100+j*10+i];
      putBar(x+i*size,y+j*size,size,size,drawColor);
      if (cursorx = i) and (cursory = j) then
      begin
        putRectangle(x+i*size,y+j*size,size,size,14);
      end;
    end;
end;
procedure drawNormalImage(x,y : integer);
var i,j : integer;
    drawColor : byte;
begin
  for j := 0 to 9 do
    for i := 0 to 9 do
    begin
      drawColor := tileData^[index*100+j*10+i];
      putPixel(x+i,y+j,drawColor);
    end;
end;
procedure drawPalette(x,y : integer);
var i,j : integer;
    drawColor : byte;
begin
  drawColor := 0;
  for i := 0 to 15 do
  begin
    for j := 0 to 15 do
    begin
      putBar(x+i*3,y+j*3,3,3,drawColor);
      if (color = drawColor) then
      begin
        putHLine(x+i*3,y+j*3,3,15);
        putVLine(x+i*3,y+j*3,3,15);
        (*putRectangle(x+i*3,y+j*3,3,3,15);*)
      end;
      inc(drawColor)
    end;
  end;
end;
procedure loadTileFile(s : string);
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
procedure saveTileFile(s : string);
var f : file;
begin
  assign(f,s);
  rewrite(f,sizeOf(TileDataArray));
  blockwrite(f,tileData^,1);
  close(f);
end;
function byteToHex(value : byte) : string;
const
 hexChars: array [0..$F] of Char =
   '0123456789ABCDEF';
var tmp : string;
begin
  tmp := hexChars[value shr 4];
  tmp := tmp + hexChars[value and $F];
  byteToHex := tmp;
end;
procedure savePalette;
var f : Text;
    i,r,g,b : byte;
begin
  assign(f,'default.pal');
  rewrite(f);
  for i := 0 to 255 do
  begin
    getPalette(i,r,g,b);
    writeln(f,'#', byteToHex(r*4), byteToHex(g*4), byteToHex(b*4));
  end;
  close(f);
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
procedure loadPalette;
var f : Text;
    s : string;
    i,r,g,b : byte;
begin
  assign(f,'default.pal');
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

procedure mainLoop;
var ch : char;
    value : byte;
    currentValue : byte;
    i,j,tmp : byte;
    s : string;
    tmpTile : array[0..9,0..9] of byte;
    r,g,b : byte;
begin
  ch := #0;
  repeat
    readyDraw;
    clearBuffer(0);
    drawBaseUi(ch);
    drawBigImage(11,11,5);
    drawNormalImage(11,100);
    drawPalette(11,120);
    doneDraw;
    if (keypressed) then
    begin
      ch := readkey;
      case ch of
      #72: if (cursory > 0) then cursory := cursory -1;
      #75: if (cursorx > 0) then cursorx := cursorx -1;
      #77: if (cursorx < 9) then cursorx := cursorx +1;
      #80: if (cursory < 9) then cursory := cursory +1;
      #73: if (index < 255) then inc(index);
      #81: if (index > 0) then dec(index);
      (* F2 Save palette *)
      #60: begin
             savePalette;
             addNewMessage('Saved palette to default.pal');
           end;
      (* F10 Save tiles *)
      #68: begin
             saveTileFile(paramStr(1));
             addNewMessage('Saved tiles to ' + paramStr(1));
           end;
      '1': begin
             getPalette(color,r,g,b);
             if (r > 0) then
             begin
               dec(r);
             end;
             setPalette(color,r,g,b);
           end;
      '2': begin
             getPalette(color,r,g,b);
             if (r < 63) then
             begin
               inc(r);
             end;
             setPalette(color,r,g,b);
           end;
      '3': begin
             getPalette(color,r,g,b);
             if (g > 0) then
             begin
               dec(g);
             end;
             setPalette(color,r,g,b);
           end;
      '4': begin
             getPalette(color,r,g,b);
             if (g < 63) then
             begin
               inc(g);
             end;
             setPalette(color,r,g,b);
           end;
      '5': begin
             getPalette(color,r,g,b);
             if (b > 0) then
             begin
               dec(b);
             end;
             setPalette(color,r,g,b);
           end;
      '6': begin
             getPalette(color,r,g,b);
             if (b < 63) then
             begin
               inc(b);
             end;
             setPalette(color,r,g,b);
           end;
      '7': begin
             getPalette(color -1,r,g,b);
             setPalette(color,r,g,b);
           end;
      'z': dec(color);
      'x': inc(color);
      't': begin
             tagged := index;
             str(index,s);
             addNewMessage('Tagged font '+s);
           end;
      'a': begin
             for j := 0 to 9 do
             begin
               tmp := tileData^[index*100+j*10];
               for i := 0 to 8 do
               begin
                 tileData^[index*100+j*10+i] :=
                                             tileData^[index*100+j*10+i+1];
               end;
               tileData^[index*100+j*10+9] := tmp;
             end;
             addNewMessage('Tile moved left!');
           end;
      'd': begin
             for j := 0 to 9 do
             begin
               tmp := tileData^[index*100+j*10+9];
               for i := 9 downto 1 do
               begin
                 tileData^[index*100+j*10+i] :=
                                             tileData^[index*100+j*10+i-1];
               end;
               tileData^[index*100+j*10] := tmp;
             end;
             addNewMessage('Tile moved right!');
           end;
      'w': begin
             for i := 0 to 9 do
             begin
               tmp := tileData^[index*100+i];
               for j := 0 to 8 do
               begin
                 tileData^[index*100+j*10+i] :=
                                             tileData^[index*100+j*10+i+10];
               end;
               tileData^[index*100+9*10+i] := tmp;
             end;
             addNewMessage('Tile moved up!');
           end;
      's': begin
             for i := 0 to 9 do
             begin
               tmp := tileData^[index*100+i+90];
               for j := 9 downto 1 do
               begin
                 tileData^[index*100+j*10+i] :=
                                             tileData^[index*100+j*10+i-10];
               end;
               tileData^[index*100+i] := tmp;
             end;
             addNewMessage('Tile moved down!');
           end;
      'p': begin
             for j := 0 to 9 do
             begin
               for i := 0 to 9 do
               begin
                 tileData^[index*100+j*10+i] := tileData^[tagged*100+j*10+i];
               end;
             end;
             addNewMessage('Tile pasted!');
           end;
      'm': begin
             for j := 0 to 9 do
             begin
               for i := 0 to 9 do
               begin
                 tmpTile[i,j] := tileData^[index*100+j*10+i];
               end;
             end;
             for j := 0 to 9 do
             begin
               for i := 9 downto 0 do
               begin
                 tileData^[index*100+j*10+i] := tmpTile[9-i,j];
               end;
             end;
             addNewMessage('Tile mirrored!');
           end;
      'c': begin
             for j := 0 to 9 do
             begin
               for i := 0 to 9 do
               begin
                 tileData^[index*100+j*10+i] := color;
               end;
             end;
             addNewMessage('Tile cleared!');
           end;
      ' ': begin
             tileData^[index*100+cursory*10+cursorx] := color;
           end;
      'g': begin
             color := tileData^[index*100+cursory*10+cursorx];
           end;
      end;
    end
  until (ch = #27);
end;
begin
  if (paramCount = 0) then
  begin
    Writeln('Please give tile file name!');
    exit;
  end;
  color := 9;
  initializeVgaMode;
  initVGAUI;
  loadPalette;
  getMem(miniFont, FONT_MEM_SIZE);
  loadFont(systemFont^,'system.fnt');
  loadFont(miniFont^,'mini.fnt');
  getMem(tileData, 256*10*10);
  fillChar(tileData^, 256*10*10, 0);
  loadTileFile(paramStr(1));
  setFont(systemFont);
  setTextSize(8);
  setColor(15);
  setDoubleBuffermode;
  cursorx := 0;
  cursory := 0;
  index := 0;
  mainLoop;
  freeMem(tileData, 256*10*10);
  freeMem(miniFont, FONT_MEM_SIZE);
  shutdownVGAUI;
  initializeTextMode;
end.