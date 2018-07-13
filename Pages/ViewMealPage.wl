ClearAll["Pages`ViewMealPage`*"];
ClearAll["Pages`ViewMealPage`*`*"];

BeginPackage["Pages`ViewMealPage`", (Get[#];#)& /@ {"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`"}];

DeployViewMealPage::usage = "";

Begin["`Private`"];

DeployViewMealPage[root_, opts : OptionsPattern[]] := CloudDeploy[
	Delayed[
		Get[FileNameJoin[{root, "MealTrackerApp.wl"}]];
		Get[FileNameJoin[{root, "Pages", "ViewMealPage.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
		mealViewAPI[root]
	],
	FileNameJoin[{root, "ViewMeal"}],
	opts
];

mealViewAPI[root_CloudObject] := APIFunction[
	{
		"mealType" -> AnySubset[$MealTypes] -> $MealTypes
	},
	mealGalleryView[root][#]&
];

mealGalleryView[root_][parameters_Association] := Module[
	{mealData, foodData, mealTypes, nutrients, properties},
	
	mealTypes = parameters["mealType"];
	
	LoadEntityStore[root, "MyMeal"];
	LoadEntityStore[root, "MyFood"];
	
	nutrients = Keys @ GetConfiguration[root, "NutritionTargets"];
	properties = nutrients[[All, 2]];
	
	mealData = EntityValue[
		EntityClass["MyMeal", "MealTypes" -> ContainsAny@mealTypes],
		Join[{"Label", "MealTypes", "Ingredients"}, properties],
		"EntityPropertyAssociation"
	];
	
	GalleryView[
		KeyValueMap[
			Function[{mealEntity, mealAssociation},
				Grid[
					List /@ {
						editHyperlink[root][mealEntity, #Label],
						Row[#MealTypes, Spacer[1]],
						
						"Ingredients:",
						Grid[
							{QuantityToString[#2], #1["Label"]}& @@@ #Ingredients,
							Frame -> All
						],
						
						"Nutrition per serving:",
						Grid[
							KeyValueMap[
								{
									FromCamelCase[#1],
									QuantityToString[#2]
								}&,
								KeyTake[#, properties]
							],
							Frame -> All
						]
					},
					Alignment -> Center,
					Frame -> True
				]&[mealAssociation]
			],
			mealData
		],
		AppearanceRules -> <|
			"Title" -> "View Meals",
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]]
				}
			]
		|>,
		Pagination -> {6, 2}
	]
];

editHyperlink[root_CloudObject][meal : Entity["MyMeal", _], label_String: "Click here to edit"] :=
	Hyperlink[
		label,
		URLBuild[
			FileNameJoin[{root, "MealEntry"}],
			<|
				"entity" -> CanonicalName[meal],
				"description" -> meal["Label"],
				"mealType" -> meal["MealTypes"],
				"foodToAmount" -> Compress @ Association[Rule[#1, #2]& @@@ meal["Ingredients"]],
				"action" -> "update"
			|> // DeleteMissing
		]
	
	];

End[];
EndPackage[];