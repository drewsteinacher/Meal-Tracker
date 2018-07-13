ClearAll["Pages`MealEntryPage`*"];
ClearAll["Pages`MealEntryPage`*`*"];

BeginPackage["Pages`MealEntryPage`", {"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`"}];

DeployMealEntryPage::usage = "";

Begin["`Private`"];

DeployMealEntryPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	Delayed[
		Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
		mealEntryAPI[root]
	],
	FileNameJoin[{root, "MealEntry"}],
	opts
];

mealEntryAPI[root_CloudObject] := APIFunction[
	{
		"entity" -> "String" -> "",
		"description" -> "String" -> "",
		"mealType" -> AnySubset[$MealTypes] :> {GetMealTypeFromTime[]},
		"foodToAmount" -> "String" -> Compress[<||>],
		"action" -> {"new", "update"} -> "new",
		"mode" -> {"none", "test", "submit"} -> "none"
	},
	(
		Get[FileNameJoin[{root, "MealTrackerApp.wl"}]];
		With[{form = mealEntryForm[root][#]},
			Switch[#mode,
				"test" | "submit",  form[#],
				_,                  form
			]
		]
	)&
];

mealEntryForm[root_CloudObject][defaults_Association] := Module[
	{configuration, nutritionTargets, nutritionToLabel, foodData},
	
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
	
	LoadEntityStore[root, "MyFood"];
	
	FormFunction[
		{
			"Description" -> <|
				"Interpreter" -> "String",
				"Label" -> "Meal",
				"Input" -> Lookup[defaults, "description", ""]
			|>,
			"MealType" -> <|
				"Interpreter" -> AnySubset[$MealTypes],
				"Control" -> TogglerBar,
				"Input" -> Lookup[defaults, "mealType", None]
			|>,
			"Foods" -> <|
				"Interpreter" -> AnySubset[Rule @@@ SortBy[EntityValue["MyFood", {"Label", "CanonicalName"}], First]],
				"Control" -> TogglerBar,
				"Help" -> AddFoodHelpLinks[root, "MealEntryPage"],
				"Input" -> (Keys[Uncompress @ Lookup[defaults, "foodToAmount"]] /. e_Entity :> CanonicalName[e])
			|>
		},
		mealEntryAction[root][Join[#, KeyTake[defaults, {"mode", "action", "foodToAmount", "entity"}]]]&,
		AppearanceRules -> <|
			"Title" -> "Meal entry",
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]]
				}
			],
			"ItemLayout" -> "Vertical"
		|>
	]
];

mealEntryAction[root_][results_Association] := Module[
	{url},
	
	url = URLBuild[
		FileNameJoin[{root, "ServingSizeEntry"}],
		{
			"meal" -> Switch[#action,
				"update",   #entity,
				"new",      ToCamelCase[#Description]
			],
			"description" -> #Description,
			"mealType" -> #MealType,
			"foodToAmount" -> Compress @ AssociationThread[#Foods -> Lookup[Uncompress[#foodToAmount] // KeyMap[CanonicalName], #Foods, 1]],
			"action" -> #action,
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