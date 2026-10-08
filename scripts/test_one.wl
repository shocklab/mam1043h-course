(* test_one.wl — debug one notebook with verbose prints *)

$animIdx = 0;

captureFrames[lst_List] := Module[{},
  If[Length[lst] < 2, Print["  (list too short: ", Length[lst], ")"]; Return[Null]];
  $animIdx++;
  Print["  GOT FRAMES: ", Length[lst]];
];
captureFrames[other_] := Print["  (arg head: ", Head[other], ")"];

Unprotect[System`ListAnimate];
ClearAll[System`ListAnimate];
System`ListAnimate[arg_, ___] := (
  Print["  ListAnimate called, arg head=", Head[arg]];
  captureFrames[arg]; Null);

UsingFrontEnd[
  nb = NotebookOpen["/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H/MAM1043part1b.nb", Visible -> False];
  inputCells = Cells[nb, CellStyle -> "Input"];
  Print["cells: ", Length[inputCells]];
  Do[
    Print["--- cell ", i, " ---"];
    cellExpr = NotebookRead[inputCells[[i]]];
    If[Head[cellExpr] =!= Cell, Print["  not a cell, skipping"]; Continue[]];
    srcStr = ToString[cellExpr[[1]], InputForm];
    Print["  src (first 100): ", StringTake[srcStr, UpTo[100]]];
    r = Quiet[Check[ToExpression[cellExpr[[1]]], $Failed]];
    Print["  result head: ", Head[r]],
    {i, Length[inputCells]}
  ];
  NotebookClose[nb];
  Print["Done. animIdx=", $animIdx];
]
