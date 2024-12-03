program strategie_flore;
{
Auteur: Patrick Pr‚martin.
Date: 27/02/1992. (1.0)
Langage: Turbo Pascal 6.0
But: Jeu en VGA 256 couleurs: 2 joueurs (dont ordinateur), chacun peut se
     d‚placer dans une ligne, ou une colonne. La partie s'arrŠte lorsqu'un des
     joueurs ne peut plus bouger. Le gagnant est celui qui aura gagn‚ le plus
     de points.
}
{$m 32768, 0, 655360}
uses
    crt,
    u_presentation,
    u_code_clavier,
    u_sai_donnee,
    u_ppp,
    u_curseur,
    u_m_util,
    u_aff_chaine,
    olf_software;

const
     dat_vers : string [10] = '02/27/1992';
     num_vers : string [3] = '1.0';
     nb_figure = 15; {33;}
     nb_fig_lig = 13;

type
    t_name = array [1..2] of string;
    t_posxy = record
                x, y : byte;
    end;
    t_coul = array [1..2] of byte;
    t_score = array [1..2] of word;
    t_ecran = array [1..7, 1..7] of byte;

var
   player : t_name;
   coul : t_coul;
   image : p_ppp;
   score : t_score;
   cad,
   ocad : t_posxy;
   ecran : t_ecran;
   sortie : boolean;

procedure saisie_nom;
var
   x, y : word;
   i : byte;
begin
  repeat
  until set_mode (0);
  textcolor (white);
  textbackground (black);
  clrscr;
  textcolor (yellow);
  affic_center_ln ('STRATEGIE FLORE');
  for i := 1 to 2 do
    begin
      writeln;
      textcolor (white);
      textbackground (black);
      write ('Name of player ', i, ' : ');
      textcolor (yellow);
      textbackground (coul [i]);
      x := wherex;
      y := wherey;
      repeat
        gotoxy (x, y);
        if (player [i] = '')
        then
          player [i] := 'COMPUTER';
        {endif}
        saisie_texte ('XXXXXXXXXX', player [i]);
      until (player [i] <> '');
      score [i] := 0;
    end;
  {endfor}
  writeln;
  if (not confirm ('Are the names OK ?'))
  then
    saisie_nom;
  {endif}
  curseur_off;
end; { Saisie_Nom }

procedure set_case (x, y : byte);
var
   i, j : byte;
   pt : ^byte;
   xf, yf : word;
begin
  if (ecran [x, y] = 0)
  then
    begin
      x := succ (pred (x) * 24) + 8;
      y := succ (pred (y) * 24) + 8;
      for j := 0 to 22 do
        for i := 0 to 22 do
          {$r-}
          mem [$a000: x+i+(y+j)*320] := 0;
          {$r+}
        {endfor}
      {endfor}
    end
  else
    begin
      xf := succ ((pred (ecran [x, y]) mod nb_fig_lig)*24);
      yf := succ ((pred (ecran [x, y]) div nb_fig_lig)*24);
      x := succ (pred (x) * 24) + 8;
      y := succ (pred (y) * 24) + 8;
      for j := 0 to 22 do
        begin
          pt := ptr (seg (image^.image^), ofs (image^.image^)+xf+(yf+j)*320);
          {$r-}
          move (pt^, ptr ($a000, x+(y+j)*320)^, 23);
          {$r+}
        end;
      {endfor}
    end;
  {endif}
end; { Set_Case }

procedure set_cadre (x, y : byte);
var
   i, j : word;
