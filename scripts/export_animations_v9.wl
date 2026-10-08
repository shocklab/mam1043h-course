(* export_animations_v9.wl — v3 structure (overrides inside processNotebook,
   closures over local animIdx/outDir) PLUS $lastList fallback for cells where
   ListAnimate's arg doesn't evaluate to a list (e.g. ListAnimate[%]).
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
  {"MAM1043part3fii.nb", "part3fii"},
  (* part3e omitted: 22 Input cells with deeply nested Manipulate
     widgets cause v9's inputCells indexing to fail mid-run.
     The 3-dial Manipulate (Figure 16) is intended to become a
     JSXGraph interactive widget rather than a GIF anyway. *)
  {"MAM1043part4a.nb", "part4a"},
  {"MAM1043part4b.nb", "part4b"},
  {"MAM1043part4c.nb", "part4c"}
};

processNotebook[nbName_, partDir_] := Module[
  {nb, inputCells, outDir, animIdx, lastList, lastExportedSig},
  outDir = FileNameJoin[{outBase, partDir}];
  If[!DirectoryQ[outDir], CreateDirectory[outDir]];
  Print["\n=== ", partDir, " ==="];

  nb = NotebookOpen[FileNameJoin[{nbDir, nbName}], Visible -> False];
  If[nb === $Failed, Print["  SKIP"]; Return[0]];
  inputCells = Cells[nb, CellStyle -> "Input"];
  Print["  Input cells: ", Length[inputCells]];

  animIdx = 0;
  lastList = {};
  lastExportedSig = None;

  Module[{$captureFn, ctx},
    ctx = "AnimCapture`";
    (* Trigger lazy-load of ListAnimate/Animate so we can clear their autoload stubs *)
    Quiet[System`ListAnimate[{1, 2}]];
    Quiet[System`Animate[1, {x, 1, 2}]];
    Unprotect[System`ListAnimate, System`Animate];
    ClearAll[System`ListAnimate, System`Animate];
    System`ListAnimate[lst_List, ___] := Module[{fname, sig},
      If[Length[lst] < 5, Return[Null]];
      sig = Hash[lst];
      If[sig === lastExportedSig,
        Print["  [skip] duplicate of previous export"];
        Return[Null]];
      lastList = lst;
      lastExportedSig = sig;
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
    System`ListAnimate[other___] := Module[{arg, fname, sig},
      arg = {other}[[1]];
      If[Length[lastList] < 5,
        Print["  [skip] ListAnimate arg head=", Head[arg], ", no useful fallback (lastList len=", Length[lastList], ")"];
        Return[Null]];
      sig = Hash[lastList];
      If[sig === lastExportedSig,
        Print["  [skip] fallback matches previous export (arg head=", Head[arg], ")"];
        Return[Null]];
      lastExportedSig = sig;
      animIdx++;
      fname = FileNameJoin[{outDir,
        "anim_" <> IntegerString[animIdx, 10, 3] <> ".gif"}];
      Quiet[Export[fname, lastList, "GIF",
        "DisplayDurations" -> dur,
        "AnimationRepetitions" -> Infinity,
        ImageResolution -> res]];
      Print["  anim_", IntegerString[animIdx, 10, 3], ": ",
        Length[lastList], " frames (fallback, arg head=", Head[arg], ")"];
      Null
    ];
    System`Animate[body_, iter_List, ___] := Module[{frames, fname},
      frames = Quiet[Check[Table[body, iter], $Failed]];
      If[frames =!= $Failed && ListQ[frames] && Length[frames] >= 3,
        Module[{sig = Hash[frames]},
          If[sig =!= lastExportedSig,
            lastList = frames;
            lastExportedSig = sig;
            animIdx++;
            fname = FileNameJoin[{outDir,
              "anim_" <> IntegerString[animIdx, 10, 3] <> ".gif"}];
            Quiet[Export[fname, frames, "GIF",
              "DisplayDurations" -> dur,
              "AnimationRepetitions" -> Infinity,
              ImageResolution -> res]];
            Print["  anim_", IntegerString[animIdx, 10, 3], ": ",
              Length[frames], " frames (Animate)"]]]
      ];
      Null
    ];
    SetAttributes[System`Animate, HoldAll];
  ];

  Do[
    Module[{cellExpr, held, topN, sub, ceLen, heldArgs, heldArg, r},
      cellExpr = NotebookRead[inputCells[[i]]];
      If[Head[cellExpr] =!= Cell, Continue[]];
      (* Parse as held expression.  ToExpression[..., Hold] returns
         Hold[s1, s2, ...] for multi-statement cells.  A statement that
         ends with `;` parses as Hold[CompoundExpression[expr, Null]],
         which would eval to Null and never expose a list to update
         lastList.  So we unfold one level of CompoundExpression and
         evaluate each sub-arg individually so `Table[...]; ListAnimate[%]`
         can see the Table's list via lastList. *)
      held = Quiet[Check[
        ToExpression[cellExpr[[1]], StandardForm, Hold], $Failed]];
      If[held === $Failed || Head[held] =!= Hold, Continue[]];
      topN = Length[held];
      heldArgs = {};
      Do[
        sub = Extract[held, {k}, Hold];
        If[MatchQ[sub, Hold[_CompoundExpression]],
          ceLen = Replace[sub,
            {Hold[_[a___]] :> Length[Hold[a]], _ :> 0}];
          Do[
            AppendTo[heldArgs, Extract[held, {k, m}, Hold]];
            , {m, ceLen}];
          ,
          AppendTo[heldArgs, sub];
        ];
        , {k, topN}];
      Do[
        heldArg = heldArgs[[k]];
        heldArg = heldArg /. {
          HoldPattern[Out[]] :> lastList,
          HoldPattern[Out[_]] :> lastList};
        r = TimeConstrained[
          Quiet[Check[ReleaseHold[heldArg], $Failed]],
          60, $TimedOut];
        If[ListQ[r] && Length[r] >= 2, lastList = r];
        , {k, Length[heldArgs]}];
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
