ClearAll["Plots`NutritionRadarPlot`*"];
ClearAll["Plots`NutritionRadarPlot`*`*"];

BeginPackage["Plots`NutritionRadarPlot`", {"Plots`RadarPlot`"}];

NutritionRadarPlot::usage = "NutritionRadarPlot[<| \"nutrient 1\" -> value1, ... |>] creates a radar plot of the given nutrition data";

Begin["`Private`"];

entityNormalization = ReplaceAll[ Entity[type_, sn_] :> sn];
normalizeEntitiesToStandardNames[entities_List] := entityNormalization[entities];
normalizeEntitiesToStandardNames[nutrientData_Association] := KeyMap[entityNormalization, nutrientData];


validInputQ[a_Association] := And[
	Length[a] >= 3,
	MatchQ[Values[a], {__Quantity}],
	SubsetQ[EntityValue["Nutrient", "CanonicalName"], normalizeEntitiesToStandardNames[Keys[a]] ]
];
validInputQ[x___] := False;


Options[getNutrientTargetProperty] = {
	"DietaryReferenceIntakeType" -> "DailyValue",
	"Age" -> Automatic,
	"Gender" -> Automatic,
	"PregnancyStage" -> Automatic
};
getNutrientTargetProperty[OptionsPattern[]] := With[
	{
		baseProperty = OptionValue["DietaryReferenceIntakeType"],
		age = Replace[OptionValue["Age"], n_?NumberQ :> Quantity[n, "Years"]],
		gender = Replace[OptionValue["Gender"], s_String :> Entity["Gender", s]],
		pregnancyStage = Replace[OptionValue["PregnancyStage"], s_String :> Entity["PregnancyStage", s]]
	},
	EntityProperty[
		"Nutrient",
		baseProperty,
		DeleteCases[
			{
				"Age" -> age,
				"Gender" -> gender,
				"PregnancyStage" -> pregnancyStage
			},
			HoldPattern @ Rule[_, Automatic]
		]
	]
];


Options[getNutritionTargets] = Join[
	Options[getNutrientTargetProperty],
	{
		"NutritionTargets" -> Automatic,
		"Duration" -> Quantity[1, "Days"]
	}
];
getNutritionTargets[nutrients : {__String}, opts : OptionsPattern[]] := Module[
	{nutrientTargetProperty, nutrientTargets, duration, existingNutrientTargets},
	
	nutrientTargetProperty = getNutrientTargetProperty @@ FilterRules[{opts}, Options[getNutrientTargetProperty]];
	
	existingNutrientTargets = Replace[OptionValue["NutritionTargets"], Except[_Association] -> <||>];
	existingNutrientTargets = normalizeEntitiesToStandardNames @ existingNutrientTargets;
	existingNutrientTargets = KeyTake[existingNutrientTargets, nutrients];
	
	(* Get any missing targets *)
	nutrientTargets = EntityValue[Entity["Nutrient", #]& /@ Complement[nutrients, Keys[existingNutrientTargets]], nutrientTargetProperty, "EntityAssociation"];
	nutrientTargets = normalizeEntitiesToStandardNames @ nutrientTargets;
	
	(* Merge with any existing targets *)
	nutrientTargets = Join[existingNutrientTargets, nutrientTargets];
	
	(* Deal with durations *)
	duration = OptionValue["Duration"];
	nutrientTargets = Replace[q : Quantity[_, _String] :> q / duration] /@ nutrientTargets;
	nutrientTargets = nutrientTargets * duration;
	
	nutrientTargets
];


Options[normalizeNutritionData] = Options[getNutritionTargets];
normalizeNutritionData[nutritionData_Association, opts : OptionsPattern[]] := With[
	{
		nutritionTargets = getNutritionTargets[normalizeEntitiesToStandardNames @ Keys[nutritionData], opts]
	},

	(* TODO: Handle errors here where the keys are not identical? *)
	Merge[normalizeEntitiesToStandardNames /@ {nutritionData, nutritionTargets}, Apply[N[100. * Divide[##]] &]]
];


Options[NutritionRadarPlot] = Join[
	Options[normalizeNutritionData],
	Options[RadarPlot]
];

NutritionRadarPlot::invalid = "Invalid syntax";
NutritionRadarPlot[data_, ___] /; Not[validInputQ[data]] := (Message[NutritionRadarPlot::invalid]; $Failed);

NutritionRadarPlot[nutritionData_Association, opts : OptionsPattern[]] := Module[
	{nutritionLimits, normalizedNutrientData},
	normalizedNutrientData = normalizeNutritionData[nutritionData, ##]& @@ FilterRules[{opts}, Options[normalizeNutritionData]];
	RadarPlot[normalizedNutrientData, ##]& @@ FilterRules[{opts}, Options[RadarPlot]]
];

NutritionRadarPlot[___] := (Message[NutritionRadarPlot::invalid]; $Failed);

End[];

EndPackage[];