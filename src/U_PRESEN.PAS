unit u_presentation;
{
Auteur: Patrick Pr‚martin.
Date: 25/02/1991.
Langage: Turbo Pascal 6.0
But: Presentation de 'Strat‚gie Flore'.
}
interface
const
     vga256 = 19;

procedure presentation (titre : string; copyright : string);

implementation
uses
    crt,
    u_ppp;

procedure vsync;
begin
  while ((8 and port [$3da]) = 0) do;
end; { vsync }

function point (x, y : word) : byte;
begin
  {$r-}
  point := mem [$a000 : x+y*320];
  {$r+}
end; { point }

procedure pset (x, y : word; coul : byte);
begin
  if (point (x, y) > 0)
  then
    coul := 1;
  {endif}
  {$r-}
  mem [$a000 : x+y*320] := coul;
  {$r+}
end; { pset }

procedure run_demo;
var
   x,
   y : word;
   c : byte;
begin
  for x := 0 to 159 do
    for y := 0 to 99 do
      begin
        c := (x+y) mod 255 +1;
        if ((x in [156..159]) and (y in [96..99]))
        then
          if (c < 100)
          then
            c := 255 - c;
          {endif}
        {endif}
        pset (x, y, c);
        pset (x, 199 - y, c);
        pset (319 - x, 199 - y, c);
        pset (319 - x, y, c);
      end;
    {endfor}
  {endfor}
end;

procedure presentation (titre : string; copyright : string);
var
   old_pal,
   pal : p_ppp_pal;
   rvb : t_rvb_coul;
   carac : char;
   i : word;
   sens_inc,
   sens_inc2 : boolean;
begin
  if (not set_mode (vga256))
  then
    begin
      writeln ('VGA adapter needed...');
      halt (1);
    end
  else
    directvideo := false;
  {endif}
  old_pal := ppp_get_coul;

  pal := ppp_get_coul;
  for i := 0 to 255 do
    begin
      pal^ [i].r := 0;
      pal^ [i].v := 0;
      pal^ [i].b := 0;
    end;
  {endfor}
  ppp_set_coul (pal);
  textcolor (1);
  textbackground (0);
  gotoxy (15, 9);
  writeln ('Olf Software');
  gotoxy (17, 10);
  writeln ('presents');
  gotoxy (1+succ ((40 - length (titre)) div 2), 12);
  write (titre);
  gotoxy (1+succ ((40 - length (copyright)) div 2), 25);
  write (copyright);
  run_demo;
  while keypressed do
    carac := readkey;
  {endwhile}
  rvb.r := 0;
  rvb.v := 0;
  rvb.b := 0;
  sens_inc := true;
  sens_inc2 := true;
  while not keypressed do
    begin
{ Modification couleurs fond. }
      for i := 2 to 254 do
        pal^ [i] := pal ^[i+1];
      {endfor}
      pal^ [255].r := rvb.r;
      pal^ [255].v := rvb.v;
      pal^ [255].b := rvb.b;
      if (sens_inc)
      then
        begin
          inc (rvb.r);
          if (rvb.r > 63)
          then
            begin
              rvb.r := 63;
              inc (rvb.b);
              if (rvb.b > 63)
              then
                begin
                  rvb.b := 63;
                  inc (rvb.v);
                  if (rvb.v > 63)
                  then
                    begin
                      rvb.v := 63;
                      sens_inc := false;
                    end;
                  {endif}
                end;
              {endif}
            end;
          {endif}
        end
      else
        begin
          dec (rvb.v);
          if (rvb.v < 1)
          then
            begin
              rvb.v := 1;
              dec (rvb.b);
              if (rvb.b < 1)
              then
                begin
                  rvb.b := 1;
                  dec (rvb.r);
                  if (rvb.r < 1)
                  then
                    sens_inc := true;
                  {endif}
                end;
              {endif}
            end;
          {endif}
        end;
      {endif}
{ Modification couleur textes. }
      pal^ [1].r := 32;
      if (sens_inc2)
      then
        begin
          inc (pal^ [1].v);
          pal^ [1].b := 63 - pal^ [1].v;
          if (pal^ [1].v = 63)
          then
            sens_inc2 := false;
          {endif}
        end
      else
        begin
          dec (pal^ [1].v);
          pal^ [1].b := 63 - pal^ [1].v;
          if (pal^ [1].v = 0)
          then
            sens_inc2 := true;
          {endif}
        end;
      {endif}
{ Fin modifications. }
      ppp_set_coul (pal);
    end;
  {endwhile}
  carac := readkey;
  while keypressed do
    carac := readkey;
  {endwhile}
  ppp_set_coul (old_pal);
  dispose (old_pal);
  repeat
  until (set_mode (3));
end; { Presentation }

end. { U_Presentation }
