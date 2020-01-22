program demo;
uses vga,crt, vgaui;

procedure flip(src, dest : word);
begin
  move (mem[src:0], mem[dest:0], 64000);
end;
procedure testDraw;
var i,j : integer;
    color, r, g, b : byte;
begin
  for i := 0 to 100 do
  begin
    drawPixel(i,i,i,VGA_ADDR);
    color := getPixel(i,i,VGA_ADDR);
    drawPixel(i,i + 2, color, VGA_ADDR);
  end;
  readkey;
  for i := 20 to 100 do
  begin
    getPalette(i, r, g, b);
    setPalette(i, r,g,i div 2);
  end;
  for i := 100 downto 1 do
  begin
    setPalette(i, i div 2,0,0);
  end;
end;

procedure drawStarField;
var x : array[0..100] of integer;
    y : array[0..100] of integer;
    z : array[0..100] of integer;
    i : integer;
    divider : byte;
    color : byte;
    background : byte;
begin
  for i := 0 to 63 do
  begin
    setPalette(i,i,i,i);
  end;
  for i := 0 to 100 do
  begin
    x[i] := random(320) - 159;
    y[i] := random(200) - 99;
    if (i > 50) then
    begin
      z[i] := random(510) + 2;
    end
    else
    begin
      z[i] := random(253) + 2;
    end;
  end;
  repeat
    readyDraw;
    clearBuffer(0);
    for i := 0 to 100 do
    begin
      if (i > 50) then
      begin
        divider := z[i] div 8;
        color := 32 - divider div 2;
      end
      else
      begin
        divider := z[i] div 4;
        color := 64 - divider;
      end;
      if (divider = 0) then
      begin
        divider := 1;
      end;
      background := fetchPixel(160 + x[i] div divider,
        100 + y[i] div divider);
      if (color > background) then
      begin
        putPixel(160 + x[i] div divider, 100 + y[i] div divider, color);
      end;
      if (z[i] > 1) then
      begin
        dec(z[i]);
      end
      else
      begin
        x[i] := random(320) - 159;
        y[i] := random(200) - 99;
        z[i] := 255;
      end;
    end;
    doneDraw;
  until keypressed;
  readkey;
end;

procedure drawCopperBars;
var y : array[0..3] of integer;
    my : array[0..3] of integer;
    c : array[0..3] of integer;
    i : integer;
begin
  setPalette(0,0,0,0);
  setPalette(1,0,0,16);
  setPalette(2,0,0,32);
  setPalette(3,16,16,48);
  setPalette(4,32,32,63);
  setPalette(5,0,16,0);
  setPalette(6,0,32,0);
  setPalette(7,16,48,16);
  setPalette(8,32,63,32);
  setPalette(9,16,0,0);
  setPalette(10,32,0,0);
  setPalette(11,48,16,16);
  setPalette(12,63,32,32);
  setPalette(13,16,0,16);
  setPalette(14,32,0,32);
  setPalette(15,48,16,48);
  setPalette(16,63,32,63);
  y[0] := 0;
  my[0] := 1;
  c[0] := 1;
  y[1] := 16;
  my[1] := 1;
  c[1] := 5;
  y[2] := 32;
  my[2] := 1;
  c[2] := 9;
  y[3] := 48;
  my[3] := 1;
  c[3] := 13;
  repeat
    readyDraw;
    nosound;
    clearBuffer(0);
    for i := 0 to 3 do
    begin
      putHLine(0,y[i],319,c[i]);
      putHLine(0,y[i]+1,319,c[i]+1);
      putHLine(0,y[i]+2,319,c[i]+2);
      putHLine(0,y[i]+3,319,c[i]+3);
      putHLine(0,y[i]+4,319,c[i]+2);
      putHLine(0,y[i]+5,319,c[i]+2);
      putHLine(0,y[i]+6,319,c[i]+1);
      putHLine(0,y[i]+7,319,c[i]);
      y[i] := y[i] + my[i];
      if (y[i] > VGA_HEIGHT - 9) then
      begin
        y[i] := VGA_HEIGHT -9;
        my[i] := -2;
        sound(200);
      end;
      if (y[i] < 1) then
      begin
        y[i] := 0;
        my[i] := 1;
        sound(400);
      end;
    end;
    doneDraw;
  until keypressed;
  nosound;
  readkey;
end;

procedure drawVerticalBars;
var x : array[0..3] of integer;
    mx : array[0..3] of integer;
    c : array[0..3] of integer;
    i : integer;
