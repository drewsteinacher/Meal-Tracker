BeginTestSection["MealTrackerApp"];

VerificationTest[
	Get["MealTrackerApp.wl"],
	Null,
	TestID -> "Load-package"
];

VerificationTest[
	root = CloudObject["Temporary_" <> DateString["ISODate"]],
	_CloudObject,
	SameTest -> MatchQ,
	TestID -> "Temporary-Root-CloudObject"
];

VerificationTest[
	FileExistsQ[root],
	False,
	TestID -> "Temporary-Root-CloudObject-should-not-exist"
];

VerificationTest[
	bin = Databin["sEv5jeQT"],
	_Databin,
	SameTest -> MatchQ,
	TestID -> "History-Databin"
];

VerificationTest[
	DeployMealTrackerApp[root, "DefaultDirectory" -> 7],
	$Failed,
	{DeployMealTrackerApp::invalidDirectory},
	TestID -> "DeployMealTrackerApp-invalid-default-directory"
];

VerificationTest[
	DeployMealTrackerApp[root, "HistoryDatabin" -> bin],
	{__CloudObject},
	SameTest -> MatchQ,
	TestID -> "DeployMealTrackerApp-valid-with-Databin"
];

VerificationTest[
	DeployMealTrackerApp[root],
	{__CloudObject},
	SameTest -> MatchQ,
	TestID -> "DeployMealTrackerApp-valid-no-Databin-after-initial-deployment"
];

VerificationTest[
	oldConfiguration = GetConfiguration[root],
	_Association,
	SameTest -> MatchQ,
	TestID -> "GetConfiguration-single-argument"
];

VerificationTest[
	Keys @ GetConfiguration[root, "NutritionTargets"],
	{Entity["Nutrient", _String]..},
	SameTest -> MatchQ,
	TestID -> "GetConfiguration-two-argument"
];

VerificationTest[
	SetConfiguration[root,
		newConfiguration = <|
			"HistoryDatabin" -> bin,
			"DietaryRestrictions" -> {Entity["DietaryRestriction", "Vegetarian"]},
			"NutritionTargets" -> <|
				Entity["Nutrient", "TotalCalories"] -> Quantity[2000, "LargeCalories" / "Days"],
				Entity["Nutrient", "Calcium"] -> Quantity[1., "Grams" / "Days"],
				Entity["Nutrient", "Cholesterol"] -> Quantity[0.3, "Grams" / "Days"],
				Entity["Nutrient", "Iron"] -> Quantity[0.018, "Grams" / "Days"],
				Entity["Nutrient", "Sodium"] -> Quantity[2.4, "Grams" / "Days"],
				Entity["Nutrient", "TotalCarbohydrates"] -> Quantity[300, "Grams" / "Days"],
				Entity["Nutrient", "TotalFat"] -> Quantity[65, "Grams" / "Days"],
				Entity["Nutrient", "TotalFiber"] -> Quantity[25, "Grams" / "Days"],
				Entity["Nutrient", "TotalProtein"] -> Quantity[50, "Grams" / "Days"],
				Entity["Nutrient", "TotalSaturatedFat"] -> Quantity[20, "Grams" / "Days"],
				Entity["Nutrient", "VitaminC"] -> Quantity[0.06, "Grams" / "Days"]
			|>
		|>
	],
	_CloudObject,
	SameTest -> MatchQ,
	TestID -> "SetConfiguration-two-argument"
];

VerificationTest[
	GetConfiguration[root, "DietaryRestrictions"],
	{Entity["DietaryRestriction", "Vegetarian"]},
	TestID -> "SetConfiguration-verification"
];

VerificationTest[
	SetConfiguration[root, "DietaryRestrictions", {}],
	_CloudObject,
	SameTest -> MatchQ,
	TestID -> "SetConfiguration-three-argument"
];

VerificationTest[
	GetConfiguration[root, "DietaryRestrictions"],
	{},
	TestID -> "SetConfiguration-three-argument-confirmation"
];

VerificationTest[
	LoadEntityStore[root, "MyFood"],
	{"MyFood"},
	TestID -> "LoadEntityStore-MyFood"
];

VerificationTest[
	EntityValue[Entity["MyFood", "Honey"], "ServingSizes"],
	{Quantity[1, "Cups"], Quantity[339., "Grams"]},
	TestID -> "MyFood-ServingSize"
];


