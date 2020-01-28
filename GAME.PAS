program game;
uses vga,vgaui,crt,dos;
const DIR_UP = 0;
      DIR_RIGHT = 1;
      DIR_DOWN = 2;
      DIR_LEFT = 3;
      TYPE_TANK = 0;
      TYPE_BULLET = 1;
      TYPE_ENEMY = 2;
      TYPE_BASE = 3;
      MAX_ENEMY = 30;
type MapType = record
       map : array[0..149,0..99] of byte;
     end;
     MapTypePtr = ^MapType;
     TankType = record
       x,y : integer;
       (* Direction 0 up, 1 right, 2 down, 3 left *)
       dir : integer;
       shot : byte;
       taip : byte;
       load : byte;
     end;
var
    map : MapTypePtr;
    miniFont : fontDataPtr;
    cyberFont : fontDataPtr;
    (* Tank Index *)
    ti : integer;
    base : ^TankType;
    tank : array[1..2] of ^TankType;
    bullet : ^TankType;
    enemy : array[1..MAX_ENEMY] of ^TankType;

procedure randomTerrainType(tileIndex,rtiles : byte; fields,amount : integer);
var i,j,k,n : integer;
    x,y,dir : integer;
begin
  n := random(fields)+10;
  for k := 1 to n do
  begin
    x := random(150);
    y := random(100);
    j := random(amount*3)+amount;
    for i := 0 to j do
    begin
      map^.map[x,y] := tileIndex+random(rtiles);
      dir := random(4);
      case dir of
      DIR_UP: if (y > 0) then y := y -1;
      DIR_LEFT: if (x > 0) then x := x -1;
      DIR_DOWN: if (y < 99) then y := y +1;
      DIR_RIGHT: if (x < 149) then x := x +1;
      end;
    end;
  end;
end;
procedure smoothTerrain(terrain, smooth, chance : byte);
var i,j,k : integer;
begin
  for i := 1 to 148 do
  begin
    for j := 1 to 98 do
    begin
      k := random(100);
      if (k < chance) and (map^.map[i,j] < 4) then
      begin
        if (map^.map[i-1,j] = terrain) then
          map^.map[i,j] := smooth;
        if (map^.map[i+1,j] = terrain) then
          map^.map[i,j] := smooth;
        if (map^.map[i,j-1] = terrain) then
          map^.map[i,j] := smooth;
        if (map^.map[i,j+1] = terrain) then
          map^.map[i,j] := smooth;
      end;
    end;
  end;
end;
function getFreeEnemyIndex : integer;
var i,index : integer;
begin
  index := -1;
  for i := 1 to MAX_ENEMY do
  begin
    if (enemy[i]^.x = -1) then
    begin
      index := i;
      i := MAX_ENEMY;
    end;
  end;
  getFreeEnemyIndex := index;
end;
procedure spawnEnemy;
var i,j,index : integer;
begin
  for i := 0 to 149 do
  begin
    for j := 0 to 99 do
    begin
      if (map^.map[i,j] = 15) and (random(10) = 0) then
      begin
        index := getFreeEnemyIndex;
        if (index <> -1) then
        begin
          enemy[index]^.x := i;
          enemy[index]^.y := j;
          enemy[index]^.taip := TYPE_ENEMY;
        end;
      end;
    end;
  end;
end;
procedure animMap;
var i,j : integer;
begin
  for i := 0 to 149 do
  begin
    for j := 0 to 99 do
    begin
      case map^.map[i,j] of
      6 : map^.map[i,j] := 7;
      7 : map^.map[i,j] := 6;
      8 : map^.map[i,j] := 9;
      9 : map^.map[i,j] := 8;
      end;
    end;
  end;
end;
procedure randomMap;
var i,j,k,n : integer;
    x,y,dir : integer;
