ClearAll["Pages`NutritionEntryPage`*"];
ClearAll["Pages`NutritionEntryPage`*`*"];

BeginPackage["Pages`NutritionEntryPage`", {"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`"}];

DeployNutritionEntryPage::usage = "";

Begin["`Private`"];

DeployNutritionEntryPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	nutritionEntryAPI[root],
	FileNameJoin[{root, "NutritionEntry"}],
	opts
];

$ParametersPassedToAction = {"description", "mode", "action", "resubmitPage", "Resubmit"};

nutritionEntryAPI[root_CloudObject] := APIFunction[
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
		With[{form = nutritionEntryForm[root][#]},
			Switch[#mode,
				"test" | "submit",  form[#],
				_,                  form
			]
		]
	)&
];

nutritionEntryForm[root_CloudObject][parameters_Association] := Module[
	{entity, servingSizeMass, servingSizeString, description, nutrients, nutrientToAmount},
	
	Check[
		{entity, servingSizeMass} = Uncompress /@ Lookup[parameters, {"entity", "servingSizeMass"}];,
		Return["Error in uncompressing parameters"];
	];
	description = Lookup[parameters, "description"];
	servingSizeString = Lookup[parameters, "servingSizeString"];
	
	nutrients = Keys[GetConfiguration[root, "NutritionTargets"]][[All, 2]];
	
	If[MatchQ[entity, _String],
		entity = SafeInterpreter["Food"][entity];
	];
	
	nutrientToAmount = Switch[entity,
		
		Entity["Food", _],
		AssociationThread[
			nutrients,
			EntityValue[EntityInstance[entity, servingSizeMass], "Absolute" <> # <> "Content"& /@ nutrients]
		]
		,
			
		Entity["MyFood" | "MyMeal", _],
		LoadEntityStore[root, "MyFood"];
		LoadEntityStore[root, "MyMeal"];
		EntityValue[entity, nutrients, "PropertyAssociation"]
		,
		
		_,
		entity = Missing["NotAvailable"];
		AssociationMap[Missing["NotAvailable"]&, nutrients]
	];
	
	FormFunction[
		Join[
			{
				"Description" -> <|
					"Interpreter" -> "String",
					"Input" -> Lookup[parameters, "description"]
				|>,
				"ServingSize" -> <|
					"Label" -> "Serving size",
					"Interpreter" -> "String",
					"Input" -> servingSizeString,
					"Help" -> ServingSizeHelpMessage[]
				|>
			},
			KeyValueMap[nutrientAmountField, nutrientToAmount],
			If[parameters["action"] === "new",
				{
					"Resubmit" -> <|
						"Interpreter" -> "Boolean",
						"Label" -> "Add another?",
						"Help" -> "Check this box if you are adding another food directly after submitting this one.",
						"Input" -> False
					|>
				},
				{}
			]
		],
		nutritionEntryAction[root][Join[#, KeyTake[parameters, $ParametersPassedToAction], <|"Entity" -> entity|>]]&,
		AppearanceRules -> <|
			"Title" -> StringReplace[
				StringTemplate["Enter nutrition for `` `` "][First @ StringSplit[servingSizeString, ";"], description],
				{"()" -> "", Whitespace -> " "}
			],
			"Description" -> Hyperlink["Return home", FileNameJoin[{root, "Home"}]],
			"ItemLayout" -> "Vertical"
		|>
	]
	
];

nutrientAmountField[nutrient_, amount_] :=
    Rule[
	    nutrient,
	    <|
		    "Interpreter" -> nutrientToInterpreterSpec[nutrient],
		    "Label" -> FromCamelCase[nutrient],
		    "Input" -> StringTrim @ QuantityToString[amount],
		    "Default" -> amount,
		    "Required" -> False
	    |> // DeleteMissing
    ];

nutrientToInterpreterSpec[_String?(StringEndsQ["Calories"])] = Restricted["Quantity", "LargeCalories"];
nutrientToInterpreterSpec[_String] = Restricted["Quantity", QuantityVariable["Mass"]] | Restricted["Quantity", "Percent"];


nutritionEntryAction[root_][results_Association] := Module[
	{url},
	
	Get[FileNameJoin[{root, "MealTrackerApp.wl"}]];
	Get[FileNameJoin[{root, "Utilities", "GenerateData.wl"}]];
	Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
	Get[FileNameJoin[{root, "Pages", "ViewFood.wl"}]];
	
	LoadEntityStore[root, "MyFood"];
	
	url = FileNameJoin[{root, "ViewFood"}];
	
	If[Lookup[results, "mode"] === "test",
		url
		,
		
		Switch[results["action"],
			"new",
			AddFoodEntry[root][#Description, #ServingSize, KeyDrop[#, $ParametersPassedToAction], #Entity]&[results],
			
			"update",
			UpdateFoodEntry[root][#Entity, #Description, #ServingSize, KeyDrop[#, $ParametersPassedToAction], #Entity["Food"]]&[results]
		];
		
		UpdateEntityStore[root, "MyFood"];
		
		DeployViewFoodPage[root, Permissions -> "Public"];
		If[Lookup[results, "Resubmit", False],
			url = FileNameJoin[{root, Lookup[results, "resubmitPage"]}];
		];
		HTTPRedirect[url]
		
	]
];

End[];
EndPackage[];