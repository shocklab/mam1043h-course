(* export_animations_v7.wl — Override ListAnimate/Animate. Skip Manipulate/Dynamic
   by text-match. For cells whose ListAnimate arg is % (Out[n]) or an unbound
   symbol, fall back to $lastList — the most recent evaluated list of length >= 2.
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
$lastList = {};

exportFrames[lst_] := Module[{fname},
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

captureFrames[arg_] := Module[{lst},
  lst = Which[
    ListQ[arg] && Length[arg] >= 2, arg,
    Length[$lastList] >= 2, $lastList,
    True, Null
  ];
  If[lst === Null,
    Print["  (no frames available, arg head=", Head[arg], ")"];
    Return[Null]];
  exportFrames[lst];
];

Unprotect[System`ListAnimate];
ClearAll[System`ListAnimate];
System`ListAnimate[arg_, ___] := (captureFrames[arg]; Null);

Unprotect[System`Animate];
ClearAll[System`Animate];
SetAttributes[System`Animate, HoldAll];
System`Animate[body_, iter_List, ___] := Module[{frames},
  frames = Quiet[Check[Table[body, iter], $Failed]];
  If[frames =!= $Failed && ListQ[frames] && Length[frames] >= 2,
    $lastList = frames;
    exportFrames[frames]];
  Null
];

processNotebook[nbName_, partDir_] := Module[
  {nb, inputCells, startIdx, n},
  $outDir = FileNameJoin[{outBase, partDir}];
  If[!DirectoryQ[$outDir], CreateDirectory[$outDir]];
  Print["\n=== ", partDir, " ==="];
  startIdx = $animIdx;
  $lastList = {};

  nb = NotebookOpen[FileNameJoin[{nbDir, nbName}], Visible -> False];
  If[nb === $Failed, Print["  SKIP"]; Return[0]];

  inputCells = Cells[nb, CellStyle -> "Input"];
  n = Length[inputCells];
  Print["  Input cells: ", n];

  Do[
    Module[{cellExpr, srcStr, r},
      cellExpr = NotebookRead[inputCells[[i]]];
      If[Head[cellExpr] =!= Cell, Continue[]];
      srcStr = ToString[cellExpr[[1]], InputForm];

      If[StringContainsQ[srcStr, "Manipulate[" | "DynamicModule[" | "SlideView["],
        Continue[]];

      r = TimeConstrained[
        Quiet[Check[ToExpression[cellExpr[[1]]], $Failed]],
        cellTimeout, $TimedOut];

      (* If the cell result is a list of length >= 2, cache it for later % fallback *)
      If[ListQ[r] && Length[r] >= 2, $lastList = r];
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