begin
  for i := 0 to 149 do
  begin
    for j := 0 to 99 do
    begin
      map^.map[i,j] := random(2);
    end;
  end;
  (* Generate terrains *)
  (* Fields *)
  randomTerrainType(2,2,50,80);
  (* water *)
  randomTerrainType(6,2,30,120);
  smoothTerrain(6,7,50);
  smoothTerrain(7,6,50);
  (* lava *)
  randomTerrainType(8,2,10,20);
  (* Forest *)
  randomTerrainType(10,1,20,40);
  (* Mountains *)
  randomTerrainType(11,1,20,40);
  (* Smooth mountains *)
  smoothTerrain(11,4,100);
  smoothTerrain(4,5,25);
  (* Own base *)
  i := 0;
  repeat
    x := random(130)+10;
    y := random(85)+5;
    if (map^.map[x,y] < 4) then
    begin
      map^.map[x,y] := 14;
      tank[1]^.x := x-1;
      tank[1]^.y := y;
      tank[1]^.taip := TYPE_TANK;
      tank[2]^.x := x+1;
      tank[2]^.y := y;
      tank[2]^.taip := TYPE_TANK;
      base^.x := x;
      base^.y := y;
      base^.taip := TYPE_BASE;
      inc(i);
    end;
  until i = 1;
  (* Enemy bases *)
  i := 0;
  repeat
    x := random(130)+10;
    y := random(85)+5;
    if (map^.map[x,y] < 4) then
    begin
      map^.map[x,y] := 15;
      inc(i);
    end;
  until i = 5;
end;
procedure cyclePalette;
var i,r,g,b : byte;
    r2,g2,b2 : byte;
begin
  getPalette(48,r2,g2,b2);
  for i := 48 to 62 do
  begin
    getPalette(i+1,r,g,b);
    setPalette(i,r,g,b);
  end;
  setPalette(63,r2,g2,b2);
  getPalette(64,r2,g2,b2);
  for i := 64 to 78 do
  begin
    getPalette(i+1,r,g,b);
    setPalette(i,r,g,b);
  end;
  setPalette(79,r2,g2,b2);
end;
procedure drawMap(cx, cy, size, dx, dy : integer);
var x,y,i,j,k : integer;
begin
  i := 0;
  j := 0;
  if (cx < size) then
  begin
    cx := size;
  end;
  if (cy < size) then
  begin
    cy := size;
  end;
  if (cx > 149-size) then
  begin
    cx := 149-size;
  end;
  if (cy > 99-size) then
  begin
    cy := 99-size;
  end;
  for y := -size to size do
  begin
    inc(j);
    i := 0;
    for x := -size to size do
    begin
      inc(i);
      drawTile(dx+i*10,dy+j*10,map^.map[cx+x,cy+y]);
      for k := 1 to 2 do
      begin
        if (tank[k]^.x = cx+x) and (tank[k]^.y = cy+y) then
        begin
          if (tank[k]^.shot > 0) then
          begin
            case tank[k]^.dir of
            DIR_LEFT: drawSprite(dx+i*10,dy+j*10,67);
            DIR_UP: drawSprite(dx+i*10,dy+j*10,70);
            DIR_DOWN: drawSprite(dx+i*10,dy+j*10,72);
            DIR_RIGHT: drawSprite(dx+i*10,dy+j*10,66);
            end;
          end
          else
          begin
            case tank[k]^.dir of
            DIR_LEFT: drawSprite(dx+i*10,dy+j*10,68);
            DIR_UP: drawSprite(dx+i*10,dy+j*10,69);
            DIR_DOWN: drawSprite(dx+i*10,dy+j*10,71);
            DIR_RIGHT: drawSprite(dx+i*10,dy+j*10,65);
            end;
          end;
        end;
      end;
      for k := 1 to MAX_ENEMY do
      begin
        if (enemy[k]^.x = cx+x) and (enemy[k]^.y = cy+y) then
        begin
          if enemy[k]^.dir = 0 then
          begin
            drawSprite(dx+i*10,dy+j*10,81);
          end
          else
          begin
            drawSprite(dx+i*10,dy+j*10,82);
          end;
        end;
      end;
      if (bullet^.x = cx+x) and (bullet^.y = cy+y) then
      begin
        if (bullet^.shot > 0) then
        begin
          drawSprite(dx+i*10,dy+j*10,80-bullet^.shot);
        end
        else
        begin
          drawSprite(dx+i*10,dy+j*10,73);
        end;
      end;
    end;
  end;
end;
function isBlocked(x,y : integer; taip : byte) : boolean;
begin
  if (x >= 0) and (y >= 0) and (x < 150) and (y < 100) then
  begin
    if (taip = TYPE_TANK) then
      case map^.map[x,y] of
      0..3 : isBlocked := false;
      4..15 : isBlocked := true;
      end;
    if (taip = TYPE_BULLET) then
      case map^.map[x,y] of
      0..3,6..9 : isBlocked := false;
      4,5,10..15 : isBlocked := true;
      end;
    if (taip = TYPE_ENEMY) then
      case map^.map[x,y] of
      0..3 : isBlocked := false;
      4..15 : isBlocked := true;
      end;
  end
  else
  begin
    isBlocked := true;
  end;
