BeginTestSection["NutritionRadarPlot"];

VerificationTest[
	Get["Plots/NutritionRadarPlot.wl"],
	Null,
	TestID -> "Get-Package"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`validInputQ[
		testInput = <|
			Entity["Nutrient", "VitaminA"] -> Quantity[1, "Milligrams"],
			"VitaminB6" -> Quantity[1, "Milligrams"],
			"VitaminC" -> Quantity[20, "Milligrams"]
		|>
	],
	TestID -> "Test-Input-for-validity"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`validInputQ[testInput[[;; 1]]],
	False,
	TestID -> "Not-Enough-Data-1"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`validInputQ[testInput[[;; 2]]],
	False,
	TestID -> "Not-Enough-Data-2"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`validInputQ[<||>],
	False,
	TestID -> "Not-Enough-Data-0"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`validInputQ[1234],
	False,
	TestID -> "Invalid-Syntax"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`validInputQ[
		<|
			"VitaminA" -> Quantity[1, "Grams"],
			"VitaminB12" -> Quantity[40, "Grams"],
			"VitaminC" -> "String"
		|>
	],
	False,
	TestID -> "Invalid-Syntax-Association-Values"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`validInputQ[
		<|
			"NotANutrient" -> Quantity[1, "Grams"],
			"VitaminB12" -> Quantity[40, "Grams"],
			"VitaminC" -> Quantity[4, "Milligrams"]
		|>
	],
	False,
	TestID -> "Invalid-Syntax-NonNutrient-Keys"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`normalizeEntitiesToStandardNames[Keys[testInput]],
	{"VitaminA", "VitaminB6", "VitaminC"},
	TestID -> "normalize-Entity-to-SNs"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`normalizeEntitiesToStandardNames[testInput],
	<|
		"VitaminA" -> Quantity[1, "Milligrams"],
		"VitaminB6" -> Quantity[1, "Milligrams"],
		"VitaminC" -> Quantity[20, "Milligrams"]
	|>,
	TestID -> "normalize-Entity-to-SNs-Association-Keys"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`getNutrientTargetProperty[],
	EntityProperty["Nutrient", "DailyValue", {}],
	TestID -> "get-nutrient-target-property-defaults"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`getNutrientTargetProperty["Gender" -> "Female"],
	EntityProperty["Nutrient", "DailyValue", {"Gender" -> Entity["Gender", "Female"]}],
	TestID -> "get-nutrient-target-property-gender"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`getNutrientTargetProperty["Gender" -> "Female", "PregnancyStage" -> "Pregnant", "Age" -> 25],
	EntityProperty["Nutrient", "DailyValue",
		{
			"Age" -> Quantity[25, "Years"],
			"Gender" -> Entity["Gender", "Female"],
			"PregnancyStage" -> Entity["PregnancyStage", "Pregnant"]
		}
	],
	TestID -> "get-nutrient-target-property-all-qualifiers"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`getNutritionTargets[Plots`NutritionRadarPlot`Private`normalizeEntitiesToStandardNames @ Keys[testInput]],
	<|
		"VitaminA" -> Quantity[0.0015, "Grams"],
		"VitaminB6" -> Quantity[0.002, "Grams"],
		"VitaminC" -> Quantity[0.06, "Grams"]
	|>,
	TestID -> "get-nutrition-targets-Automatic"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`normalizeNutritionData[testInput],
	<|"VitaminA" -> 66.6667, "VitaminB6" -> 50., "VitaminC" -> 33.3333|>,
	TestID -> "normalize-nutrition-data-to-percents-Automatic",
	SameTest -> ((SameQ @@ Round[{##}, 0.1])&)
];


VerificationTest[
	Plots`NutritionRadarPlot`Private`normalizeNutritionData[testInput, "NutritionTargets" -> testInput],
	<|"VitaminA" -> 100., "VitaminB6" -> 100., "VitaminC" -> 100.|>,
	TestID -> "normalize-nutrition-data-to-percents-self-test"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`normalizeNutritionData[testInput, "NutritionTargets" -> testInput / Quantity[1, "Days"]],
	<|"VitaminA" -> 100., "VitaminB6" -> 100., "VitaminC" -> 100.|>,
	TestID -> "normalize-nutrition-data-to-percents-self-test-with-per-day-amounts"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`normalizeNutritionData[
		testInput,
		"NutritionTargets" -> testInput / Quantity[1, "Days"],
		"Duration" -> Quantity[7, "Days"]
	],
	<|"VitaminA" -> 14.2857, "VitaminB6" -> 14.2857, "VitaminC" -> 14.2857|>,
	TestID -> "normalize-nutrition-data-to-percents-self-test-with-explicit-duration",
	SameTest -> ((SameQ @@ Round[{##}, 0.1])&)
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`normalizeNutritionData[
		testInput,
		"NutritionTargets" -> testInput / Quantity[1, "Days"],
		"DietaryReferenceIntakeType" -> "EstimatedAverageRequirement"
	],
	<|"VitaminA" -> 100., "VitaminB6" -> 100., "VitaminC" -> 100.|>,
	TestID -> "normalize-nutrition-data-to-percents-self-test-with-DRIType"
];

VerificationTest[
	Plots`NutritionRadarPlot`Private`normalizeNutritionData[
		testInput,
		(*"NutritionTargets" -> testInput / Quantity[1, "Days"],*)
		"DietaryReferenceIntakeType" -> "EstimatedAverageRequirement",
		"Gender" -> "Female",
		"PregnancyStage" -> "Pregnant",
		"Age" -> Quantity[25, "Years"]
	],
	<|"VitaminA" -> 181.818, "VitaminB6" -> 62.5, "VitaminC" -> 28.5714|>,
	TestID -> "normalize-nutrition-data-to-percents-with-all-qualifiers",
	SameTest -> ((SameQ @@ Round[{##}, 0.1])&)
];

VerificationTest[
	NutritionRadarPlot[testInput],
	Rotate[_Graphics, _],
	SameTest -> MatchQ,
	TestID -> "Simple-Input-3"
];

VerificationTest[
	NutritionRadarPlot[
		<|
			"TotalCalories" -> Quantity[224., "LargeCalories"],
			"Calcium" -> Quantity[250., "Milligrams"],
			"Sodium" -> Quantity[55.5, "Milligrams"]
		|>,
		"NutritionTargets" -> <|
			"TotalCalories" -> Quantity[2000, "LargeCalories"/"Days"],
			"Calcium" -> Quantity[1., "Grams"/"Days"],
			"Sodium" -> Quantity[2.4, "Grams"/"Days"],
			"VitaminC" -> Quantity[0.06, "Grams"/"Days"]
		|>
	],
	Rotate[_Graphics, _],
	SameTest -> MatchQ,
	TestID -> "NutritionRadarPlot-ignore-extra-nutrition-targets"
];

EndTestSection[];