VerificationTest[
	EntityValue[Entity["MyFood", "Honey"], "TotalCalories"],
	Quantity[1030.56, "LargeCalories"],
	TestID -> "MyFood-TotalCalories"
];

VerificationTest[
	Entity["MyFood", "Honey"]["TotalCalories", "Amount" -> Quantity[3, "Servings"]],
	Quantity[3091.68, "LargeCalories"],
	TestID -> "MyFood-TotalCalories-servings"
];

VerificationTest[
	Entity["MyFood", "Honey"]["TotalCalories", "Amount" -> 3],
	Quantity[3091.68, "LargeCalories"],
	TestID -> "MyFood-TotalCalories-number"
];

VerificationTest[
	Entity["MyFood", "Honey"]["TotalCalories", "Amount" -> Quantity[42, "Grams"]],
	Quantity[127.67999999999999, "LargeCalories"],
	TestID -> "MyFood-TotalCalories-grams"
];

VerificationTest[
	Entity["MyFood", "Honey"]["TotalCalories", "Amount" -> Quantity[85, "Joules"]],
	Missing["NotAvailable"],
	TestID -> "MyFood-TotalCalories-incompatible"
];

VerificationTest[
	AddFoodEntry[root]["My new food 1", "1 cup; 30g; 1/4 tbsp", <|"TotalCalories" -> Quantity[120, "LargeCalories"]|>, Entity["Food", {"Variety" -> "RedDelicious"}]],
	Entity["MyFood", "MyNewFood1"],
	TestID -> "AddFoodEntry"
];

VerificationTest[
	Sort @ EntityValue["MyFood", "CanonicalName"],
	Sort @ {"Egg", "WhiteBread", "PeanutButter", "Jelly", "Milk", "Oats", "GreekYogurt", "FlaxSeed", "Honey", "VanillaExtract", "MyNewFood1"},
	TestID -> "AddFoodEntry-CanonicalName"
];

VerificationTest[
	Entity["MyFood", "MyNewFood1"]["Label"],
	"My new food 1",
	TestID -> "AddFoodEntry-Label"
];

VerificationTest[
	Entity["MyFood", "MyNewFood1"]["ServingSizes"],
	{Quantity[1, "Cups"], Quantity[30, "Grams"], Quantity[1/4, "Tablespoons"]},
	TestID -> "AddFoodEntry-ServingSizes"
];

VerificationTest[
	UpdateFoodEntry[root][Entity["MyFood", "WhiteBread"], "bread", "1 slice; 43 g", Entity["MyFood", "WhiteBread"]["NutritionAssociation"], Entity["MyFood", "WhiteBread"]["Food"]],
	Entity["MyFood", "WhiteBread"],
	TestID -> "UpdateFoodEntry"
];

VerificationTest[
	Entity["MyFood", "WhiteBread"]["Label"],
	"bread",
	TestID -> "UpdateFoodEntry-Label"
];

VerificationTest[
	Entity["MyFood", "WhiteBread"]["ServingSizes"],
	{Quantity[1, "Slices"], Quantity[43, "Grams"]},
	TestID -> "UpdateFoodEntry-ServingSizes"
];

VerificationTest[
	LoadEntityStore[root, "MyFood"],
	{"MyFood"},
	TestID -> "UpdateFoodEntry-reset-EntityStore"
];

VerificationTest[
	LoadEntityStore[root, "MyMeal"],
	{"MyMeal"},
	TestID -> "LoadEntityStore-MyMeal"
];

VerificationTest[
	Entity["MyMeal", "PB&JSandwich"]["TotalCalories"],
	Quantity[485.86, "LargeCalories"],
	TestID -> "MyMeal-TotalCalories"
];

VerificationTest[
	Entity["MyMeal", "PB&JSandwich"]["TotalCalories", "Amounts" -> 2],
	Quantity[751.72, "LargeCalories"],
	TestID -> "MyMeal-TotalCalories-double-all-amounts"
];

VerificationTest[
	Entity["MyMeal", "PB&JSandwich"]["TotalCalories", "Amounts" -> {"PeanutButter" -> Quantity[2, "Servings"], "Jelly" -> Quantity[3, "Servings"], "WhiteBread" -> Quantity[0.5, "Servings"]}],
	Quantity[642.5799999999999, "LargeCalories"],
	TestID -> "MyMeal-TotalCalories-specify-all-amounts-as-servings"
];