end;
procedure shootTerrain(var obj : TankType; x,y : integer);
begin
  case map^.map[x, y] of
  4 : begin
        map^.map[x, y] := 5;
        obj.x := x;
        obj.y := y;
        obj.shot := 6;
      end;
  5 : begin
        map^.map[x, y] := 1;
        obj.x := x;
        obj.y := y;
        obj.shot := 6;
  end;
  10 : begin
         map^.map[x, y] := 1;
         obj.x := x;
         obj.y := y;
         obj.shot := 6;
  end;
  11 : begin
         map^.map[x, y] := 4;
         obj.x := x;
         obj.y := y;
         obj.shot := 6;
       end;
  15 : begin
         map^.map[x, y] := 5;
         obj.x := x;
         obj.y := y;
         obj.shot := 6;
       end;
  else
  begin
    obj.x := -1;
    obj.y := -1;
  end;
  end;
end;
procedure moveTank(var obj : TankType; direction : byte);
begin
  case direction of
  DIR_UP: begin
    if (obj.y > 0) and (isBlocked(obj.x,obj.y-1,obj.taip) = false) then
    begin
      obj.y := obj.y -1;
      obj.dir := DIR_UP;
    end
    else
    begin
      if (obj.taip = TYPE_TANK) then
        sound(50);
      if (obj.taip = TYPE_BULLET) then
      begin
        shootTerrain(obj,obj.x,obj.y-1);
      end;
    end;
  end;
  DIR_RIGHT: begin
    if (obj.x < 149) and (isBlocked(obj.x+1,obj.y,obj.taip) = false) then
    begin
      obj.x := obj.x +1;
      obj.dir := DIR_RIGHT;
    end
    else
    begin
      if (obj.taip = TYPE_TANK) then
        sound(50);
      if (obj.taip = TYPE_BULLET) then
      begin
        shootTerrain(obj,obj.x+1,obj.y);
      end;
    end;
  end;
  DIR_DOWN: begin
    if (obj.y < 99) and (isBlocked(obj.x,obj.y+1,obj.taip) = false) then
    begin
      obj.y := obj.y +1;
      obj.dir := DIR_DOWN;
    end
    else
    begin
      if (obj.taip = TYPE_TANK) then
        sound(50);
      if (obj.taip = TYPE_BULLET) then
      begin
        shootTerrain(obj,obj.x,obj.y+1);
      end;
    end;
  end;
  DIR_LEFT: begin
    if (obj.x > 0) and (isBlocked(obj.x-1,obj.y,obj.taip) = false) then
    begin
      obj.x := obj.x -1;
      obj.dir := DIR_LEFT;
    end
    else
    begin
      if (obj.taip = TYPE_TANK) then
        sound(50);
      if (obj.taip = TYPE_BULLET) then
      begin
        shootTerrain(obj,obj.x-1,obj.y);
      end;
    end;
  end;
  end;
end;
procedure handleBullet;
var i : integer;
begin
  if (bullet^.shot > 0) then
  begin
    dec(bullet^.shot);
    if (bullet^.shot = 0) then
     begin
       bullet^.x := -1;
       bullet^.y := -1;
     end;
  end;
  if (bullet^.x <> -1) and (bullet^.y <> -1) and (bullet^.shot = 0) then
  begin
    moveTank(bullet^,bullet^.dir);
    for i := 1 to MAX_ENEMY do
    begin
      if (bullet^.x = enemy[i]^.x) and (bullet^.y = enemy[i]^.y) then
      begin
        enemy[i]^.x := -1;
        enemy[i]^.y := -1;
        bullet^.shot := 6;
      end;
    end;
    if (bullet^.shot = 0) and (bullet^.load > 0) then
      dec(bullet^.load);
    if (bullet^.load = 0) then
    begin
      bullet^.x := -1;
      bullet^.y := -1;
    end;
  end;
end;
procedure handleTank(i : integer);
begin
  if (tank[i]^.load > 0) then
  begin
    dec(tank[i]^.load);
  end;
  if (tank[i]^.shot > 0) then
  begin
    dec(tank[i]^.shot);
    sound(50+tank[i]^.shot*10);
  end
end;
procedure handleEnemy(fIndex, tIndex : integer);
var i,mx,my,move : integer;
    dir : byte;
