program fonteditor;
uses crt,vga,vgaui,dos;
var fontData : array[0..127*8] of byte;
    miniFont : fontDataPtr;
    message : array[0..5] of string[30];
    cursorx, cursory : integer;
    color : byte;
    index : byte;
    tagged : byte;
procedure drawBaseUI(ch : char);
var s : string;
    i : integer;
begin
  putRectangle(10,10,8*5+2,8*5+2,14);
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
    offset : byte;
begin
  for j := 0 to 7 do
    for i := 0 to 7 do
    begin
      offset := 1;
      offset := offset shl i;
      if (fontData[index*8+j] and offset = offset) then
      begin
        putBar(x+i*size,y+j*size,size,size,color);
      end
      else
      begin
        putBar(x+i*size,y+j*size,size,size,0);
      end;
      if (cursorx = i) and (cursory = j) then
      begin
        putRectangle(x+i*size,y+j*size,size,size,14);
      end;
    end;
end;
procedure drawNormalImage(x,y : integer);
var i,j : integer;
    offset : byte;
begin
  for j := 0 to 7 do
    for i := 0 to 7 do
    begin
      offset := 1;
      offset := offset shl i;
      if (fontData[index*8+j] and offset = offset) then
      begin
        putPixel(x+i,y+j,color);
      end
      else
      begin
        putPixel(x+i,y+j,0);
      end;
    end;
end;
procedure loadFontFile(s : string);
var f : file;
begin
  assign(f,s);
  {$I-}
  reset(f,sizeOf(fontData));
  {$I+}
  if IoResult = 0 then
  begin
    blockread(f,fontData,1);
    close(f);
  end;
end;
procedure saveFontFile(s : string);
var f : file;
begin
  assign(f,s);
  rewrite(f,sizeOf(fontData));
  blockwrite(f,fontData,1);
  close(f);
end;

function flipNibble(value : byte) : byte;
begin
  case value of
  0: flipNibble := 0;
  1: flipNibble := 8;
  2: flipNibble := 4;
  3: flipNibble := 12;
  4: flipNibble := 2;
  5: flipNibble := 10;
  6: flipNibble := 6;
  7: flipNibble := 14;
  8: flipNibble := 1;
  9: flipNibble := 9;
  10: flipNibble := 5;
  11: flipNibble := 13;
  12: flipNibble := 3;
  13: flipNibble := 11;
  14: flipNibble := 7;
  15: flipNibble := 15;
  end;
end;
function rotateByte(value : byte) : byte;
var low, hi,result : byte;
begin
  hi := value and $f0;
  low := value and $0f;
  low := flipNibble(low);
  hi := hi shr 4;
  hi := flipNibble(hi);
  low := low shl 4;
  result := hi + low;
  rotateByte := result;
end;
function moveLeft(value : byte) : byte;
var result : byte;
begin
  asm
    mov  al,[value]
    ror  al,1
    mov  [result], al
  end;
  moveLeft := result;
end;
function moveRight(value : byte) : byte;
var result : byte;
begin
  asm
    mov  al,[value]
    rol  al,1
    mov  [result], al
  end;
  moveRight := result;
end;
procedure mainLoop;
var ch : char;
    value : byte;
    currentValue : byte;
    i,tmp : byte;
    s : string;
begin
  ch := #0;
  repeat
    readyDraw;
    clearBuffer(0);
    drawBaseUi(ch);
    drawBigImage(11,11,5);
    drawNormalImage(11,100);
    doneDraw;
    if (keypressed) then
    begin
      ch := readkey;
      case ch of
      #72: if (cursory > 0) then cursory := cursory -1;
      #75: if (cursorx > 0) then cursorx := cursorx -1;
      #77: if (cursorx < 7) then cursorx := cursorx +1;
      #80: if (cursory < 7) then cursory := cursory +1;
      #73: if (index < 126) then inc(index);
      #81: if (index > 0) then dec(index);
      #68: begin
             saveFontFile(paramStr(1));
             addNewMessage('Saved fonts to ' + paramStr(1));
           end;
      '1': color := 9;
      '2': color := 2;
      '3': color := 10;
      '4': color := 4;
      '5': color := 12;
      '6': color := 6;
      '7': color := 7;
      '8': color := 8;
      '9': color := 5;
      '0': color := 13;
      't': begin
             tagged := index;
             str(index,s);
             addNewMessage('Tagged font '+s);
           end;
      'a': begin
             for i := 0 to 7 do
             begin
               fontData[index*8+i] := moveLeft(fontData[index*8+i]);
             end;
             addNewMessage('Font moved left!');
           end;
      'd': begin
             for i := 0 to 7 do
             begin
               fontData[index*8+i] := moveRight(fontData[index*8+i]);
             end;
             addNewMessage('Font moved right!');
           end;
      'w': begin
             tmp := fontData[index*8];
             for i := 0 to 6 do
             begin
               fontData[index*8+i] := fontData[index*8+i+1];
             end;
             fontData[index*8+7] := tmp;
             addNewMessage('Font moved up!');
           end;
      's': begin
             tmp := fontData[index*8+7];
             for i := 7 downto 1 do
             begin
               fontData[index*8+i] := fontData[index*8+i-1];
             end;
             fontData[index*8] := tmp;
             addNewMessage('Font moved down!');
           end;
      'p': begin
             for i := 0 to 7 do
             begin
               fontData[index*8+i] := fontData[tagged*8+i];
             end;
             addNewMessage('Font pasted!');
           end;
      'm': begin
             for i := 0 to 7 do
             begin
               fontData[index*8+i] := rotateByte(fontData[index*8+i]);
             end;
             addNewMessage('Font mirrored!');
           end;
      'i': begin
             for i := 0 to 7 do
             begin
               fontData[index*8+i] := not fontData[index*8+i];
             end;
             addNewMessage('Font inverted!');
           end;
      'c': begin
             for i := 0 to 7 do
             begin
               fontData[index*8+i] := 0;
             end;
             addNewMessage('Font cleared!');
           end;
      ' ': begin
             value := 1;
             value := value shl cursorx;
             currentValue := fontData[index*8+cursory] and value;
             if (currentValue = 0) then
             begin
               fontData[index*8+cursory] := fontData[index*8+cursory]
                                            or value;
             end
             else
             begin
               value := not value;
               fontData[index*8+cursory] := fontData[index*8+cursory]
                                            and value;
             end;

           end;
      end;
    end
  until (ch = #27);
end;
begin
  if (paramCount = 0) then
  begin
    Writeln('Please give font file name!');
    exit;
  end
  else
  begin
    fillChar(fontData, 127*8, 0);
    loadFontFile(paramStr(1));
  end;
  color := 9;
  initializeVgaMode;
  initVGAUI;
  getMem(miniFont, FONT_MEM_SIZE);
  loadFont(systemFont^,'system.fnt');
  loadFont(miniFont^,'mini.fnt');
  setFont(systemFont);
  setTextSize(8);
  setColor(15);
  setDoubleBuffermode;
  cursorx := 0;
  cursory := 0;
  index := 0;
  mainLoop;
  freeMem(miniFont, FONT_MEM_SIZE);
  shutdownVGAUI;
  initializeTextMode;
end.