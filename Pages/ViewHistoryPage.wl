ClearAll["Pages`ViewHistoryPage`*"];
ClearAll["Pages`ViewHistoryPage`*`*"];

BeginPackage["Pages`ViewHistoryPage`",
	{
		"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`", "Plots`NutritionRadarPlot`"
	}
];

DeployViewHistoryPage::usage = "";

Begin["`Private`"];

DeployViewHistoryPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	Delayed[
		Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
		viewHistoryForm[root]
	],
	FileNameJoin[{root, "ViewHistory"}],
	opts
];

viewHistoryForm[root_CloudObject] := Module[
	{nutrients, bin},
	
	nutrients = Keys[GetConfiguration[root, "NutritionTargets"]][[All, 2]];
	bin = GetConfiguration[root, "HistoryDatabin"];
	
	FormPage[
		{
			"Nutrients" -> <|
				"Interpreter" -> AnySubset[nutrients],
				"Control" -> TogglerBar,
				"Input" -> Take[nutrients, UpTo[5]],
				"Default" -> nutrients
			|>,
			"Format" -> <|
				"Interpreter" -> {"RadarPlot", "Grid", "Gauges", "TimeSeries"},
				"Input" -> "RadarPlot",
				"Default" -> "RadarPlot",
				"Control" -> SetterBar,
				"AutoSubmitting" -> True
			|>,
			{"StartDate", "Start"} :> With[{date = DateObject[Today, TimeObject[{4, 0}]]}, DateInterpreterSpec[date]],
			{"EndDate", "End"} :> With[{date = DateObject[Today, TimeObject[{23, 0}]]}, DateInterpreterSpec[date]]
		},
		viewHistoryAction[root],
		AppearanceRules -> <|
			"Title" -> EmbeddedHTML[
				StringTemplate["View history
				<script>
				function confirmRemoval(uuid) {
                    if (confirm('Are you sure you want to remove this data point? This operation cannot be undone.')) {
                        var url = '``';
                        location.href = url.concat('&uuid=', uuid);
                    }
				}
				</script>"][URLBuild[FileNameJoin[{root, "RemoveLogEntry"}], <|"bin" -> bin["ShortID"]|>]]
			],
			"Description" -> Hyperlink["Return home", FileNameJoin[{root, "Home"}]],
			"ItemLayout" -> "Vertical"
		|>
	]
];

$MissingDataMessage = "There is no data for the selected time period.";

viewHistoryAction[root_][results_Association] := Module[
	{bin, binData, nutritionTargets},
	
	Get[FileNameJoin[{root, "Pages", "ViewHistoryPage.wl"}]];
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	
	bin = GetConfiguration[root, "HistoryDatabin"];
	nutritionTargets = GetConfiguration[root, "NutritionTargets"] // KeyMap[Last];
	
	Switch[results["Format"],
		
		"Grid",
		gridView[bin, results],
		
		"Gauges",
		gaugeView[bin, results, nutritionTargets],
		
		"TimeSeries",
		timeSeriesView[bin, results, nutritionTargets],
		
		"RadarPlot",
		radarPlotView[bin, results, nutritionTargets],
		
		_,
		"Something went wrong"
	]
];

gridView[bin_Databin, results_] := Module[
	{binData},
	
	binData = Get @ Databin[bin, getDateSpec[results], {"Meal", "MealType"}];
	binData = Join[
		#Data,
		<|
			"Timestamp" -> #Timestamp,
			"UUID" -> removalConfirmationLink[#UUID]
		|>
	]& /@ binData;
	binData = SortBy[binData, #Timestamp&];
	If[Length[binData] === 0,
		$MissingDataMessage,
		GridFormat[binData /. e_Entity :> e["CanonicalName"]]
	]
];

getDateSpec[a_Association] := getDateSpec @@ Lookup[a, {"StartDate", "EndDate"}];
getDateSpec[startDate_Association, endDate_Association] := DateObject[{#Year, #Month, #Day}, TimeObject[{#Hour, 0}]]& /@ {startDate, endDate};
getDateSpec[___] := $Failed;

removalConfirmationLink[uuid_String] :=
	EmbeddedHTML[
		StringTemplate[
			"<a style=\"cursor:pointer;\" onclick = \"confirmRemoval('``')\">Delete</a>"
		][uuid]
	];



gaugeView[bin_Databin, results_, nutritionTargets_Association] := Module[
	{nutritionData, dateSpec, days},
	
	dateSpec = getDateSpec[results];
	
	nutritionData = Normal @ Databin[bin, dateSpec, results["Nutrients"]];
	nutritionData = nutritionData // ReplaceAll[_Missing -> 0] // Merge[Total] // Map[Replace[0 -> Missing["NotAvailable"]]];
	
	If[Length[nutritionData] === 0,
		$MissingDataMessage
		,
		days = Quantity[DayCount @@ dateSpec, "Days"];
		Multicolumn[
			KeyValueMap[nutrientGauge[#1, #2, nutritionTargets[#1] * days]&, nutritionData]
		]
	]
	
];

nutrientGauge[nutrient_String, value_, target_] := Module[{},
	BulletGauge[value, target * {0.8, 1.2}, {0, 0.80, 1.20, 2}* target,
		GaugeLabels -> {Placed[FromCamelCase[nutrient], Top], Placed["Value", Left]},
		ScaleRangeStyle -> {Red, Green, Red},
		GaugeStyle -> Black
	]
];

timeSeriesView[bin_Databin, results_, nutritionTargets_] := Module[
	{nutrientToEventSeries, dateSpec, targetsForTimePeriod},
	
	dateSpec = getDateSpec[results];
	nutrientToEventSeries = EventSeries[Databin[bin, dateSpec, results["Nutrients"]]];
	nutrientToEventSeries = Select[nutrientToEventSeries, #["PathLength"] > 0 &];
	If[Length[nutrientToEventSeries] === 0,
		$MissingDataMessage,
		targetsForTimePeriod = Quantity[DayCount @@ dateSpec, "Days"] * nutritionTargets;
		Multicolumn[
			KeyValueMap[nutrientTimeSeriesPlot[targetsForTimePeriod, dateSpec], nutrientToEventSeries],
			1
		]
	]
];

nutrientTimeSeriesPlot[nutritionTargets_, dateSpec_][nutrient_String, es_TemporalData] := Module[
	{target, yRange, epilog, plottingUnits},
	target = Lookup[nutritionTargets, nutrient];
	
	If[MatchQ[target, _Quantity],
		yRange = {Quantity[0, QuantityUnit[target]], 1.25 * Max[target, Max[es]]};
		plottingUnits = QuantityUnit[es["FirstValue"]];
		epilog = {
			{Green, Thick, Dashed, InfiniteLine[{{0, QuantityMagnitude[target, plottingUnits]}, {1, QuantityMagnitude[target, plottingUnits]}}]}
		};
		,
		yRange = Automatic;
		epilog = {};
	];
	
	DateListStepPlot[
		TimeSeriesAccumulate[es, First[dateSpec]],
		PlotRange -> {dateSpec, yRange},
		PlotRangePadding -> Scaled[.1],
		ImageSize -> Large,
		Filling -> Axis,
	    PlotTheme -> {"Web","Frame"},
		PlotLabel -> nutrient,
		Epilog -> epilog
	] // ExportForm[#, "PNG"]&
	
];
nutrientTimeSeriesPlot[__][___] = $Failed;


radarPlotView[bin_Databin, results_Association, nutritionTargets_Association] := Module[
	{dateSpec, nutritionData, days},
	dateSpec = getDateSpec[results];
	
	nutritionData = Normal @ Databin[bin, dateSpec, results["Nutrients"]];
	nutritionData = nutritionData // ReplaceAll[_Missing -> 0] // Merge[Total] // Map[Replace[0 -> Missing["NotAvailable"]]];
	
	days = Quantity[DayCount @@ dateSpec, "Days"];
	If[Length[nutritionData] === 0,
		$MissingDataMessage,
		NutritionRadarPlot[nutritionData, "NutritionTargets" -> nutritionTargets, "Duration" -> days] // ExportForm[#, "PNG"]&
	]
];

End[];
EndPackage[];