begin
  {$r-}
  x := pred (x) * 24 + 8;
  y := pred (y) * 24 + 8;
  if ((ocad.x = 0) and (ocad.y = 0))
  then
    begin
      ocad.x := x;
      ocad.y := y;
    end;
  {endif}
  if ((ocad.x <> x) or (ocad.y <> y))
  then
    begin
      for i := ocad.x to ocad.x+24 do
        begin
          mem [$a000: i+ocad.y*320] := 0;
          mem [$a000: i+(ocad.y+24)*320] := 0;
        end;
      {endfor}
      for j := ocad.y to ocad.y+24 do
        begin
          mem [$a000: ocad.x+j*320] := 0;
          mem [$a000: ocad.x+24+j*320] := 0;
        end;
      {endfor}
      ocad.x := x;
      ocad.y := y;
    end;
  {endif}
  for i := x to x+24 do
    begin
      mem [$a000: i+y*320] := 48 + (i+y) mod 16;
      mem [$a000: i+(y+24)*320] := 48 + (i+y+24) mod 16;
    end;
  {endfor}
  for j := y to y+24 do
    begin
      mem [$a000: x+j*320] := 48 + (x+j) mod 16;
      mem [$a000: x+24+j*320] := 48 + (x+24+j) mod 16;
    end;
  {endfor}
  {$r+}
end; { Set_Cadre }

procedure dessin_ecran;
var
   i, j : byte;
