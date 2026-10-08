(* export_animations_smooth.wl — Re-export all automated animations
   with 4x the frame count for smoother playback.

   Approach: evaluate notebook cells, find Table+ListAnimate patterns,
   extract the Table body and iterator, reconstruct with finer step.
*)

nbDir = "/Users/jonathanshock/Cursor folders/Teaching/MAM2046";
outBase = "/Users/jonathanshock/Cursor folders/Teaching/MAM2046-site/static/images";
dur = 0.12;
res = 120;
multiplier = 4;

notebooks = {
  {"MAM20462NDpart14-2.nb", "part14-2"},
  {"MAM20462NDpart16.nb", "part16"},
  {"MAM20462NDpart23.nb", "part23"},
  {"MAM20462NDpart32.nb", "part32"},
  {"MAM20462NDpart33.nb", "part33"},
  {"MAM20462NDpart34.nb", "part34"}
};

UsingFrontEnd[
  Do[
    {nbName, partDir} = spec;
    outDir = FileNameJoin[{outBase, partDir}];
    Print["\n=== ", partDir, " ==="];

    nb = NotebookOpen[FileNameJoin[{nbDir, nbName}], Visible -> False];
    If[nb === $Failed, Print["  SKIP"]; Continue[]];

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

          (* Find Table iterator *)
          iterMatch = Cases[held,
            Hold[CompoundExpression[Table[_, iter_], Null]] |
            Hold[Table[_, iter_]] :> iter, {0}];

          If[Length[iterMatch] == 0,
            (* Not a Table — evaluate as definition *)
            Quiet[ReleaseHold[held]];
            Continue[]
          ];

          iter = First[iterMatch];
          var = iter[[1]]; mn = iter[[2]]; mx = iter[[3]]; stp = iter[[4]];
          origN = Round[N[(mn - mx) / stp]] + 1;
          If[origN < 0, origN = -origN];
          newStep = N[stp / multiplier];

          (* Extract Table body *)
          bodyMatch = Cases[held,
            Hold[CompoundExpression[Table[body_, _], Null]] |
            Hold[Table[body_, _]] :> Hold[body], {0}];

          If[Length[bodyMatch] == 0, Continue[]];

          (* Reconstruct Table with finer step *)
          newResult = Quiet[Check[
            Table[ReleaseHold[First[bodyMatch]], Evaluate[{var, mn, mx, newStep}]],
            $Failed]];

          If[!ListQ[newResult] || Length[newResult] < 3,
            Print["  Cell ", i, ": reconstruction failed"];
            Continue[]];

          animIdx++;
          fname = FileNameJoin[{outDir,
            "anim_" <> IntegerString[animIdx, 10, 3] <> ".gif"}];
          Export[fname, newResult, "GIF",
            "DisplayDurations" -> dur,
            "AnimationRepetitions" -> Infinity,
            ImageResolution -> res];
          Print["  anim_", IntegerString[animIdx, 10, 3], ": ",
            origN, " -> ", Length[newResult], " frames (",
            NumberForm[Length[newResult] * dur, {4, 1}], "s)"];,
          {j, Length[exprs]}
        ];,

        (* Non-animation: evaluate for definitions *)
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
