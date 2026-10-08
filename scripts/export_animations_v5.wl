(* export_animations_v5.wl — Evaluate Input cells sequentially via ToExpression
   while manually maintaining Out[n] / % so cells like ListAnimate[%] work.

   Key differences from v3/v4:
   - No SelectionEvaluate (avoids FrontEnd hangs)
   - We fake the In[]/Out[] history ourselves: after each cell, assign Out[n]=result
     and increment $Line so that % (= Out[$Line-1]) resolves correctly
   - Skip cells containing Manipulate/Dynamic (cannot be captured as a single GIF)
   - Per-cell timeout via TimeConstrained so one bad cell can't hang the whole run
*)

nbDir = "/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H";
outBase = "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site/static/images";
dur = 0.12;
res = 100;
cellTimeout = 30;  (* seconds per cell *)

notebooks = {
  {"MAM1043part1a.nb", "part1a"},
  {"MAM1043part1b.nb", "part1b"},
  {"MAM1043part1d.nb", "part1d"},
  {"MAM1043part1exercises.nb", "part1exercises"},
  {"MAM1043part2g.nb", "part2g"},
  {"MAM1043part3a.nb", "part3a"},
  {"MAM1043part3b.nb", "part3b"},
  {"MAM1043part3d.nb", "part3d"},
  {"MAM1043part4a.nb", "part4a"},
  {"MAM1043part4b.nb", "part4b"},
  {"MAM1043part4c.nb", "part4c"}
};

$animIdx = 0;
$outDir = ".";

captureFrames[lst_List] := Module[{fname},
  If[Length[lst] < 2, Return[Null]];
  $animIdx++;
  fname = FileNameJoin[{$outDir,
    "anim_" <> IntegerString[$animIdx, 10, 3] <> ".gif"}];
  Quiet[Export[fname, lst, "GIF",
    "DisplayDurations" -> dur,
    "AnimationRepetitions" -> Infinity,
    ImageResolution -> res]];
  Print["  anim_", IntegerString[$animIdx, 10, 3], ": ",
    Length[lst], " frames"];
];
captureFrames[_] := Null;

(* Override System`ListAnimate and System`Animate *)
Unprotect[System`ListAnimate];
ClearAll[System`ListAnimate];
System`ListAnimate[arg_, ___] := (captureFrames[arg]; Null);

Unprotect[System`Animate];
ClearAll[System`Animate];
SetAttributes[System`Animate, HoldAll];
System`Animate[body_, iter_List, ___] := Module[{frames},
  frames = Quiet[Check[Table[body, iter], $Failed]];
  If[frames =!= $Failed, captureFrames[frames]];
  Null
];

(* Neutralise Manipulate / Dynamic — don't evaluate them; they can hang *)
Unprotect[System`Manipulate];
ClearAll[System`Manipulate];
SetAttributes[System`Manipulate, HoldAll];
System`Manipulate[___] := Null;

Unprotect[System`Dynamic];
ClearAll[System`Dynamic];
SetAttributes[System`Dynamic, HoldAll];
System`Dynamic[___] := Null;

processNotebook[nbName_, partDir_] := Module[
  {nb, inputCells, startIdx, n, result, cellStr},
  $outDir = FileNameJoin[{outBase, partDir}];
  If[!DirectoryQ[$outDir], CreateDirectory[$outDir]];
  Print["\n=== ", partDir, " ==="];
  startIdx = $animIdx;

  nb = NotebookOpen[FileNameJoin[{nbDir, nbName}], Visible -> False];
  If[nb === $Failed, Print["  SKIP"]; Return[0]];

  inputCells = Cells[nb, CellStyle -> "Input"];
  Print["  Input cells: ", Length[inputCells]];
  n = Length[inputCells];

  (* Clear any prior Out[] history from previous notebook *)
  Clear[Out];
  $Line = 1;

  Do[
    Module[{cellExpr, line, r},
      cellExpr = NotebookRead[inputCells[[i]]];
      If[Head[cellExpr] =!= Cell, Continue[]];
      line = $Line;
      r = TimeConstrained[
        Quiet[Check[ToExpression[cellExpr[[1]]], $Failed]],
        cellTimeout, $TimedOut];
      If[r === $TimedOut,
        Print["  cell ", i, "/", n, ": TIMED OUT (", cellTimeout, "s)"]];
      (* Store in Out[] table so subsequent % / Out[n] references work *)
      If[r =!= $Failed && r =!= $TimedOut && r =!= Null,
        Out[line] = r];
      $Line = line + 1;
    ],
    {i, n}
  ];

  NotebookClose[nb];
  Print["  Total: ", $animIdx - startIdx, " GIF(s)"];
  $animIdx - startIdx
];

UsingFrontEnd[
  total = 0;
  Do[
    $animIdx = 0;
    total += processNotebook[spec[[1]], spec[[2]]],
    {spec, notebooks}
  ];
  Print["\n=== DONE: ", total, " GIFs total ==="];
];