begin
  repeat
  until set_mode (vga256);
  for i := 32 to 47 do     { Couleurs du cadre de l'‚cran. }
    begin
      image^.palette^ [i].r := (i - 32) * 4;
      image^.palette^ [i].v := (i - 32) * 4;
      image^.palette^ [i].b := (i - 32) * 4;
    end;
  {endfor}
  for i := 48 to 63 do     { Couleurs du cadre de s‚lection. }
    begin
      image^.palette^ [i].r := (i - 48) * 4;
      image^.palette^ [i].v := 63 - (i - 48) * 4;
      image^.palette^ [i].b := 63 - (i - 48) * 4;
    end;
  {endfor}
  ppp_set_coul (image^.palette);
  {$r-}
  for i := 0 to 7*24+16 do
    for j := 0 to 7 do
      begin
        mem [$a000: i+j*320] := 32 + (i+j) mod 16;
        mem [$a000: i+(177+j)*320] := 32 + (i+j) mod 16;
        mem [$a000: j+i*320] := 32 + (i+j) mod 16;
        mem [$a000: (177+j)+i*320] := 32 + (i+j) mod 16;
      end;
    {endfor}
  {endfor}
  {$r+}
  for i := 1 to 7 do
    for j := 1 to 7 do
      begin
        ecran [i, j] := succ (random (nb_figure));
        set_case (i, j);
      end;
    {endfor}
  {endfor}
  ocad.x := 0;
  ocad.y := 0;
  set_cadre (4, 4);
  cad.x := 4;
  cad.y := 4;
  for i := 1 to 2 do
    begin
      textcolor (coul [i]);
      textbackground (black);
      gotoxy (30, pred (i)*3+1);
      write (player [i]);
      gotoxy (32, pred (i)*3+2);
      write (score [i] : 5);
    end;
  {endfor}
end; { Dessin_Ecran }

function joueur_bloque (num : byte) : boolean;
var
   i : byte;
   res : boolean;
begin
  res := true;
  case num of
    1 :
      for i := 1 to 7 do
        res := res and (ecran [i, cad.y] = 0);
      {endfor}
    2 :
      for i := 1 to 7 do
        res := res and (ecran [cad.x, i] = 0);
      {endfor}
  end;
  joueur_bloque := res;
end; { Joueur_Bloque }

procedure choix_computer (num : byte);
var
   i, j, k, sc_max : byte;
begin
  sc_max := 0;
  i := cad.x;
  j := cad.y;
  for k := 1 to 7 do
    if (num = 1)
    then
      begin
        if ((ecran [k, j] <> 0) and (sc_max < (succ (ecran [k, j] mod 5))))
        then
          begin
            sc_max := succ (ecran [k, j] mod 5);
            i := k;
          end
        {endif}
      end
    else
      begin
        if ((ecran [i, k] <> 0) and (sc_max < (succ (ecran [i, k] mod 5))))
        then
          begin
            sc_max := succ (ecran [i, k] mod 5);
            j := k;
          end
        {endif}
      end;
    {endif}
  {endfor}
  while ((i <> cad.x) or (j <> cad.y)) do
    begin
      if (cad.x < i)
      then
        inc (cad.x)
      else
        if (cad.x > i)
        then
          dec (cad.x);
        {endif}
      {endif}
      if (cad.y < j)
      then
        inc (cad.y)
      else
        if (cad.y > j)
        then
          dec (cad.y);
        {endif}
      {endif}
      set_cadre (cad.x, cad.y);
      delay (100);
    end;
  {endwhile}
  delay (200);
end; { Choix_Computer }

procedure choix_joueur (num : byte);
var
   c : char;
begin
  repeat
    c := readkey;
    if (c = carac_nul)
    then
      case num of
        1 :
          case readkey of
            touche_gauche :
              begin
                dec (cad.x);
                if (cad.x < 1)
                then
                  cad.x := 7;
                {endif}
              end;
            touche_droite :
              begin
                inc (cad.x);
                if (cad.x > 7)
                then
                  cad.x := 1;
                {endif}
              end;
          end;
        2 :
          case readkey of
            touche_haut :
              begin
                dec (cad.y);
                if (cad.y < 1)
                then
                  cad.y := 7;
                {endif}
              end;
            touche_bas :
              begin
                inc (cad.y);
                if (cad.y > 7)
                then
                  cad.y := 1;
                {endif}
              end;
          end;
      end
    else
      sortie := (c = touche_escape);
    {endif}
    set_cadre (cad.x, cad.y);
  until (((c = touche_return) and (ecran [cad.x, cad.y] <> 0)) or (sortie));
end; { Choix_Joueur }

procedure deplacement (num : byte);
begin
  gotoxy (1, 25);
  textcolor (coul [num]);
  textbackground (black);
  write (player [num], ' ');
  textcolor (white);
  if (num = 1)
  then
    write ('move on the line...          ')
  else
    write ('move on the column...          ');
  {endif}
  if (player [num] = 'COMPUTER')
  then
    choix_computer (num)
  else
    choix_joueur (num);
  {endif}
  score [num] := score [num] + succ (ecran [cad.x, cad.y] mod 5);
  ecran [cad.x, cad.y] := 0;
  set_case (cad.x, cad.y);
  textcolor (coul [num]);
  textbackground (black);
  gotoxy (32, pred (num)*3+2);
  write (score [num] : 5);
end; { Deplacement }

procedure jeu;
var
   num : byte;
begin
  saisie_nom;
  dessin_ecran;
  num := succ (random (2));
  sortie := false;
  while not (joueur_bloque (num) or sortie) do
    begin
      deplacement (num);
      if (keypressed)
      then
        sortie := (readkey = touche_escape);
      {endif}
      num := 3-num;
    end;
  {endwhile}
  score [3-num] := score [3-num] + 5; { Bonus pour avoir bloqu‚ l'adversaire }
  repeat
  until set_mode (0);
  if (score [1] > score [2])
  then
    num := 1
  else
    num := 2;
  {endif}
  writeln;
  textcolor (coul [num]);
  textbackground (black);
  write (player [num]);
  textcolor (white);
  write (' win with ');
  textcolor (coul [num]);
  write (score [num]);
  textcolor (white);
  writeln ('.');
  num := 3-num;
  textcolor (coul [num]);
  write (player [num]);
  textcolor (white);
  write (' has ');
  textcolor (coul [num]);
  write (score [num]);
  textcolor (white);
  writeln ('. But not enough...');
end; { Jeu }

begin
  checkbreak := false;
  randomize;
  init_licence ('GAMESTFL');
  init_olf_message (mess_shareware);
  init_olf_software ('Strat‚gie Flore '+num_vers, #155' Patrick Pr‚martin '+dat_vers);
  directvideo := false;
  image := ppp_load ('FLORE');
  if (image = nil)
  then
    begin
      writeln ('Loading Error: file FLORE.PPP is not in memory...');
      halt (1);
    end;
  {endif}
  coul [1] := blue;
  coul [2] := red;
  player [1] := '';
  player [2] := '';
  score [1] := 0;
  score [2] := 0;
  presentation ('Strat‚gie Flore '+num_vers, #155' Patrick Pr‚martin '+dat_vers);
  repeat
    curseur_off;
    jeu;
  until (not confirm ('Play again ?'));
  ppp_done (image);
  repeat
  until (set_mode (3));
  textcolor (lightgray);
  textbackground (black);
  clrscr;
  writeln ('See you later...');
  curseur_on;
end.
