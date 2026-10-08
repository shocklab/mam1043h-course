(* export_animations_mam1043h.wl — Extract ListAnimate/Table animations from
   MAM1043H notebooks and export as animated GIFs.
*)

nbDir = "/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H";
outBase = "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site/static/images";
dur = 0.12;
res = 120;
multiplier = 2;

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

UsingFrontEnd[
  Do[
    {nbName, partDir} = spec;
    outDir = FileNameJoin[{outBase, partDir}];
    If[!DirectoryQ[outDir], CreateDirectory[outDir]];
    Print["\n=== ", partDir, " ==="];

    nb = NotebookOpen[FileNameJoin[{nbDir, nbName}], Visible -> False];
    If[nb === $Failed, Print["  SKIP (cannot open)"]; Continue[]];

    inputCells = Cells[nb, CellStyle -> "Input"];
    animIdx = 0;

    Do[
      cellExpr = NotebookRead[inputCells[[i]]];
      If[Head[cellExpr] =!= Cell, Continue[]];
      inner = cellExpr[[1, 1]];
      str = ToString[inner, InputForm];

      If[StringContainsQ[str, "ListAnimate"],
        exprs = If[Head[inner] === List, inner, {inner}];

        Do[
          If[StringQ[exprs[[j]]], Continue[]];
          exprStr = ToString[exprs[[j]], InputForm];
          If[StringContainsQ[exprStr, "ListAnimate"], Continue[]];

          expr = exprs[[j]];
          If[MatchQ[expr, RowBox[{_, ";"}]], expr = expr[[1, 1]]];

          held = Quiet[Check[
            ToExpression[BoxData[expr], StandardForm, Hold],
            $Failed]];
          If[held === $Failed, Continue[]];

          iterMatch = Cases[held,
            Hold[CompoundExpression[Table[_, iter_], Null]] |
            Hold[Table[_, iter_]] :> iter, {0}];

          If[Length[iterMatch] == 0,
            Quiet[ReleaseHold[held]];
            Continue[]
          ];

          iter = First[iterMatch];
          var = iter[[1]]; mn = iter[[2]]; mx = iter[[3]];
          stp = If[Length[iter] >= 4, iter[[4]], 1];
          origN = Round[N[(mx - mn) / stp]] + 1;
          If[origN < 0, origN = -origN];
          newStep = N[stp / multiplier];

          bodyMatch = Cases[held,
            Hold[CompoundExpression[Table[body_, _], Null]] |
            Hold[Table[body_, _]] :> Hold[body], {0}];

          If[Length[bodyMatch] == 0, Continue[]];

          newResult = Quiet[Check[
            Table[ReleaseHold[First[bodyMatch]], Evaluate[{var, mn, mx, newStep}]],
            $Failed]];

          If[!ListQ[newResult] || Length[newResult] < 3,
            Print["  Cell ", i, ": reconstruction failed (iter=", iter, ")"];
            Continue[]];

          animIdx++;
          fname = FileNameJoin[{outDir,
            "anim_" <> IntegerString[animIdx, 10, 3] <> ".gif"}];
          Quiet[Export[fname, newResult, "GIF",
            "DisplayDurations" -> dur,
            "AnimationRepetitions" -> Infinity,
            ImageResolution -> res]];
          Print["  anim_", IntegerString[animIdx, 10, 3], ": ",
            origN, " -> ", Length[newResult], " frames (",
            NumberForm[Length[newResult] * dur, {4, 1}], "s)"];,
          {j, Length[exprs]}
        ];,

        Quiet[Check[ToExpression[cellExpr[[1]]], $Failed]];
      ];,
      {i, Length[inputCells]}
    ];

    NotebookClose[nb];
    Print["  Done: ", animIdx, " GIF(s)"];,
    {spec, notebooks}
  ];
];

Print["\n=== ALL DONE ==="];
