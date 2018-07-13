ClearAll["Pages`FoodSearchPage`*"];
ClearAll["Pages`FoodSearchPage`*`*"];

BeginPackage["Pages`FoodSearchPage`", {"Utilities`GenerateData`", "Utilities`General`"}];

DeployFoodSearchPage::usage = "";

Begin["`Private`"];

DeployFoodSearchPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	foodSearchForm[root],
	FileNameJoin[{root, "FoodSearch"}],
	opts
];

foodSearchForm[root_CloudObject] := Module[
	{},
	FormPage[
		{
			"Description" -> <|
				"Interpreter" -> "String",
				"Label" -> "Food",
				"Help" -> AddFoodHelpLinks[root, "FoodSearch"]
			|>
		},
		foodSearchAction[root],
		AppearanceRules -> <|
			"Title" -> "Food search",
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]],
					"Enter a food name here to discover foods and add them for tracking by clicking on a serving size."
				}
			],
			"ItemLayout" -> "Vertical"
		|>
	]
];

foodSearchAction[root_] := Module[
	{entity, data},
	
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	entity = SafeInterpreter["Food"][#Description];
	
	(* TODO: Find USDA foods that match the given input string? *)
	FoodServingSizeHyperlinkGrid[root][entity, "IncludeImplicitEntity" -> True, "ImplicitEntityLabel" -> #Description, "ResubmitPage" -> "FoodSearch"]
]&;


End[];
EndPackage[];