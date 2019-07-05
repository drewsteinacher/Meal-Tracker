ClearAll["Pages`ChooseMealPage`*"];
ClearAll["Pages`ChooseMealPage`*`*"];

BeginPackage["Pages`ChooseMealPage`", {"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`"}];

DeployChooseMealPage::usage = "";

Begin["`Private`"];

DeployChooseMealPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	chooseMealAPI[root],
	FileNameJoin[{root, "ChooseMeal"}],
	opts
];

$ParametersPassedToAction = {"mode", "editQ", "servingCount"};

chooseMealAPI[root_CloudObject] := APIFunction[
	{
		"mealType" -> RepeatingElement["String"] :> GetMealTypeFromTime[],
		"editQ" -> "Boolean" -> False,
		"servingCount" -> "Number" -> 1,
		"meal" -> "String" -> "",
		"mode" -> {"none", "test", "submit"} -> "none"
	},
	(
		Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
		With[{form = chooseMealForm[root][#]},
			Switch[#mode,
				"test" | "submit",  form[#],
				_,                  form
			]
		]
	)&
];

chooseMealForm[root_CloudObject][defaults_Association] := Module[
	{configuration, nutritionTargets, nutritionToLabel, foodData, mealTypes, meals},
	
	LoadEntityStore[root, "MyMeal"];
	
	mealTypes = Lookup[defaults, "mealType", $MealTypes];
	mealTypes = Intersection[mealTypes, $MealTypes] // Replace[{} -> $MealTypes];

	meals = EntityList @ Sort @ EntityClass["MyMeal", "MealTypes" -> ContainsAny[mealTypes]];
	
	FormFunction[
		{
			"ServingCount" -> <|
				"Interpreter" -> "Number",
				"Label" -> "Serving count",
				"Input" -> Lookup[defaults, "servingCount"]
			|>,
			"Meal" -> <|
				"Interpreter" -> Normal @ AssociationMap[Reverse, Sort @ EntityValue[meals, "Label", "EntityAssociation"]],
				"Control" -> PopupMenu,
				"Help" -> AddMealHelpLinks[root],
				"Input" -> Replace[Lookup[defaults, "meal", None], s_String :> Entity["MyMeal", s]]
			|>,
			"Timestamp" :> DateInterpreterSpec[Now, "AutoSubmitting" -> {}],
			"MealType" -> <|
				"Interpreter" -> $MealTypes,
				"Control" -> SetterBar,
				"Input" :> First @ mealTypes
			|>,
			"EditQ" -> <|
				"Interpreter" -> "Boolean",
				"Label" -> "Edit servings for this meal?",
				"Input" -> Lookup[defaults, "editQ", False]
			|>
		},
		chooseMealAction[root][Join[#, KeyTake[defaults, $ParametersPassedToAction]]]&,
		AppearanceRules -> <|
			"Title" -> "Log Meal",
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]]
				}
			],
			"ItemLayout" -> "Vertical"
		|>
	]
];

chooseMealAction[root_][results_Association] := Module[
	{url, mealData, servingCount},
	
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
	Get[FileNameJoin[{root, "Utilities", "GenerateData.wl"}]];
	
	servingCount = Replace[Lookup[results, "ServingCount", "servingCount"], Except[_?NumberQ] -> 1.];
	
	LoadEntityStore[root, "MyFood"];
	LoadEntityStore[root, "MyMeal"];
	
	url = If[TrueQ[results["EditQ"]] || TrueQ[results["editQ"]],
		
		mealData = EntityValue[results["Meal"], {"Label", "MealTypes", "Ingredients", "ServingCount"}, "PropertyAssociation"];
		
		URLBuild[
			FileNameJoin[{root, "ServingSizeEntry"}],
			{
				"meal" -> results["Meal"]["CanonicalName"],
				"servingCount" -> Replace[N[servingCount / Lookup[#, "ServingCount", 1.]], Except[_?NumberQ] -> 1.],
				"description" -> #Label,
				"mealType" -> #MealTypes,
				"foodToAmount" -> Compress @ Association[Rule @@@ #Ingredients],
				"timestamp" -> Compress[results["Timestamp"]],
				"action" -> "log",
				"mode" -> Lookup[results, "mode"]
			}&[mealData]
		]
		,
		
		LogMeal[root, #Meal, servingCount, #MealType, #Timestamp]&[results];
		
		(* TODO: Redirect to results page *)
		URLBuild @ FileNameJoin[{root, "Home"}]
	];
	
	Switch[results["mode"],
		"test",     url,
		_,          HTTPRedirect[url]
	]
];


End[];
EndPackage[];