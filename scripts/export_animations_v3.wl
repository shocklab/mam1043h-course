(* export_animations_v3.wl — Evaluate notebooks in order; override ListAnimate
   and Animate to capture the list of frames; export each as GIF.
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

processNotebook[nbName_, partDir_] := Module[
  {nb, inputCells, outDir, animIdx, captured},
  outDir = FileNameJoin[{outBase, partDir}];
  If[!DirectoryQ[outDir], CreateDirectory[outDir]];
  Print["\n=== ", partDir, " ==="];

  nb = NotebookOpen[FileNameJoin[{nbDir, nbName}], Visible -> False];
  If[nb === $Failed, Print["  SKIP"]; Return[0]];
  inputCells = Cells[nb, CellStyle -> "Input"];
  Print["  Input cells: ", Length[inputCells]];

  animIdx = 0;

  (* Custom capturing function used inside overridden System functions.
     We want to capture ListAnimate[lst] with lst evaluated.
  *)
  Module[{$captureFn, ctx},
    ctx = "AnimCapture`";
    Unprotect[System`ListAnimate, System`Animate];
    ClearAll[System`ListAnimate, System`Animate];
    System`ListAnimate[lst_List, ___] := Module[{fname},
      animIdx++;
      fname = FileNameJoin[{outDir,
        "anim_" <> IntegerString[animIdx, 10, 3] <> ".gif"}];
      Quiet[Export[fname, lst, "GIF",
        "DisplayDurations" -> dur,
        "AnimationRepetitions" -> Infinity,
        ImageResolution -> res]];
      Print["  anim_", IntegerString[animIdx, 10, 3], ": ",
        Length[lst], " frames (ListAnimate)"];
      Null
    ];
    System`ListAnimate[other___] := (
      Print["  [skip] ListAnimate arg not a list, got Head=", Head[{other}[[1]]]];
      Null
    );
    System`Animate[body_, iter_List, ___] := Module[{frames, fname},
      frames = Quiet[Check[Table[body, iter], $Failed]];
      If[frames =!= $Failed && ListQ[frames] && Length[frames] >= 2,
        animIdx++;
        fname = FileNameJoin[{outDir,
          "anim_" <> IntegerString[animIdx, 10, 3] <> ".gif"}];
        Quiet[Export[fname, frames, "GIF",
          "DisplayDurations" -> dur,
          "AnimationRepetitions" -> Infinity,
          ImageResolution -> res]];
        Print["  anim_", IntegerString[animIdx, 10, 3], ": ",
          Length[frames], " frames (Animate)"];
      ];
      Null
    ];
    SetAttributes[System`Animate, HoldAll];
  ];

  Do[
    Module[{cellExpr},
      cellExpr = NotebookRead[inputCells[[i]]];
      If[Head[cellExpr] =!= Cell, Continue[]];
      Quiet[Check[ToExpression[cellExpr[[1]]], $Failed]];
    ],
    {i, Length[inputCells]}
  ];

  NotebookClose[nb];
  Print["  Total: ", animIdx, " GIF(s)"];
  animIdx
];

UsingFrontEnd[
  total = 0;
  Do[total += processNotebook[spec[[1]], spec[[2]]], {spec, notebooks}];
  Print["\n=== DONE: ", total, " GIFs total ==="];
];
