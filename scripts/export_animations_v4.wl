(* export_animations_v4.wl — Evaluate each Input cell via SelectionEvaluate
   so Out[n] / % are tracked. Override ListAnimate/Animate to capture frames.
*)

nbDir = "/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H";
outBase = "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site/static/images";
dur = 0.12;
res = 100;

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

(* Global animation counter (reset per notebook) *)
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

(* Override at kernel level *)
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

processNotebook[nbName_, partDir_] := Module[
  {nb, inputCells, startIdx},
  $outDir = FileNameJoin[{outBase, partDir}];
  If[!DirectoryQ[$outDir], CreateDirectory[$outDir]];
  Print["\n=== ", partDir, " ==="];
  startIdx = $animIdx;

  nb = NotebookOpen[FileNameJoin[{nbDir, nbName}], Visible -> False];
  If[nb === $Failed, Print["  SKIP"]; Return[0]];

  inputCells = Cells[nb, CellStyle -> "Input"];
  Print["  Input cells: ", Length[inputCells]];

  Do[
    SelectionMove[inputCells[[i]], All, Cell];
    Quiet[Check[SelectionEvaluate[nb], $Failed]];
    (* wait briefly for evaluation to settle *)
    Pause[0.05],
    {i, Length[inputCells]}
  ];

  NotebookClose[nb];
  Print["  Total: ", $animIdx - startIdx, " GIF(s)"];
  $animIdx - startIdx
];

UsingFrontEnd[
  total = 0;
  Do[
    $animIdx = 0;  (* reset per notebook so filenames are local *)
    total += processNotebook[spec[[1]], spec[[2]]],
    {spec, notebooks}
  ];
  Print["\n=== DONE: ", total, " GIFs total ==="];
];
