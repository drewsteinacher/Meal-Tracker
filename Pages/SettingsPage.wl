ClearAll["Pages`SettingsPage`*"];
ClearAll["Pages`SettingsPage`*`*"];

BeginPackage["Pages`SettingsPage`", {"Utilities`GenerateData`", "Utilities`General`"}];

DeploySettingsPage::usage = "";

Begin["`Private`"];

DeploySettingsPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	Delayed[settingsForm[root]],
	FileNameJoin[{root, "Settings"}],
	opts
];

settingsForm[root_CloudObject] := Module[
	{configuration, nutritionTargets, nutritionToLabel},
	
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	
	nutritionTargets = Normal @ GetConfiguration[root, "NutritionTargets"];
	
	FormFunction[
		{
			{"NutritionTargets", "Nutrition Targets"} -> RepeatingElement[
				CompoundElement[
					<|
						"Nutrient" -> <|
							"Interpreter" -> "String",
							"Input" :> If[i <= Length[nutritionTargets],
								FromCamelCase[nutritionTargets[[i, 1, -1]]],
								""
							]
						|>,
						"Target" -> <|
							"Interpreter" -> "String",
							"Input" :> If[i <= Length[nutritionTargets],
								QuantityToString[nutritionTargets[[i, 2]]],
								""
							]
						|>
					|>
				],
				{
					{i, Length[nutritionTargets]},
					{1, 20}
				}
			]
		},
		settingsAction[root],
		AppearanceRules -> <|
			"Title" -> "Settings",
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]],
					"TEST"
				}
			],
			"ItemLayout" -> "Vertical"
		|>
	]
];

settingsAction[root_][results_Association] := Module[
	{},
	results
];


End[];
EndPackage[];