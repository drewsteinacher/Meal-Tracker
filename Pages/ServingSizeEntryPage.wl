ClearAll["Pages`ServingSizeEntryPage`*"];
ClearAll["Pages`ServingSizeEntryPage`*`*"];

BeginPackage["Pages`ServingSizeEntryPage`", {"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`"}];

DeployServingSizeEntryPage::usage = "";

Begin["`Private`"];

DeployServingSizeEntryPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	servingSizeEntryAPI[root],
	FileNameJoin[{root, "ServingSizeEntry"}],
	opts
];

$ParametersPassedToAction = {"meal", "description", "mealType", "mode", "foodToAmount", "action", "timestamp", "servingCount"};

servingSizeEntryAPI[root_CloudObject] := APIFunction[
	{
		"meal" -> "String" -> "",
		"description" -> "String",
		"mealType" -> RepeatingElement["String"],
		"servingCount" -> "Number" -> 1,
		"foodToAmount" -> "String",
		"action" -> {"new", "update", "log"},
		"timestamp" -> "String" :> Compress[Now],
		"mode" -> {"none", "test", "submit"} -> "none"
	},
	(
		Get[FileNameJoin[{root, "MealTrackerApp.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
		With[{form = servingSizeEntryForm[root][#]},
			Switch[#mode,
				"test" | "submit",  form[#],
				_,                  form
			]
		]
	)&
];

servingSizeEntryForm[root_CloudObject][parameters_Association] := Module[
	{foodToAmount, foodData, foods, servingCount},
	
	servingCount = Lookup[parameters, "servingCount", 1];
	
	foodToAmount = Uncompress @ Lookup[parameters, "foodToAmount"];
	foodToAmount = KeyMap[Replace[e_Entity :> CanonicalName[e]], foodToAmount];
	foodToAmount = Replace[x: (_?NumberQ | _Quantity) :> x / servingCount] /@ foodToAmount;
	
	LoadEntityStore[root, "MyFood"];
	
	foodData = EntityValue[
		Replace[s_String :> Entity["MyFood", s]] /@ Keys[foodToAmount],
		{"Label", "ServingSizes"},
		"EntityPropertyAssociation"
	];
	foodData = KeyMap[CanonicalName] @ foodData;
	
	FormFunction[
		Join[
			If[parameters["action"] =!= "log",
				{
					"ServingCount" -> <|
						"Interpreter" -> "Number",
						"Label" -> "Serving count",
						"Input" -> Lookup[parameters, "servingCount"]
					|>
				},
				{}
			],
			KeyValueMap[
				Function[{foodCanonicalName, amount},
					foodCanonicalName -> <|
						"Interpreter" -> "Number" | "Quantity",
						(* TODO: Improve display of equivalent serving sizes *)
						"Label" -> StringTemplate["`Label` `ServingSizes`"][foodData[foodCanonicalName]],
						"Input" -> StringTrim[StringReplace[QuantityToString[amount], "servings" | "serving" -> ""]]
					|>
				],
				foodToAmount
			]
		],
		servingSizeEntryAction[root][Join[#, KeyTake[parameters, $ParametersPassedToAction]]]&,
		AppearanceRules -> <|
			(* TODO: Simplify the serving size string? *)
			"Title" -> StringTemplate["Enter amounts for `description`"][parameters],
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]],
					ServingAmountHelpMessage[]
				}
			],
			"ItemLayout" -> "Inline"
		|>
	]
];

servingSizeEntryAction[root_][results_Association] := Module[
	{url, meal, servingCount, foodToServings},
	
	Get[FileNameJoin[{root, "MealTrackerApp.wl"}]];
	Get[FileNameJoin[{root, "Utilities", "GenerateData.wl"}]];
	Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
	
	LoadEntityStore[root, "MyFood"];
	LoadEntityStore[root, "MyMeal"];
	
	url = URLBuild @ FileNameJoin[{root, "ViewMeal"}];
	
	servingCount = Lookup[#, "ServingCount", #servingCount]&[results];
	foodToServings = KeyTake[#, Replace[e_Entity :> CanonicalName[e]] /@ Keys @ Uncompress[#foodToAmount]]&[results];
	
	Switch[results["action"],
		
		"new",
		meal = AddMealEntry[root][#description, #mealType, servingCount, foodToServings]&[results];
		UpdateEntityStore[root, "MyMeal"];
		,
		
		"update",
		meal = getMealEntity[results];
		meal = UpdateMealEntry[root][meal, #description, #mealType, servingCount, foodToServings]&[results];
		UpdateEntityStore[root, "MyMeal"];
		,
		
		"log",
		meal = getMealEntity[results];
		LogMeal[root, meal, servingCount, First[#mealType], Uncompress @ #timestamp, Replace[n_?NumberQ :> servingCount / n ] /@ foodToServings]&[results];
		url = URLBuild @ FileNameJoin[{root, "Home"}];
		,
		
		_,
		$Failed
		
	];
	
	Switch[results["mode"],
		"test",     url,
		_,          HTTPRedirect[url]
	]
];

getMealEntity = Replace[
	Lookup[#, "meal", ""],
	{
		"" :> Replace[Keys[Uncompress[#foodToAmount]], s_String :> Entity["MyFood", s], {1}],
		s_String :> Entity["MyMeal", s]
	}
]&;

End[];
EndPackage[];