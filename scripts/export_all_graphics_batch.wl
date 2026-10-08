(* export_all_graphics_batch.wl — Batch-export Output cell graphics for all MAM1043H notebooks.
   Shares one WolframScript session across all notebooks.

   Usage: wolframscript -file export_all_graphics_batch.wl
*)

nbDir = "/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H";
outBase = "/Users/jonathanshock/Cursor folders/Teaching/MAM1043H-site/static/images";

(* notebook basename -> image subdirectory *)
jobs = {
  {"MAM1043part1a.nb", "part1a"},
  {"MAM1043part1b.nb", "part1b"},
  {"MAM1043part1c.nb", "part1c"},
  {"MAM1043part1d.nb", "part1d"},
  {"MAM1043part1e.nb", "part1e"},
  {"MAM1043part1f.nb", "part1f"},
  {"MAM1043part1exercises.nb", "part1exercises"},
  {"MAM1043part2a.nb", "part2a"},
  {"MAM1043part2b.nb", "part2b"},
  {"MAM1043part2c.nb", "part2c"},
  {"MAM1043part2d.nb", "part2d"},
  {"MAM1043part2e.nb", "part2e"},
  {"MAM1043part2f.nb", "part2f"},
  {"MAM1043part2g.nb", "part2g"},
  {"MAM1043part2h.nb", "part2h"},
  {"MAM1043part2exercises.nb", "part2exercises"},
  {"MAM1043part2answers.nb", "part2answers"},
  {"MAM1043part3a.nb", "part3a"},
  {"MAM1043part3b.nb", "part3b"},
  {"MAM1043part3c.nb", "part3c"},
  {"MAM1043part3d.nb", "part3d"},
  {"MAM1043part3e.nb", "part3e"},
  {"MAM1043part3f.nb", "part3f"},
  {"MAM1043part3fii.nb", "part3fii"},
  {"MAM1043part3exercises.nb", "part3exercises"},
  {"MAM1043part3exercises1a.nb", "part3exercises1a"},
  {"MAM1043part3exercises1b.nb", "part3exercises1b"},
  {"MAM1043part3exercises1c.nb", "part3exercises1c"},
  {"MAM1043part3exercises1d.nb", "part3exercises1d"},
  {"MAM1043part3exercises4b.nb", "part3exercises4b"},
  {"MAM1043part3exercises4c.nb", "part3exercises4c"},
  {"MAM1043part3exercises4d.nb", "part3exercises4d"},
  {"MAM1043part3exercises4e.nb", "part3exercises4e"},
  {"MAM1043part3exercises5b.nb", "part3exercises5b"},
  {"MAM1043part4a.nb", "part4a"},
  {"MAM1043part4b.nb", "part4b"},
  {"MAM1043part4c.nb", "part4c"},
  {"MAM1043part4d.nb", "part4d"},
  {"MAM1043part4exercises.nb", "part4exercises"},
  {"MAM1043part4answers.nb", "part4answers"}
};

processNotebook[nbFile_, outDir_] := Module[
  {nb, cells, count = 0, skipped = 0},
  Print["---"];
  Print["Exporting: ", nbFile];

  If[!DirectoryQ[outDir], CreateDirectory[outDir]];

  nb = NotebookOpen[nbFile, Visible -> False];
  If[nb === $Failed,
    Print["  ERROR: Could not open notebook"];
    Return[0]
  ];

  cells = Cells[nb, CellStyle -> "Output"];
  Print["  Output cells: ", Length[cells]];

  Do[
    Module[{cellExpr, img, fname, hasGraphics},
      cellExpr = NotebookRead[cells[[i]]];
      If[cellExpr === {} || cellExpr === "" || Head[cellExpr] =!= Cell,
        skipped++;
        Continue[]
      ];
      hasGraphics = !FreeQ[cellExpr,
        GraphicsBox | Graphics3DBox | RasterBox | DynamicModuleBox];
      If[!hasGraphics, skipped++; Continue[]];

      count++;
      fname = FileNameJoin[{outDir,
        "output_" <> IntegerString[count, 10, 3] <> ".png"}];
      img = Rasterize[cellExpr, ImageResolution -> 150];
      Export[fname, img];
      Print["  [", count, "] ", FileNameTake[fname]];
    ],
    {i, Length[cells]}
  ];

  NotebookClose[nb];
  Print["  Done: ", count, " images, ", skipped, " skipped"];
  count
];

UsingFrontEnd[
  totalImages = 0;
  Do[
    Module[{nb = jobs[[k, 1]], dir = jobs[[k, 2]]},
      totalImages += processNotebook[
        FileNameJoin[{nbDir, nb}],
        FileNameJoin[{outBase, dir}]
      ]
    ],
    {k, Length[jobs]}
  ];
  Print[""];
  Print["=== Total: ", totalImages, " images across ", Length[jobs], " notebooks ==="];
];
