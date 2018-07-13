ClearAll["Pages`ServingSizeMultiplicationPage`*"];
ClearAll["Pages`ServingSizeMultiplicationPage`*`*"];

BeginPackage["Pages`ServingSizeMultiplicationPage`", {"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`"}];

DeployServingSizeMultiplicationPage::usage = "";

Begin["`Private`"];

DeployServingSizeMultiplicationPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	servingSizeMultiplicationAPI[root],
	FileNameJoin[{root, "ServingSizeMultiplication"}],
	opts
];

$ParametersPassedToAction = {"description", "entity", "servingSizeMass", "resubmitPage", "action", "mode"};

servingSizeMultiplicationAPI[root_CloudObject] := APIFunction[
	{
		"description" -> "String",
		"entity" -> "String",
		"servingSizeMass" -> "String" -> Compress[Missing["NotAvailable"]],
		"servingSizeString" -> "String",
		"resubmitPage" -> {"FoodSearch", "FoodLookup", "ScanBarcode"} -> "FoodSearch",
		"action" -> {"new", "update"} -> "new",
		"mode" -> {"none", "test", "submit"} -> "none"
	},
	(
		Get[FileNameJoin[{root, "MealTrackerApp.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
		With[{form = servingSizeMultiplicationForm[root][#]},
			Switch[#mode,
				"test" | "submit",  form[#],
				_,                  form
			]
		]
	)&
];

servingSizeMultiplicationForm[root_CloudObject][parameters_Association] := Module[
	{},
	
	FormFunction[
		{
			"ServingSize" -> <|
				"Label" -> "Serving size",
				"Interpreter" -> "String",
				"Input" -> parameters["servingSizeString"],
				"Help" -> ServingSizeHelpMessage[]
			|>
		},
		servingSizeMultiplicationAction[root][Join[#, KeyTake[parameters, $ParametersPassedToAction]]]&,
		AppearanceRules -> <|
			"Title" -> StringTemplate["Enter a serving size for ``"][parameters["description"]],
			"Description" -> Hyperlink["Return home", FileNameJoin[{root, "Home"}]],
			"ItemLayout" -> "Vertical"
		|>
	]
	
];

servingSizeMultiplicationAction[root_][results_Association] := Module[
	{url, servingSizeString, servingSizeMass},
	
	servingSizeString = results["ServingSize"];
	
	servingSizeMass = SelectFirst[
		SafeInterpreter["Quantity"][StringSplit[servingSizeString, ";"]],
		CompatibleUnitQ[#, Quantity[1, "Grams"]]&
	];
	
	url = URLBuild[
		FileNameJoin[{root, "NutritionEntry"}],
		Join[
			KeyDrop[results, "ServingSize"],
			<|
				"servingSizeString" -> servingSizeString,
				"servingSizeMass" -> Compress[servingSizeMass]
			|>
		]
	];
	
	Switch[results["mode"],
		"test",     url,
		_,          HTTPRedirect[url]
	]
];

End[];
EndPackage[];