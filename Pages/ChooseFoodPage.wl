ClearAll["Pages`ChooseFoodPage`*"];
ClearAll["Pages`ChooseFoodPage`*`*"];

BeginPackage["Pages`ChooseFoodPage`", {"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`"}];

DeployChooseFoodPage::usage = "";

Begin["`Private`"];

DeployChooseFoodPage[root_, opts : OptionsPattern[]] := CloudDeploy[
	chooseFoodAPI[root],
	FileNameJoin[{root, "ChooseFood"}],
	opts
];

chooseFoodAPI[root_CloudObject] := APIFunction[
	{
		"mealType" -> "String" :> GetMealTypeFromTime[],
		"editQ" -> "Boolean" -> True,
		"servings" -> RepeatingElement["Number"] -> {},
		"food" -> RepeatingElement["String"] -> "",
		"mode" -> {"none", "test", "submit"} -> "none"
	},
	(
		Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
		With[{form = chooseFoodForm[root][#]},
			Switch[#mode,
				"test" | "submit", form[#],
				_, form
			]
		]
	)&
];

chooseFoodForm[root_CloudObject][defaults_Association] := Module[
	{},
	
	LoadEntityStore[root, "MyFood"];
	
	FormFunction[
		{
			"Foods" -> <|
				"Interpreter" -> AnySubset @ Normal @ Sort @ AssociationMap[Reverse, EntityValue["MyFood", "Label", "EntityAssociation"]],
				"Control" -> TogglerBar,
				"Help" -> AddFoodHelpLinks[root, "ChooseFoodPage"],
				"Input" -> (Lookup[defaults, "food", {}] // Map[Replace[s_String :> Entity["MyFood", s]]])
			|>,
			"Timestamp" :> DateInterpreterSpec[Now, "AutoSubmitting" -> {}],
			"MealType" -> <|
				"Interpreter" -> $MealTypes,
				"Control" -> SetterBar,
				"Input" :> Lookup[defaults, "mealType"]
			|>,
			"EditQ" -> <|
				"Interpreter" -> "Boolean",
				"Label" -> "Edit servings for this meal?",
				"Help" -> "If unchecked, a single default serving of each selected food will be used.",
				"Input" -> Lookup[defaults, "editQ", True]
			|>
		},
		chooseFoodAction[root][Join[#, KeyTake[defaults, "mode"]]]&,
		AppearanceRules -> <|
			"Title" -> "Log Foods",
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]]
				}
			],
			"ItemLayout" -> "Vertical"
		|>
	]
];

chooseFoodAction[root_][results_Association] := Module[
	{url, mealData, entity},
	
	Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
	
	LoadEntityStore[root, "MyFood"];
	
	entity = results["Foods"];
	
	mealData = <|
		"Label" -> If[Length[#Foods] === 1, First[#Foods]["Label"], "Custom " <> #MealType],
		"MealTypes" -> {#MealType},
		"Ingredients" -> Thread[#Foods -> ConstantArray[Quantity[1, "Servings"], Length[#Foods]]]
	|>&[results];
	
	
	url = If[TrueQ @ results["EditQ"],
		URLBuild[
			FileNameJoin[{root, "ServingSizeEntry"}],
			{
				"meal" -> "",
				"description" -> #Label,
				"mealType" -> #MealTypes,
				"foodToAmount" -> Compress @ Association[Rule @@@ #Ingredients],
				"timestamp" -> Compress[results["Timestamp"]],
				"action" -> "log",
				"mode" -> Lookup[results, "mode"]
			}&[mealData]
		]
		
		,
		Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "GenerateData.wl"}]];
		LogMeal[root, entity, 1, #MealType, #Timestamp]&[results];
		
		(* TODO: Redirect to results page *)
		URLBuild @ FileNameJoin[{root, "Home"}]
	];
	
	Switch[results["mode"],
		"test", url,
		_,      HTTPRedirect[url]
	]

];


End[];
EndPackage[];