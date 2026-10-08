(* export_animations_v8.wl — v3 + $lastList fallback. No text-match skips.
   ToExpression on Manipulate in a hidden notebook returns the Manipulate
   object (doesn't hang). Only Dynamic was the hang culprit in v4/v5.
*)

nbDir = "/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H";
outBase = "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site/static/images";
dur = 0.12;
res = 100;
cellTimeout = 60;

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

Unprotect[System`ListAnimate];
ClearAll[System`ListAnimate];
System`ListAnimate[lst_List, ___] := (
  If[Length[lst] >= 2, $lastList = lst; exportFrames[lst]];
  Null);
System`ListAnimate[other___] := Module[{arg},
  arg = {other}[[1]];
  If[Length[$lastList] >= 2,
    Print["  (fallback: arg head=", Head[arg], ", using $lastList)"];
    exportFrames[$lastList],
    Print["  (no frames available, arg head=", Head[arg], ")"]];
  Null];

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
    Module[{cellExpr, r},
      cellExpr = NotebookRead[inputCells[[i]]];
      If[Head[cellExpr] =!= Cell, Continue[]];

      r = TimeConstrained[
        Quiet[Check[ToExpression[cellExpr[[1]]], $Failed]],
        cellTimeout, $TimedOut];

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
