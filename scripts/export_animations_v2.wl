(* export_animations_v2.wl — Smarter animation extractor.

   For each notebook:
   1. Walk Input cells in notebook order
   2. When a cell contains ListAnimate OR Animate:
      - Strip the ListAnimate[...]; wrapper
      - Evaluate the inner expression (which should evaluate to a List of Graphics or an evaluated list variable)
      - Export as GIF
   3. All preceding Input cells are evaluated too so defs/assignments are available
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

(* Strip outer BoxData, SEMICOLONs, StyleBoxes, etc. to get at the raw expression *)
stripWrap[boxExpr_] := Module[{x = boxExpr},
  While[MatchQ[x, RowBox[{_, ";"}]], x = x[[1, 1]]];
  x
];

processNotebook[nbName_, partDir_] := Module[
  {nb, inputCells, animIdx = 0, outDir, anim},
  outDir = FileNameJoin[{outBase, partDir}];
  If[!DirectoryQ[outDir], CreateDirectory[outDir]];
  Print["\n=== ", partDir, " ==="];

  nb = NotebookOpen[FileNameJoin[{nbDir, nbName}], Visible -> False];
  If[nb === $Failed, Print["  SKIP"]; Return[0]];

  inputCells = Cells[nb, CellStyle -> "Input"];

  Do[
    Module[{cellExpr, inner, innerList, str},
      cellExpr = NotebookRead[inputCells[[i]]];
      If[Head[cellExpr] =!= Cell, Continue[]];
      inner = cellExpr[[1, 1]];
      str = ToString[inner, InputForm];

      (* Split a CompoundExpression (semicolon-separated) into its parts *)
      innerList = If[Head[inner] === List, inner, {inner}];

      (* Check each top-level part for ListAnimate or Animate *)
      Scan[Function[part,
        Module[{partStr, argBox, argExpr, frames},
          If[StringQ[part], Return[]];
          partStr = ToString[part, InputForm];

          Which[
            (* ListAnimate[arg] — arg should evaluate to a list *)
            StringContainsQ[partStr, "ListAnimate["],
              argBox = FirstCase[part,
                RowBox[{"ListAnimate", "[", a_, "]"}] :> a, Missing[], Infinity];
              If[MissingQ[argBox],
                Print["  cell ", i, ": ListAnimate found but couldn't extract arg"];
                Return[]
              ];
              argExpr = Quiet[Check[
                ToExpression[BoxData[argBox], StandardForm],
                $Failed]];
              If[argExpr === $Failed || !ListQ[argExpr] || Length[argExpr] < 2,
                Print["  cell ", i, ": arg didn't evaluate to a list (head=", Head[argExpr], ")"];
                Return[]
              ];
              frames = argExpr,

            (* Animate[body, {x, min, max, step}] *)
            StringContainsQ[partStr, "Animate["],
              (* try to rewrite Animate as Table and evaluate *)
              Module[{animCase},
                animCase = FirstCase[part,
                  RowBox[{"Animate", "[", RowBox[{bodyBox_, ",", iterBox_}], "]"}] :>
                    {bodyBox, iterBox}, Missing[], Infinity];
                If[MissingQ[animCase],
                  Print["  cell ", i, ": Animate couldn't extract"];
                  Return[]
                ];
                Module[{tblBox},
                  tblBox = RowBox[{"Table", "[", RowBox[{animCase[[1]], ",", animCase[[2]]}], "]"}];
                  frames = Quiet[Check[
                    ToExpression[BoxData[tblBox], StandardForm],
                    $Failed]];
                  If[frames === $Failed || !ListQ[frames] || Length[frames] < 2,
                    Print["  cell ", i, ": Animate->Table eval failed"];
                    Return[]
                  ]
                ]
              ],

            (* Not an anim — just evaluate for side-effects (definitions) *)
            True,
              Quiet[ToExpression[BoxData[part], StandardForm]];
              Return[]
          ];

          (* Export frames *)
          animIdx++;
          Module[{fname},
            fname = FileNameJoin[{outDir,
              "anim_" <> IntegerString[animIdx, 10, 3] <> ".gif"}];
            Quiet[Export[fname, frames, "GIF",
              "DisplayDurations" -> dur,
              "AnimationRepetitions" -> Infinity,
              ImageResolution -> res]];
            Print["  anim_", IntegerString[animIdx, 10, 3], ": ",
              Length[frames], " frames (",
              NumberForm[Length[frames] * dur, {4, 1}], "s)"]
          ]
        ]], innerList];
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
  Print["\n=== ALL DONE — ", total, " GIFs total ==="];
];