begin
  for i := fIndex to tIndex do
  begin
    if (enemy[i]^.x <> -1) then
    begin
      mx := base^.x - enemy[i]^.x;
      my := base^.y - enemy[i]^.y;
    end;
    move := random(3);
    dir := random(4);
    if (move = 0) then
    begin
      if (mx < 0) then
        dir := DIR_LEFT;
      if (mx > 0) then
        dir := DIR_RIGHT;
    end;
    if (move = 1) then
    begin
      if (my < 0) then
        dir := DIR_UP;
      if (my > 0) then
        dir := DIR_DOWN;
    end;
    moveTank(enemy[i]^,dir);
    enemy[i]^.dir := random(2);
  end;
end;
procedure mainLoop;
var ch : char;
    x, y,i : integer;
    timer : byte;
begin
  bullet^.x := -1;
  bullet^.y := -1;
  bullet^.taip := TYPE_BULLET;
  tank[1]^.dir := random(4);
  tank[1]^.taip := TYPE_TANK;
  tank[2]^.dir := random(4);
  tank[2]^.taip := TYPE_TANK;
  ti := 1;
  for i := 1 to MAX_ENEMY do
  begin
    enemy[i]^.x := -1;
    enemy[i]^.taip := TYPE_ENEMY;
  end;
  timer := 0;
  repeat
    inc(timer);
    if (timer = 1) then
    begin
      spawnEnemy;
      handleEnemy(1,10);
    end;
    if (timer = 4) then
    begin
      handleEnemy(11,20);
    end;
    if (timer = 8) then
    begin
      handleEnemy(21,30);
    end;
    if (timer = 5) then
    begin
      handleBullet;
    end;
    if (timer = 10) then
    begin
      animMap;
      cyclePalette;
      timer := 0;
      handleTank(1);
      handleTank(2);
      if (tank[1]^.shot = 0) and (tank[2]^.shot = 0) then
        nosound;
    end;
    readyDraw;
    clearBuffer(0);
    drawMap(base^.x,base^.y,4,10,10);
    drawMap(tank[1]^.x,tank[1]^.y,4,110,10);
    drawMap(tank[2]^.x,tank[2]^.y,4,210,10);
    doneDraw;
    if (keypressed) then
    begin
      ch := readkey;
      case ch of
      '1': ti := 1;
      '2': ti := 2;
      #72: moveTank(tank[ti]^, DIR_UP);
      #75: moveTank(tank[ti]^, DIR_LEFT);
      #77: moveTank(tank[ti]^, DIR_RIGHT);
      #80: moveTank(tank[ti]^, DIR_DOWN);
      ' ': begin
             if (tank[ti]^.load = 0) then
             begin
               sound(200);
               tank[ti]^.shot := 5;
               tank[ti]^.load := 5;
               bullet^.x := tank[ti]^.x;
               bullet^.y := tank[ti]^.y;
               bullet^.dir := tank[ti]^.dir;
               bullet^.shot := 0;
               bullet^.load := 5;
             end;
           end;
      end;
    end;
  until ch = #27;
  nosound;
end;
procedure reserveMemory;
var i : integer;
begin
  getMem(base, sizeOf(TankType));
  getMem(tank[1], sizeOf(TankType));
  getMem(tank[2], sizeOf(TankType));
  getMem(bullet, sizeOf(TankType));
  for i := 1 to MAX_ENEMY do
    getMem(enemy[i], sizeOf(TankType));
end;
procedure freeMemory;
var i : integer;
begin
  freeMem(base, sizeOf(TankType));
  freeMem(tank[1], sizeOf(TankType));
  freeMem(tank[2], sizeOf(TankType));
  freeMem(bullet, sizeOf(TankType));
  for i := 1 to MAX_ENEMY do
    freeMem(enemy[i], sizeOf(TankType));
end;
begin
  randomize;
  initializeVgaMode;
  initVGAUI;
  loadVGAPalette('default.pal');;
  getMem(miniFont, FONT_MEM_SIZE);
  getMem(cyberFont, FONT_MEM_SIZE);
  getMem(map, sizeOf(MapType));
  reserveMemory;
  loadFont(systemFont^,'system.fnt');
  loadFont(miniFont^,'mini.fnt');
  loadFont(cyberFont^,'cyber.fnt');
  loadTiles('game.til');
  setFont(systemFont);
  setTextSize(8);
  setColor(15);
  setDoubleBuffermode;
  randomMap;
  mainLoop;
  freeMemory;
  freeMem(map, sizeOf(MapType));
  freeMem(miniFont, FONT_MEM_SIZE);
  freeMem(cyberFont, FONT_MEM_SIZE);
  shutdownVGAUI;
  initializeTextMode;
end.