VerificationTest[
	Entity["MyMeal", "PB&JSandwich"]["TotalCalories", "Amounts" -> {"PeanutButter" -> 2, "Jelly" -> 3, "WhiteBread" -> 0.5}],
	Quantity[642.5799999999999, "LargeCalories"],
	TestID -> "MyMeal-TotalCalories-specify-all-amounts-as-numbers"
];

VerificationTest[
	Entity["MyMeal", "PB&JSandwich"]["TotalCalories", "Amounts" -> {"PeanutButter" -> Quantity[50, "Grams"], "Jelly" -> Quantity[30, "Grams"], "WhiteBread" -> Quantity[5, "Servings"]}],
	Quantity[957.925, "LargeCalories"],
	TestID -> "MyMeal-TotalCalories-specify-all-amounts-as-quantities"
];

VerificationTest[
	Entity["MyMeal", "PB&JSandwich"]["TotalCalories", "Amounts" -> {"PeanutButter" -> Quantity[50, "Grams"]}],
	Quantity[603.985, "LargeCalories"],
	TestID -> "MyMeal-TotalCalories-specify-some-amounts"
];

VerificationTest[
	Entity["MyMeal", "PB&JSandwich"]["TotalCalories", "Amounts" -> Quantity[50, "Joules"]],
	Missing["NotAvailable"],
	TestID -> "MyMeal-TotalCalories-invalid-amounts"
];

VerificationTest[
	Entity["MyMeal", "PB&JSandwich"]["TotalCalories", "Amounts" -> Association[]],
	Quantity[485.86, "LargeCalories"],
	TestID -> "MyMeal-TotalCalories-no-amounts"
];

VerificationTest[
	Entity["MyMeal", "OvernightOats"]["ServingCount"],
	2,
	TestID -> "MyMeal-ServingCount"
];

VerificationTest[
	Entity["MyMeal", "OvernightOats"]["TotalCalories", "Amounts" -> 1],
	Entity["MyMeal", "OvernightOats"]["TotalCalories"],
	TestID -> "MyMeal-TotalCalories-default-behavior"
];