begin
  setPalette(0,0,0,0);
  setPalette(1,0,0,16);
  setPalette(2,0,0,32);
  setPalette(3,16,16,48);
  setPalette(4,32,32,63);
  setPalette(5,0,16,0);
  setPalette(6,0,32,0);
  setPalette(7,16,48,16);
  setPalette(8,32,63,32);
  setPalette(9,16,0,0);
  setPalette(10,32,0,0);
  setPalette(11,48,16,16);
  setPalette(12,63,32,32);
  setPalette(13,16,0,16);
  setPalette(14,32,0,32);
  setPalette(15,48,16,48);
  setPalette(16,63,32,63);
  x[0] := 0;
  mx[0] := 1;
  c[0] := 1;
  x[1] := 16;
  mx[1] := 1;
  c[1] := 5;
  x[2] := 32;
  mx[2] := 1;
  c[2] := 9;
  x[3] := 48;
  mx[3] := 1;
  c[3] := 13;
  repeat
    readyDraw;
    nosound;
    clearBuffer(0);
    for i := 0 to 3 do
    begin
      putVLine(x[i],0,199,c[i]);
      putVLine(x[i]+1,0,199,c[i]+1);
      putVLine(x[i]+2,0,199,c[i]+2);
      putVLine(x[i]+3,0,199,c[i]+3);
      putVLine(x[i]+4,0,199,c[i]+2);
      putVLine(x[i]+5,0,199,c[i]+2);
      putVLine(x[i]+6,0,199,c[i]+1);
      putVLine(x[i]+7,0,199,c[i]);
      x[i] := x[i] + mx[i];
      if (x[i] > VGA_WIDTH - 9) then
      begin
        x[i] := VGA_WIDTH -9;
        mx[i] := -2;
        sound(200);
      end;
      if (x[i] < 1) then
      begin
        x[i] := 0;
        mx[i] := 1;
        sound(400);
      end;
    end;
    doneDraw;
  until keypressed;
  nosound;
  readkey;
end;

procedure barDemo;
var x,y,width, height : integer;
begin
  setPalette(0,0,0,0);
  setPalette(1,0,0,32);
  setPalette(2,0,32,0);
  setPalette(3,0,32,32);
  setPalette(4,32,0,0);
  setPalette(5,32,0,32);
  setPalette(6,32,32,0);
  setPalette(7,48,48,48);
  setPalette(8,32,32,32);
  setPalette(9,0,0,63);
  setPalette(10,0,63,0);
  setPalette(11,0,63,63);
  setPalette(12,63,0,0);
  setPalette(13,63,0,63);
  setPalette(14,63,63,0);
  setPalette(15,63,63,63);
  clearScreen(0, VGA_ADDR);
  repeat
    x := random(320);
    y := random(200);
    width := random(200);
    height := random(150);
    waitVSync;
    drawBar(x,y,width,height,random(16),VGA_ADDR);
  until keypressed;
  readkey;
end;

procedure fontDemo;
var miniFont : FontDataPtr;
begin
  loadFont(systemFont^, 'system.fnt');
  setFont(systemFont);
  readyDraw;
  clearBuffer(0);
  setPalette(1,48,0,48);
  setColor(1);
  setTextSize(8);
  putText(10,10,'Hello world, with system.fnt');
  putText(10,20,'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUu');
  getMem(miniFont, FONT_MEM_SIZE);
  loadFont(miniFont^, 'mini.fnt');
  setFont(miniFont);
  setTextSize(6);
  putText(10,30,'Hello world, with mini.fnt');
  putText(10,40,'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz');
  freeMem(miniFont, FONT_MEM_SIZE);
  doneDraw;
  readkey;
end;

procedure tileDemo;
const TILES = 1000;
var x : array[1..TILES] of integer;
    y : array[1..TILES] of integer;
    index : array[1..TILES] of byte;
    i : integer;
begin
  loadVGAPalette('default.pal');
  loadTiles('tiles.til');
  for i := 1 to TILES do
  begin
    x[i] := random(300);
    y[i] := random(189);
    index[i] := 0;
  end;
  repeat
    readyDraw;
    clearBuffer(0);
    for i := 1 to tiles do
    begin
      drawTile(x[i],y[i],index[i]);
      y[i] := y[i] +1;
      if (y[i] >= 190) then
      begin
        x[i] := random(300);
        y[i] := 0;
        index[i] := 0;
      end;
    end;
    doneDraw;
  until keypressed;
  readkey;
end;
begin
  setDoubleBufferMode;
  if (paramCount > 0) then
  begin
    if (paramStr(1) = '-sb') then
    begin
      setSingleBufferMode;
    end;
  end;
  randomize;
  clrscr;
  writeln('Hello world');
  readkey;
  initializeVgaMode;
  initVgaUI;
  testDraw;
  readkey;
  drawStarField;
  drawCopperBars;
  drawVerticalBars;
  barDemo;
  fontDemo;
  tileDemo;
  shutdownVgaUi;
  initializeTextMode;
  writeln('Back from VGA mode');
  readkey;
end.