ClearAll["Pages`FoodEntryPage`*"];
ClearAll["Pages`FoodEntryPage`*`*"];

BeginPackage["Pages`FoodEntryPage`", {"Utilities`GenerateData`", "Utilities`General`"}];

DeployFoodEntryPage::usage = "";

Begin["`Private`"];

DeployFoodEntryPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	foodEntryAPI[root],
	FileNameJoin[{root, "FoodEntry"}],
	opts
];

foodEntryAPI[root_CloudObject] := APIFunction[
	{
		"description" -> "String" -> "",
		"servingSize" -> "String" -> "",
		"mode" -> {"none", "test", "submit"} -> "none"
	},
	(
		Get[FileNameJoin[{root, "MealTrackerApp.wl"}]];
		With[{form = foodEntryForm[root][#]},
			Switch[#mode,
				"test" | "submit",  form[#],
				_,                  form
			]
		]
	)&
];

foodEntryForm[root_CloudObject][defaults_Association] := Module[
	{configuration, nutritionTargets, nutritionToLabel},
	
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	
	FormFunction[
		{
			"Description" -> <|
				"Interpreter" -> "String",
				"Label" -> "Food",
				"Input" -> Lookup[defaults, "description", ""]
			|>,
			"ServingSize" -> <|
				"Interpreter" -> "String",
				"Label" -> "Serving Size",
				"Input" -> Lookup[defaults, "servingSize", ""],
				"Help" -> ServingSizeHelpMessage[]
			|>
		},
		foodEntryAction[root][Join[#, KeyTake[defaults, "mode"]]]&,
		AppearanceRules -> <|
			"Title" -> "Food entry",
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]],
					AddFoodHelpLinks[root, "FoodEntry"]
				}
			],
			"ItemLayout" -> "Inline"
		|>
	]
];

foodEntryAction[root_][results_Association] := Module[
	{nutrients, amounts, nutrientData, url},
	
	url = URLBuild[
		FileNameJoin[{root, "NutritionEntry"}],
		{
			"description" -> #Description,
			"entity" -> Compress[#Description],
			"servingSizeString" -> #ServingSize,
			"action" -> "new",
			"mode" -> #mode
		}&[results]
	];
	
	Switch[results["mode"],
		"test",     url,
		_,          HTTPRedirect[url]
	]
];


End[];
EndPackage[];