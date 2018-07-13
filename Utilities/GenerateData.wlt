BeginTestSection["Utilities`GenerateData"];

VerificationTest[
	Get["GenerateData.wl"],
	Null,
	TestID -> "Get-package"
];

VerificationTest[
	Internal`InheritedBlock[{DateString},
		Unprotect[DateString];
		DateString["ISODateTime"] := DateString[DateObject[{2017, 10, 30, 15, 53, 15.1312937}, "Instant", "Gregorian", -5.], {"ISODateTime"}];
		Protect[DateString];
		Utilities`GenerateData`Private`makeFoodID["test"]
	],
	"test_2017-10-30_15-53-15.m",
	TestID -> "Make-food-ID"
];

VerificationTest[
	testNutrients = {
		Entity["Nutrient", "TotalCalories"],
		Entity["Nutrient", "Calcium"],
		Entity["Nutrient", "Cholesterol"],
		Entity["Nutrient", "Iron"],
		Entity["Nutrient", "Sodium"],
		Entity["Nutrient", "TotalCarbohydrates"],
		Entity["Nutrient", "TotalFat"],
		Entity["Nutrient", "TotalFiber"],
		Entity["Nutrient", "TotalProtein"],
		Entity["Nutrient", "TotalSaturatedFat"],
		Entity["Nutrient", "VitaminC"]
	},
	{Entity["Nutrient", _String] .. },
	TestID -> "testNutrients",
	SameTest -> MatchQ
];

VerificationTest[
	testInputs = {"white bread", "jelly", "peanut butter"},
	{__String},
	TestID -> "testInputs",
	SameTest -> MatchQ
];

VerificationTest[
	testInterpretations = <|
		"white bread" -> Entity["Food",
			{
				EntityProperty["Food", "FoodTypeGroup"] -> ContainsExactly[{Entity["FoodTypeGroup", "Breads"]}],
				EntityProperty["Food", "Variety"] -> Entity["FoodVariety", "White"]
			}
		],
		"jelly" -> Entity["Food",
			{
				EntityProperty["Food", "FoodType"] -> ContainsExactly[{Entity["FoodType", "Jelly"]}],
				EntityProperty["Food", "AddedFoodTypes"] -> ContainsExactly[{}]
			}
		],
		"peanut butter" -> Entity["Food",
			{
				EntityProperty["Food", "FoodType"] -> ContainsExactly[{Entity["FoodType", "PeanutButter"]}],
				EntityProperty["Food", "AddedFoodTypes"] -> ContainsExactly[{}]
			}
		]
	|>,
	_Association,
	TestID -> "testInterpretations",
	SameTest -> MatchQ
];

VerificationTest[
	Utilities`GenerateData`Private`getServingSizeData[testInterpretations]
	,
	Association[
		Rule["white bread", Quantity[_, "Grams"]],
		Rule["jelly", Quantity[_, "Grams"]],
		Rule["peanut butter", Quantity[_, "Grams"]]
	]
	,
	TestID -> "getServingSizeData-Multiple",
	SameTest -> MatchQ
];

VerificationTest[
	Utilities`GenerateData`Private`getFoodRepresentations[{"garbage"}],
	<|"garbage" -> Missing["NotAvailable"]|>,
	{GenerateData::noparse},
	TestID -> "getFoodRepresentations-failures"
];

