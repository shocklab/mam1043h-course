(* export_animations_v6.wl — Minimal overrides (ListAnimate / Animate only).
   Skip cells whose source text contains Manipulate[ or Dynamic[ to avoid hangs.
   Track Out[n] manually so ListAnimate[%] works (Unprotect Out first).
*)

nbDir = "/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H";
outBase = "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site/static/images";
dur = 0.12;
res = 100;
cellTimeout = 45;

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
captureFrames[other_] := Print["  [skip] ListAnimate arg head=", Head[other]];

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

(* Manual Out[] tracking. Out is Protected — unprotect it. *)
Unprotect[Out];

processNotebook[nbName_, partDir_] := Module[
  {nb, inputCells, startIdx, n, cellLine},
  $outDir = FileNameJoin[{outBase, partDir}];
  If[!DirectoryQ[$outDir], CreateDirectory[$outDir]];
  Print["\n=== ", partDir, " ==="];
  startIdx = $animIdx;

  nb = NotebookOpen[FileNameJoin[{nbDir, nbName}], Visible -> False];
  If[nb === $Failed, Print["  SKIP"]; Return[0]];

  inputCells = Cells[nb, CellStyle -> "Input"];
  n = Length[inputCells];
  Print["  Input cells: ", n];

  cellLine = 0;

  Do[
    Module[{cellExpr, srcStr, r},
      cellExpr = NotebookRead[inputCells[[i]]];
      If[Head[cellExpr] =!= Cell, Continue[]];
      srcStr = ToString[cellExpr[[1]], InputForm];

      (* Skip Manipulate / Dynamic / DynamicModule cells (hang-prone) *)
      If[StringContainsQ[srcStr, "Manipulate[" | "DynamicModule[" | "SlideView["],
        Print["  cell ", i, "/", n, ": SKIP (Manipulate/Dynamic/SlideView)"];
        Continue[]];

      cellLine++;
      r = TimeConstrained[
        Quiet[Check[ToExpression[cellExpr[[1]]], $Failed]],
        cellTimeout, $TimedOut];
      If[r === $TimedOut,
        Print["  cell ", i, "/", n, ": TIMED OUT"]];
      (* Populate Out[cellLine] so that % (=Out[$Line-1]) could work if $Line matches.
         To be safe we also assign Out[$Line] and increment $Line. *)
      If[r =!= $TimedOut && r =!= $Failed,
        Out[$Line] = r;
        $Line = $Line + 1];
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