VerificationTest[
	Total[(QuantityMagnitude[#2]*#1["TotalCalories"]) & @@@ Entity["MyMeal", "OvernightOats"]["Ingredients"]],
	Times @@ EntityValue[Entity["MyMeal", "OvernightOats"], {"TotalCalories", "ServingCount"}],
	TestID -> "MyMeal-ServingCount-makes-default-return-one-serving-based-on-ServingCount"
];

VerificationTest[
	EntityPropertyClass["MyMeal", "Nutrition"]["Properties"],
	{__EntityProperty},
	SameTest -> MatchQ,
	TestID -> "MyMeal-Nutrition-PropertyClass-properties"
];

VerificationTest[
	DeleteMissing[EntityValue[Entity["MyMeal", "OvernightOats"], "NutritionAssociation"]],
	a_Association /; (Length[a] > 0),
	SameTest -> MatchQ,
	TestID -> "MyMeal-NutritionAssociation"
];

VerificationTest[
	DeleteMissing[Entity["MyMeal", "OvernightOats"]["NutritionAssociation", "Amounts" -> <||>]],
	a_Association /; (Length[a] > 0),
	SameTest -> MatchQ,
	TestID -> "MyMeal-NutritionAssociation-specify-no-amounts"
];

VerificationTest[
	Entity["MyMeal", "OvernightOats"]["NutritionAssociation", "Amounts" -> 2],
	_Association,
	SameTest -> MatchQ,
	TestID -> "MyMeal-NutritionAssociation-double-all-amounts"
];

VerificationTest[
	Entity["MyMeal", "OvernightOats"]["NutritionAssociation", "Amounts" -> {"PeanutButter" -> Quantity[2, "Servings"], "Jelly" -> Quantity[3, "Servings"], "WhiteBread" -> Quantity[0.5, "Servings"]}],
	_Association,
	SameTest -> MatchQ,
	TestID -> "MyMeal-NutritionAssociation-specify-all-amounts-as-servings"
];

VerificationTest[
	Entity["MyMeal", "OvernightOats"]["NutritionAssociation", "Amounts" -> {"PeanutButter" -> 2, "Jelly" -> 3, "WhiteBread" -> 0.5}],
	_Association,
	SameTest -> MatchQ,
	TestID -> "MyMeal-NutritionAssociation-specify-all-amounts-as-numbers"
];

VerificationTest[
	Entity["MyMeal", "OvernightOats"]["NutritionAssociation", "Amounts" -> {"PeanutButter" -> Quantity[50, "Grams"], "Jelly" -> Quantity[30, "Grams"], "WhiteBread" -> Quantity[5, "Servings"]}],
	_Association,
	SameTest -> MatchQ,
	TestID -> "MyMeal-NutritionAssociation-specify-all-amounts-as-quantities"
];

VerificationTest[
	Entity["MyMeal", "OvernightOats"]["NutritionAssociation", "Amounts" -> {"PeanutButter" -> Quantity[50, "Grams"]}],
	_Association,
	SameTest -> MatchQ,
	TestID -> "MyMeal-NutritionAssociation-specify-some-amounts"
];

VerificationTest[
	Entity["MyMeal", "OvernightOats"]["NutritionAssociation", "Amounts" -> Quantity[50, "Joules"]],
	_Association,
	SameTest -> MatchQ,
	TestID -> "MyMeal-NutritionAssociation-invalid-amounts"
];

VerificationTest[
	AddMealEntry[root]["This Test Meal", {"Lunch"}, 2, <|"Milk" -> 3, "Honey" -> Quantity[10, "Grams"]|>],
	Entity["MyMeal", "ThisTestMeal"],
	TestID -> "AddMealEntry-simple"
];

VerificationTest[
	Sort @ EntityValue["MyMeal", "CanonicalName"],
	Sort @ {"OvernightOats", "PB&JSandwich", "ThisTestMeal"},
	TestID -> "AddMealEntry-simple-CanonicalName"
];

VerificationTest[
	Entity["MyMeal", "ThisTestMeal"]["Ingredients"],
	{EntityInstance[Entity["MyFood", "Milk"], Quantity[3, "Servings"]], EntityInstance[Entity["MyFood", "Honey"], Quantity[_, "Servings"]]},
	SameTest -> MatchQ,
	TestID -> "AddMealEntry-simple-Ingredients"
];

VerificationTest[
	UpdateMealEntry[root][Entity["MyMeal", "ThisTestMeal"], "My Test Meal Updated", {"Lunch"}, 2, <|"Milk" -> 1, "Honey" -> Quantity[10, "Grams"]|>],
	Entity["MyMeal", "ThisTestMeal"],
	TestID -> "UpdateMealEntry-simple"
];

VerificationTest[
	Sort @ EntityValue["MyMeal", "CanonicalName"],
	Sort @ {"OvernightOats", "PB&JSandwich", "ThisTestMeal"},
	TestID -> "UpdateMealEntry-simple-CanonicalName"
];

VerificationTest[
	Entity["MyMeal", "ThisTestMeal"]["Ingredients"],
	{EntityInstance[Entity["MyFood", "Milk"], Quantity[1, "Servings"]], EntityInstance[Entity["MyFood", "Honey"], Quantity[_, "Servings"]]},
	SameTest -> MatchQ,
	TestID -> "UpdateMealEntry-simple-Ingredients"
];

VerificationTest[
	URLFetch @ URLBuild[
		FileNameJoin[{root, "FoodEntry"}],
		{
			"description" -> "bananas",
			"servingSize" -> "30 g",
			"action" -> "new",
			"mode" -> "test"
		}
	],
	"https://www.wolframcloud.com/objects/andrews/MealTracker_2-23-2018/NutritionEntry?description=bananas&entity=1%3AeJxTTMoPCmZnYGBISswDwmIAIWgEcw%3D%3D&servingSizeString=30+g&action=new&mode=test",
	SameTest -> Function[{actual, expected},
		With[
			{
				parsedURLQueries = URLParse[StringTrim[#, "\""]]["Query"] & /@ {actual, expected}
			},
			SameQ @@ parsedURLQueries
		]
	],
	TestID -> "FoodEntry-Submission-description-serving-size-only"
];

VerificationTest[
	URLFetch @ URLBuild[
		FileNameJoin[{root, "NutritionEntry"}],
		{
			"description" -> "bananas",
			"entity" -> Compress["bananas"],
			"servingSizeString" -> "30 g",
			"action" -> "new",
			"mode" -> "test"
		}
	],
	(* TODO: Test redirect URL *)
	_String,
	SameTest -> MatchQ,
	TestID -> "NutritionEntry-Submission"
];

VerificationTest[
	LoadEntityStore[root, "MyFood"];
	Sort @ EntityValue["MyFood", "CanonicalName"],
	Sort @ {"Egg", "WhiteBread", "PeanutButter", "Jelly", "Milk", "Oats", "GreekYogurt", "FlaxSeed", "Honey", "VanillaExtract"},
	TestID -> "MyFood-entities-before-submission"
];

VerificationTest[
	URLBuild[
		FileNameJoin[{root, "NutritionEntry"}],
		{
			"description" -> "bananas",
			"entity" -> Compress["bananas"],
			"servingSizeString" -> "30 g",
			"action" -> "new",
			"mode" -> "submit"
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{"View Foods - Wolfram Cloud"},
	SameTest -> MatchQ,
	TestID -> "NutritionEntry-Submission-description-submit"
];

VerificationTest[
	LoadEntityStore[root, "MyFood"];
	Sort @ EntityValue["MyFood", "CanonicalName"],
	Sort @ {"Egg", "WhiteBread", "PeanutButter", "Jelly", "Milk", "Oats", "GreekYogurt", "FlaxSeed", "Honey", "VanillaExtract", "Bananas"},
	TestID -> "MyFood-Entities-after-submission"
];

VerificationTest[
	URLBuild[
		FileNameJoin[{root, "NutritionEntry"}],
		{
			"description" -> "Salsa",
			"entity" -> Compress[
				Entity["Food",
					{
						EntityProperty["Food", "FoodType"] -> ContainsExactly[{Entity["FoodType", "Salsa"]}],
						EntityProperty["Food", "AddedFoodTypes"] -> ContainsExactly[{}]
					}
				]
			],
			"servingSizeMass" -> Compress[Quantity[15, "Grams"]],
			"servingSizeString" -> "15 g",
			"action" -> "new",
			"mode" -> "submit"
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{"View Foods - Wolfram Cloud"},
	TestID -> "NutritionEntry-DV-Submission"
];

VerificationTest[
	LoadEntityStore[root, "MyFood"];
	Sort @ EntityValue["MyFood", "CanonicalName"],
	Sort @ {"Egg", "WhiteBread", "PeanutButter", "Jelly", "Milk", "Oats", "GreekYogurt", "FlaxSeed", "Honey", "VanillaExtract", "Bananas", "Salsa"},
	TestID -> "MyFood-Entities-after-DV-submission"
];

VerificationTest[
	LoadEntityStore[root, "MyFood"];
	Normal @ Entity["MyFood", "Salsa"]["NutritionAssociation"],
	{Rule[_String, Quantity[_?NumberQ, Except["Percent"]]]..},
	SameTest -> MatchQ,
	TestID -> "MyFood-Entities-DV-conversion"
];

VerificationTest[
	URLBuild[
		FileNameJoin[{root, "NutritionEntry"}],
		{
			"description" -> "Apples, raw, granny smith, with skin",
			"entity" -> Compress[Entity["Food", "ApplesRawGrannySmithWithSkin::dnxb4"]],
			"servingSizeString" -> "109 g",
			"servingSizeMass" -> Compress[Quantity[109, "Grams"]],
			"action" -> "new",
			"mode" -> "submit"
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{"View Foods - Wolfram Cloud"},
	TestID -> "NutritionEntry-Food-Entity-Submission"
];

VerificationTest[
	LoadEntityStore[root, "MyFood"];
	Sort @ EntityValue["MyFood", "CanonicalName"],
	Sort @ {"Egg", "WhiteBread", "PeanutButter", "Jelly", "Milk", "Oats", "GreekYogurt", "FlaxSeed", "Honey", "VanillaExtract", "Bananas", "Salsa", "Apples,Raw,GrannySmith,WithSkin"},
	TestID -> "MyFood-Entities-after-Food-Entity-submission"
];

VerificationTest[
	URLBuild[
		FileNameJoin[{root, "NutritionEntry"}],
		{
			"description" -> "Oats",
			"entity" -> Compress[Entity["MyFood", "Oats"]],
			"servingSizeString" -> "30 g",
			"action" -> "update",
			"mode" -> "submit"
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{"View Foods - Wolfram Cloud"},
	TestID -> "NutritionEntry-update"
];

VerificationTest[
	LoadEntityStore[root, "MyFood"];
	Entity["MyFood", "Oats"]["DateModified"],
	Now,
	SameTest -> Function[DateDifference[##] < Quantity[10, "Seconds"]],
	TestID -> "NutritionEntry-update-DateModified"
];

VerificationTest[
	LoadEntityStore[root, "MyMeal"];
	Sort @ EntityValue["MyMeal", "CanonicalName"],
	{"OvernightOats", "PB&JSandwich"},
	TestID -> "MyMeal-entities-before-submission"
];

VerificationTest[
	URLFetch @ URLBuild[
		FileNameJoin[{root, "MealEntry"}],
		{
			"description" -> "homemade vanilla yogurt",
			"mealType" -> {"Snack"},
			"foodToAmount" -> Compress[<|"FlaxSeed" -> 1, "GreekYogurt" -> 1, "Honey" -> 1, "VanillaExtract" -> 1|>],
			"action" -> "new",
			"mode" -> "test"
		}
	],
	"https://www.wolframcloud.com/objects/andrews/Temporary_2018-04-12/ServingSizeEntry?meal=HomemadeVanillaYogurt&description=homemade+vanilla+yogurt&mealType=Snack&foodToAmount=1%3AeJxTTMoPSmNhYGAo5gYSjsXF%2BcmZiSWZ%2BXlpTCBBkExQaU5qMAeQ4ZaTWBGcmpqSyQjkoMmDdLsXpaZmR%2BanlxaVYFPCCmR45OelVmKT5AMywhLzMnNyEl0rSooSkyFGAADQECLJ&action=new&mode=test",
	SameTest -> Function[{expected, actual},
		SameQ @@ (Merge[URLParse[#]["Query"], Identity] & /@ {expected, actual})
	],
	TestID -> "MealEntry-submission-redirect-test"
];

VerificationTest[
	URLBuild[
		FileNameJoin[{root, "ServingSizeEntry"}],
		{
			"meal" -> "HomemadeVanillaYogurt",
			"description" -> "homemade vanilla yogurt",
			"mealType" -> {"Snack"},
			"foodToAmount" -> Compress[<|"FlaxSeed" -> 1, "GreekYogurt" -> 1, "Honey" -> 1, "VanillaExtract" -> 1|>],
			"action" -> "new",
			"mode" -> "submit"
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{"View Meals - Wolfram Cloud"},
	TestID -> "ServingSizeEntry-new-submission-test"
];

VerificationTest[
	LoadEntityStore[root, "MyMeal"];
	Sort @ EntityValue["MyMeal", "CanonicalName"],
	{"HomemadeVanillaYogurt", "OvernightOats", "PB&JSandwich"},
	TestID -> "MyMeal-entities-after-new-submission"
];

VerificationTest[
	mealLogCountBefore = Length @ Normal @ Databin[bin, Today],
	_Integer,
	SameTest -> MatchQ,
	TestID -> "Meal-log-counts-before"
];

VerificationTest[
	URLFetch @ URLBuild[
		FileNameJoin[{root, "MealEntry"}],
		{
			"entity" -> "PB&JSandwich",
			"description" -> "PB & J Sandwich",
			"mealType" -> {"Lunch"},
			"foodToAmount" -> Compress[<|"WhiteBread" -> 2, "PeanutButter" -> 2, "Jelly" -> 1|>],
			"action" -> "update",
			"mode" -> "test"
		}
	],
	"https://www.wolframcloud.com/objects/andrews/Temporary_2018-04-12/ServingSizeEntry?meal=PB%26JSandwich&description=PB+%26+J+Sandwich&mealType=Lunch&foodToAmount=1%3AeJxTTMoPSmNmYGAo5gYSjsXF%2BcmZiSWZ%2BXlpTCBBFiARVJqTGswFZIRnZJakOhWlJqZkMgK5aCp4gIyA1MS80hKn0pKS1CJsaliBDK%2FUnJxKsCQA1hIbIg%3D%3D&action=update&mode=test",
	SameTest -> Function[{expected, actual},
		SameQ @@ (Merge[URLParse[#]["Query"], Identity] & /@ {expected, actual})
	],
	TestID -> "MealEntry-submission-redirect-test-update"
];

VerificationTest[
	Utilities`GenerateData`LogMeal[root, "PB&JSandwich", 1, "Lunch"],
	bin,
	TestID -> "LogMeal-defaults"
];

VerificationTest[
	Length @ Normal @ Databin[bin, Today] - mealLogCountBefore,
	1,
	TestID -> "Meal-log-counts-difference-after-LogMeal"
];

VerificationTest[
	Normal @ Databin[bin, -1, {"Meal", "MealType", "TotalCalories"}],
	{<|"Meal" -> Entity["MyMeal", "PB&JSandwich"], "MealType" -> "Lunch", "TotalCalories" -> Quantity[485.86, "LargeCalories"]|>},
	TestID -> "Meal-log-last-point-defaults"
];

VerificationTest[
	Utilities`GenerateData`LogMeal[root, "PB&JSandwich", 1, "Lunch", Now, <|"WhiteBread" -> 100|>],
	bin,
	TestID -> "LogMeal-with-changed-servings"
];

VerificationTest[
	Normal @ Databin[bin, -1, {"Meal", "MealType", "TotalCalories"}],
	List[Association[Rule["Meal", Entity["MyMeal", "PB&JSandwich"]], Rule["MealType", "Lunch"], Rule["TotalCalories", Quantity[11265.86, "LargeCalories"]]]],
	TestID -> "Meal-log-last-point-changed-servings"
];

VerificationTest[
	mealLogCountBefore = Length @ Normal @ Databin[bin, Today],
	_Integer,
	SameTest -> MatchQ,
	TestID -> "Meal-log-counts-before-form-submit"
];

VerificationTest[
	URLBuild[
		FileNameJoin[{root, "ChooseMeal"}],
		{
			"meal" -> "OvernightOats",
			"mealType" -> "Breakfast",
			"servingCount" -> 1,
			"editQ" -> False,
			"mode" -> "submit"
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{"Home Page - Wolfram Cloud"},
	TestID -> "ChooseMeal-simple-submit"
];

VerificationTest[
	Length @ Normal @ Databin[bin, Today] - mealLogCountBefore,
	1,
	TestID -> "Meal-log-counts-difference-after-simple-form-submit"
];

VerificationTest[
	URLFetch @ URLBuild[
		FileNameJoin[{root, "ChooseMeal"}],
		{
			"meal" -> "OvernightOats",
			"mealType" -> "Breakfast",
			"servingCount" -> 1,
			"editQ" -> True,
			"mode" -> "test"
		}
	],
	"\"https://www.wolframcloud.com/objects/andrews/Temporary_2018-04-23/ServingSizeEntry?meal=OvernightOats&servingCount=0.5&description=Overnight+Oats&mealType=Breakfast&foodToAmount=1%3AeJytkE0KwkAMhUdREQTv4FFctLopYgcEl7FNS%2BgwgfmRzu2d2AsozObx8nj5IDm9uB12Sil%2FyHL2njuCQGyHtYSbLG00uEzSq2ygkLTYJtXMvZbODYJfOvss9wjfFq3yoCXR6N5kR%2F8ftSEzlaXKkReHOD15jC6UhctWbWDWiH1Z8jbbK1tMZbHHbB9gyRio5uCg%2B%2BkhH4%2B7gBE%3D&timestamp=1%3AeJxTTMoPSmNhYGAo5gYSjsXF%2BcmZiSWZ%2BXlpTCBBkExQaU5qMIgRmZpYlPmInYEBTY4VyPDNzyvJyAQJoUkyAxkuiZWZ4phSIIZHfmlRJi%2BQAQC9cBrq&action=log&mode=test\"",
	SameTest -> Function[{expected, actual},
		SameQ @@ (KeyDrop["timestamp"]@Merge[URLParse[#]["Query"], Identity] & /@ {expected, actual})
	],
	TestID -> "ChooseMeal-adjust-servings-redirect"
];

VerificationTest[
	mealLogCountBefore = Length @ Normal @ Databin[bin, Today],
	_Integer,
	SameTest -> MatchQ,
	TestID -> "Meal-log-counts-before-ServingSizeEntry-logging-submit"
];

VerificationTest[
	URLBuild[
		FileNameJoin[{root, "ServingSizeEntry"}],
		{
			"meal" -> "OvernightOats",
			"servingCount" -> 1,
			"description" -> "Overnight Oats",
			"mealType" -> "Breakfast",
			"action" -> "log",
			"foodToAmount" -> Compress[
				<|
				"Oats" -> 1,
				"Milk" -> 1,
				"GreekYogurt" -> 1,
				"FlaxSeed" -> 1,
				"Honey" -> 1,
				"VanillaExtract" -> 1
				|>
			],
			"mode" -> "submit",
			"timestamp" -> Compress[Now]
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{"Home Page - Wolfram Cloud"},
	TestID -> "ServingSizeEntry-logging-submit"
];

VerificationTest[
	Length @ Normal @ Databin[bin, Today] - mealLogCountBefore,
	1,
	TestID -> "Meal-log-counts-difference-after-ServingSizeEntry-logging-submit"
];

VerificationTest[
	Utilities`GenerateData`LogMeal[root, {Entity["MyFood", "Oats"]}, 1, "Breakfast", Now],
	bin,
	TestID -> "LogMeal-Foods"
];

VerificationTest[
	Normal[Databin[bin, -1, {"Meal", "MealType", "TotalCalories"}]],
	{<|"Meal" -> {Entity["MyFood", "Oats"]}, "MealType" -> "Breakfast", "TotalCalories" -> Quantity[150., "LargeCalories"]|>},
	TestID -> "LogMeal-Foods-contents"
];

VerificationTest[
	mealLogCountBefore = Length @ Normal @ Databin[bin, Today],
	_Integer,
	SameTest -> MatchQ,
	TestID -> "Meal-log-counts-before-ChooseFood-simple-submit"
];

VerificationTest[
	URLBuild[
		FileNameJoin[{root, "ChooseFood"}],
		{
			"mealType" -> "Breakfast",
			"food" -> "Oats",
			"editQ" -> False,
			"mode" -> "submit"
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{"Home Page - Wolfram Cloud"},
	TestID -> "ChooseFood-simple-submit"
];

VerificationTest[
	Length @ Normal @ Databin[bin, Today] - mealLogCountBefore,
	1,
	TestID -> "Meal-log-counts-after-ChooseFood-simple-submit"
];

VerificationTest[
	mealLogCountBefore = Length @ Normal @ Databin[bin, Today],
	_Integer,
	SameTest -> MatchQ,
	TestID -> "Meal-log-counts-before-ChooseFood-edit-submit"
];

VerificationTest[
	URLBuild[
		FileNameJoin[{root, "ChooseFood"}],
		{
			"mealType" -> "Breakfast",
			"food" -> {"Milk", "Oats", "Bananas"},
			"editQ" -> True,
			"mode" -> "submit"
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{"Home Page - Wolfram Cloud"},
	TestID -> "ChooseFood-edit-submit"
];

VerificationTest[
	Length @ Normal @ Databin[bin, Today] - mealLogCountBefore,
	1,
	TestID -> "Meal-log-counts-after-ChooseFood-edit-submit"
];

VerificationTest[
	latestUUIDBefore = First[Get[Databin[bin, -1]]]["UUID"],
	_String,
	SameTest -> MatchQ,
	TestID -> "Bin-UUID-before-RemoveLogEntry"
];

VerificationTest[
	URLBuild[
		FileNameJoin[{root, "RemoveLogEntry"}],
		{
			"bin" -> bin["ShortID"],
			"uuid" -> latestUUIDBefore
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{_String},
	SameTest -> MatchQ,
	TestID -> "RemoveLogEntry-API"
];

VerificationTest[
	First[Get[Databin[bin, -1]]]["UUID"],
	latestUUIDBefore,
	SameTest -> UnsameQ,
	TestID -> "Bin-UUID-after-RemoveLogEntry"
];


VerificationTest[
	URLBuild[
		FileNameJoin[{root, "RemoveEntity"}],
		{
			"type" -> "MyFood",
			"entity" -> "PeanutButter"
		}
	] // URLFetch // StringCases[#, Shortest["<title>" ~~ title__ ~~ "</title>"] :> StringTrim[title]]&,
	{_String},
	SameTest -> MatchQ,
	TestID -> "RemoveEntity-API"
];

VerificationTest[
	Pause[1];
	LoadEntityStore[root, "MyFood"];
	Sort @ EntityValue["MyFood", "CanonicalName"],
	Sort @ {"Egg", "WhiteBread", "Jelly", "Milk", "Oats", "GreekYogurt", "FlaxSeed", "Honey", "VanillaExtract", "Bananas", "Salsa", "Apples,Raw,GrannySmith,WithSkin"},
	TestID -> "RemoveEntity-entities-after"
];

VerificationTest[
	DeleteDirectory[root, DeleteContents -> True];
	FileExistsQ[root],
	False,
	TestID -> "Temporary-Root-CloudObject-should-be-removed"
];


EndTestSection[];