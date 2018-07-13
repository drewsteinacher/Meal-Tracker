ClearAll["Plots`RadarPlot`*"];

BeginPackage["Plots`RadarPlot`", {"Utilities`General`"}];

RadarPlot::usage = "RadarPlot[<| \"label 1\" -> value1, ... |>] creates a radar plot of the given data";

Begin["`Private`"];

validInputQ[a_Association] /; Length[a] >= 3 := MatchQ[Values[a], {__?NumberQ}];
validInputQ[___] := False;

Options[RadarPlot] = Options[SectorChart];

RadarPlot::notenough = "RadarPlot requires at least 3 data points";
RadarPlot::invalid = "Invalid syntax";

RadarPlot[data_Association, ___] /; Length[data] < 3 := (Message[RadarPlot::notenough]; $Failed);
RadarPlot[data_, ___] /; Not[validInputQ[data]] := (Message[RadarPlot::invalid]; $Failed);

RadarPlot[newData0_Association, opts : OptionsPattern[]] := Block[
	{newData, n, connect, plot, labels, data, lastVertex},

(* Fix the order so the first point is on top and goes CCW *)
	newData = RotateLeft @ newData0;
	n = Length[newData];
	labels = FromCamelCase /@ Keys[newData];
	data = Values[newData];
	lastVertex = {Last[newData], 0};
	
	(* A ChartElementFunction to emulate the data filling a polygon *)
	connect[{{t0_, t1_}, {r0_, r1_}}, r___] := With[
		{newVertex = r1 {Cos[t1], Sin[t1]}},
		{
		(* Filling polygon slice *)
			{EdgeForm[], Opacity[0.5], Gray, Polygon[{lastVertex, newVertex, {0, 0}}]},
		(* Outermost polygon edge *)
			Line[{{lastVertex, lastVertex = newVertex}}]
		}
	];
	
	plot = SectorChart[
		{1, #} & /@ data,
		
		PolarTicks -> {
			Table[{i 2 Pi / n, Style[labels[[i]], 16]}, {i, 1, n}],
			None
		},
		PolarGridLines -> {
			Table[(i - 1) 2 Pi / n, {i, n}],
			Range[0, 100, 25]
		},
		SectorOrigin -> 0,
		ChartLayout -> "Stacked",
		ChartElementFunction -> connect,
		PlotRange -> All,
		LabelingFunction -> None,
	
	(* These are required so that I have control over the "plot range" *)
		PolarAxes -> {True, True},
		PolarAxesOrigin -> {0, 100},
		
		opts,
		
		GridLinesStyle -> Dashed,
		ChartBaseStyle -> Thick,
		ChartStyle -> Orange
	];
	
	(* Hacky fix for removing the axis while still forcing the "plot range" *)
	plot = plot /. Line[{{0, 0}, {100, 0}}] -> Nothing;
	
	(* Rotate so that the top is used by the first one *)
	plot = Rotate[plot, 90 Degree] /. {Style[a_, b___] :> Style[Rotate[a, -90 Degree], b]};
	
	(* Avoid the click-sensitive portion of SectorChart *)
	plot = plot /. DynamicModule[_, b_, ___] :> b;
	
	plot
];

RadarPlot[___] := (Message[RadarPlot::invalid]; $Failed);

End[];

EndPackage[];