VerificationTest[
	Block[{Utilities`GenerateData`Private`getFoodRepresentations},
		Utilities`GenerateData`Private`getFoodRepresentations[_] := testInterpretations;
		Normal @ Utilities`GenerateData`Private`iGenerateData[testInputs, testNutrients]
	],
	{
		Repeated[
			_String -> <|
				"Label" -> _String,
				"Food" -> Entity["Food", _List],
				"ServingSizeString" -> _,
				"ServingSizes" -> {__Quantity},
				"TotalCalories" -> Quantity[_, "LargeCalories"],
				"Calcium" -> Quantity[_, "Milligrams"],
				"Cholesterol" -> Quantity[_, "Milligrams"],
				"Iron" -> Quantity[_, "Milligrams"],
				"Sodium" -> Quantity[_, "Milligrams"],
				"TotalCarbohydrates" -> Quantity[_, "Grams"],
				"TotalFat" -> Quantity[_, "Grams"],
				"TotalFiber" -> Quantity[_, "Grams"],
				"TotalProtein" -> Quantity[_, "Grams"],
				"TotalSaturatedFat" -> Quantity[_, "Grams"],
				"VitaminC" -> Quantity[_, "Milligrams"]
			|>
		]
	}
	,
	TestID -> "generateFoodData-Multiple",
	SameTest -> MatchQ
];


VerificationTest[
	Block[{Utilities`GenerateData`Private`getFoodRepresentations},
		Utilities`GenerateData`Private`getFoodRepresentations[_] := testInterpretations[[ ;; 1]];
		Utilities`GenerateData`Private`iGenerateData[testInputs[[1]], Entity["Nutrient", #]& /@ {"TotalCalories", "TotalFat", "TotalCarbohydrates", "TotalProtein"}, Quantity[100, "Grams"]]
	],
	_Association,
	SameTest -> MatchQ,
	TestID -> "iGenerateData-1"
];

VerificationTest[
	With[{servingSizeData = Quantity[100, "Grams"]& /@ testInterpretations},
		Normal @ Utilities`GenerateData`Private`getNutritionData[testInterpretations, servingSizeData, testNutrients]
	],
	{Rule[_String, _Association] ..},
	SameTest -> MatchQ,
	TestID -> "getNutritionData-success"
];

VerificationTest[
	Normal @ Utilities`GenerateData`Private`getNutritionData[<|"garbage" -> Missing["NotAvailable"]|>, <|"garbage" -> Quantity[100, "Grams"]|>, testNutrients],
	{Rule[_String, _Association] ..},
	SameTest -> MatchQ,
	TestID -> "getNutritionData-failures"
];

VerificationTest[
	Utilities`GenerateData`Private`getNutritionData[
		<|
			"refried beans" -> Entity["Food", {"FoodType" -> ContainsExactly[{"Bean"}], "AddedFoodTypes" -> ContainsExactly[{}], "Preparation" -> "Refried"}],
			"garbage" -> Missing["NotAvailable"]
		|>,
		<|"refried beans" -> Quantity[100, "Grams"], "garbage" -> Quantity[100, "Grams"]|>,
		testNutrients
	],
	<|
		"refried beans" -> <|
			"TotalCalories" -> _Quantity,
			"Calcium" -> _Quantity,
			"Cholesterol" -> _Quantity,
			"Iron" -> _Quantity,
			"Sodium" -> _Quantity,
			"TotalCarbohydrates" -> _Quantity,
			"TotalFat" -> _Quantity,
			"TotalFiber" -> _Quantity,
			"TotalProtein" -> _Quantity,
			"TotalSaturatedFat" -> _Quantity,
			"VitaminC" -> _Quantity
		|>,
		"garbage" -> <|
			"TotalCalories" -> Missing["NotAvailable"],
			"Calcium" -> Missing["NotAvailable"],
			"Cholesterol" -> Missing["NotAvailable"],
			"Iron" -> Missing["NotAvailable"],
			"Sodium" -> Missing["NotAvailable"],
			"TotalCarbohydrates" -> Missing["NotAvailable"],
			"TotalFat" -> Missing["NotAvailable"],
			"TotalFiber" -> Missing["NotAvailable"],
			"TotalProtein" -> Missing["NotAvailable"],
			"TotalSaturatedFat" -> Missing["NotAvailable"],
			"VitaminC" -> Missing["NotAvailable"]
		|>
	|>,
	SameTest -> MatchQ,
	TestID -> "getNutritionData-both"
];


VerificationTest[
	Utilities`GenerateData`Private`iGenerateData["garbage", Entity["Nutrient", #]& /@ {"TotalCalories", "TotalFat", "TotalCarbohydrates", "TotalProtein"}, Quantity[100, "Grams"]],
	_Association,
	{GenerateData::noparse},
	SameTest -> MatchQ,
	TestID -> "iGenerateData-garbage"
];

VerificationTest[
	Utilities`GenerateData`Private`getServingSizeData[
		<|
			"refried beans" -> Entity["Food", {"FoodType" -> ContainsExactly[{"Bean"}]}],
			"garbage" -> Missing["NotAvailable"]
		|>
	] // Normal,
	{Rule[_String, _Quantity] ..},
	SameTest -> MatchQ,
	TestID -> "getServingSizeData-both"
];

VerificationTest[
	Utilities`GenerateData`Private`validFoodEntityQ[testInterpretations[[1]]],
	True,
	TestID -> "validFoodEntityQ-True"
];

VerificationTest[
	Utilities`GenerateData`Private`validFoodEntityQ[Missing["NotAvailable"]],
	False,
	TestID -> "validFoodEntityQ-False"
];


EndTestSection[];
