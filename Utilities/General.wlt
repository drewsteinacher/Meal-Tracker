BeginTestSection["Utilities`General"];

VerificationTest[
	Get["General.wl"],
	Null,
	TestID -> "Get-Package"
];

VerificationTest[
	QuantityToString[Quantity[5.1234, "LargeCalories"]],
	"5.1234 Cal",
	TestID -> "QuantityToString-calories"
];

VerificationTest[
	QuantityToString[Quantity[5.1234, "Grams"]],
	"5.1234 g",
	TestID -> "QuantityToString-grams"
];

VerificationTest[
	QuantityToString[Quantity[5.1234, "Milligrams"]],
	"5.1234 mg",
	TestID -> "QuantityToString-milligrams"
];

VerificationTest[
	QuantityToString[Quantity[5.1234, "Micrograms"]],
	"5.1234 \[Micro]g",
	TestID -> "QuantityToString-micrograms"
];

VerificationTest[
	QuantityToString[Quantity[5.1234, "Kilograms"]],
	"5.1234 kg",
	TestID -> "QuantityToString-kilograms"
];

VerificationTest[
	QuantityToString[Quantity[1/4, "Tablespoons"]],
	"0.25 tbsp",
	TestID -> "QuantityToString-rational"
];

VerificationTest[
	QuantityToString[1],
	"1.",
	TestID -> "QuantityToString-number"
];

VerificationTest[
	QuantityToString[1/4],
	"0.25",
	TestID -> "QuantityToString-Rational-number"
];

VerificationTest[
	GetMealTypeFromTime[DateObject[{2018, 3, 8, 9, 30, 8.5974213}, "Instant", "Gregorian", -6.]],
	"Breakfast",
	TestID -> "GetMealTypeFromTime-Breakfast"
];

VerificationTest[
	GetMealTypeFromTime[DateObject[{2018, 3, 8, 11, 30, 8.5974213}, "Instant", "Gregorian", -6.]],
	"Lunch",
	TestID -> "GetMealTypeFromTime-Lunch"
];

VerificationTest[
	GetMealTypeFromTime[DateObject[{2018, 3, 8, 17, 30, 8.5974213}, "Instant", "Gregorian", -6.]],
	"Dinner",
	TestID -> "GetMealTypeFromTime-Dinner"
];

VerificationTest[
	GetMealTypeFromTime[DateObject[{2018, 3, 8, 22, 30, 8.5974213}, "Instant", "Gregorian", -6.]],
	"Snack",
	TestID -> "GetMealTypeFromTime-Snack"
];

VerificationTest[
	GetMealTypeFromTime[],
	_String,
	SameTest -> MatchQ,
	TestID -> "GetMealTypeFromTime-Default"
];

VerificationTest[
	FromCamelCase["VitaminC"],
	"Vitamin C",
	TestID -> "FromCamelCase-VitaminC"
];

VerificationTest[
	FromCamelCase["ThisIsATest"],
	"This Is A Test",
	TestID -> "FromCamelCase-Sentence"
];

VerificationTest[
	AssociationToDateObject[<|"Year" -> 2018, "Month" -> 4, "Day" -> 10, "Hour" -> 13, "Minute" -> 7, "Second" -> 56|>],
	DateObject[{2018, 4, 10}, TimeObject[{13, 7, 56}]],
	TestID -> "AssociationToDateObject"
];

VerificationTest[
	TimestampString[DateObject[{2018, 3, 20, 14, 22, 16.0803520}, "Instant", "Gregorian", $TimeZone]],
	"2018-03-20 14:22:16",
	TestID -> "TimestampString-basic"
];

VerificationTest[
	TimestampString[<|"Year" -> 2018, "Month" -> 4, "Day" -> 10, "Hour" -> 13, "Minute" -> 7, "Second" -> 56|>],
	"2018-04-10 13:07:56",
	TestID -> "TimestampString-Association"
];

VerificationTest[
	ParseQuantity["1 item"],
	Quantity[1, "Items"],
	TestID -> "ParseQuantity-1"
];

VerificationTest[
	ParseQuantity["1 items"],
	Quantity[1, "Items"],
	TestID -> "ParseQuantity-2"
];

VerificationTest[
	ParseQuantity["4.56g"],
	Quantity[4.56, "Grams"],
	TestID -> "ParseQuantity-3"
];

VerificationTest[
	ParseQuantity["4.56mg"],
	Quantity[4.56, "Milligrams"],
	TestID -> "ParseQuantity-4"
];

VerificationTest[
	ParseQuantity["4.56cup"],
	Quantity[4.56, "Cups"],
	TestID -> "ParseQuantity-5"
];

VerificationTest[
	ParseQuantity["1.tsp"],
	Quantity[1., "Teaspoons"],
	TestID -> "ParseQuantity-6"
];

VerificationTest[
	ParseQuantity["1/2tbsp"],
	Quantity[1/2, "Tablespoons"],
	TestID -> "ParseQuantity-7"
];

VerificationTest[
	ParseQuantity["1/4cup"],
	Quantity[1/4, "Cups"],
	TestID -> "ParseQuantity-8"
];


VerificationTest[
	SafeInterpreter["ComputedDateTime"] @ TimestampString[DateObject[{2018, 3, 20, 14, 22, 16.0803520}, "Instant", "Gregorian", $TimeZone]],
	DateObject[{2018, 3, 20, 14, 22, 16}, "Instant", "Gregorian", $TimeZone],
	TestID -> "FromCamelCase-Interpreter-support"
];

VerificationTest[
	Internal`ClearEntityValueCache["Food"];
	SafeInterpreter["Food"]["vanilla extract"],
	Entity["Food", {EntityProperty["Food", "FoodType"] -> ContainsExactly[{Entity["FoodType", "VanillaExtract"]}], EntityProperty["Food", "AddedFoodTypes"] -> ContainsExactly[{}]}],
	TestID -> "SafeInterpreter-single"
];

VerificationTest[
	SafeInterpreter["Food"][{"vanilla extract", "peanut butter"}],
	{Entity["Food", {EntityProperty["Food", "FoodType"] -> ContainsExactly[{Entity["FoodType", "VanillaExtract"]}], EntityProperty["Food", "AddedFoodTypes"] -> ContainsExactly[{}]}], Entity["Food", {EntityProperty["Food", "FoodType"] -> ContainsExactly[{Entity["FoodType", "PeanutButter"]}], EntityProperty["Food", "AddedFoodTypes"] -> ContainsExactly[{}]}]},
	TestID -> "SafeInterpreter-multiple"
];

VerificationTest[
	Internal`ClearEntityValueCache["Food"];
	Cases[SafeInterpreter["Food"][{"white bread", "peanut butter", "jelly", "milk", "oats", "greek yogurt", "flax seed", "honey", "vanilla extract"}], _Failure],
	{},
	TestID -> "SafeInterpreter-multiple-no-failures"
];

VerificationTest[
	Normal @ TimeSeriesAccumulate[es = EventSeries[{{DateObject[{2018, 4, 5, 8, 30, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[57.965, "LargeCalories"]}, {DateObject[{2018, 4, 5, 9, 0, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[15.93, "LargeCalories"]}}]],
	{{DateObject[{2018, 4, 5, 6, 30, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[0, "LargeCalories"]}, {DateObject[{2018, 4, 5, 8, 30, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[57.965, "LargeCalories"]}, {DateObject[{2018, 4, 5, 9, 0, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[73.895, "LargeCalories"]}},
	TestID -> "TimeSeriesAccumulate-default-argument"
];

VerificationTest[
	Normal @ TimeSeriesAccumulate[es, Quantity[5, "Hours"]],
	{{DateObject[{2018, 4, 5, 3, 30, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[0, "LargeCalories"]}, {DateObject[{2018, 4, 5, 8, 30, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[57.965, "LargeCalories"]}, {DateObject[{2018, 4, 5, 9, 0, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[73.895, "LargeCalories"]}},
	TestID -> "TimeSeriesAccumulate-Quantity"
];

VerificationTest[
	Normal @ TimeSeriesAccumulate[es, es["FirstDate"] - Quantity[1, "Hours"]],
	{{DateObject[{2018, 4, 5, 7, 30, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[0, "LargeCalories"]}, {DateObject[{2018, 4, 5, 8, 30, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[57.965, "LargeCalories"]}, {DateObject[{2018, 4, 5, 9, 0, 0.}, "Instant", "Gregorian", $TimeZone], Quantity[73.895, "LargeCalories"]}},
	TestID -> "TimeSeriesAccumulate-DateObject"
];

VerificationTest[
	IntegerToOrdinalString[1],
	"1st",
	TestID -> "IntegerToOrdinalString-first"
];

VerificationTest[
	IntegerToOrdinalString[2],
	"2nd",
	TestID -> "IntegerToOrdinalString-second"
];

VerificationTest[
	IntegerToOrdinalString[3],
	"3rd",
	TestID -> "IntegerToOrdinalString-third"
];

VerificationTest[
	IntegerToOrdinalString[4],
	"4th",
	TestID -> "IntegerToOrdinalString-fourth"
];

VerificationTest[
	IntegerToOrdinalString[11],
	"11th",
	TestID -> "IntegerToOrdinalString-eleventh"
];

VerificationTest[
	IntegerToOrdinalString[12],
	"12th",
	TestID -> "IntegerToOrdinalString-twelfth"
];

VerificationTest[
	IntegerToOrdinalString[13],
	"13th",
	TestID -> "IntegerToOrdinalString-thirteenth"
];

VerificationTest[
	IntegerToOrdinalString[31],
	"31st",
	TestID -> "IntegerToOrdinalString-thirty-first"
];

VerificationTest[
	ValidGTINQ["025000056017"],
	TestID -> "ValidGTINQ-valid"
];

VerificationTest[
	ValidGTINQ["01234567"],
	False,
	TestID -> "ValidGTINQ-invalid"
];

VerificationTest[
	GetGTINCheckDigit["02500005601"],
	"7",
	TestID -> "GetGTINCheckDigit-simple"
];

VerificationTest[
	getCloudPlaintext = StringReplace[
		ImportString[
			"<html>" <> ExportString[AddFoodHelpLinks[CloudObject["DummyDirectory"], #], "HTMLFragment"] <> "<\\html>",
			"Plaintext"
		],
		WhitespaceCharacter ~~ (punct : "," | ".") :> punct
	]&,
	_Function,
	TestID -> "AddFoodHelpLinks-getCloudPlaintext",
	SameTest -> MatchQ
];

VerificationTest[
	getCloudPlaintext["ScanBarcode"],
	"You can also search, enter a number, or manually enter a food without discovery.",
	TestID -> "AddFoodHelpLinks-plaintext-scanBarcode"
];

VerificationTest[
	getCloudPlaintext["FoodSearch"],
	"You can also enter a number, scan a barcode, or manually enter a food without discovery.",
	TestID -> "AddFoodHelpLinks-plaintext-FoodSearch"
];

VerificationTest[
	getCloudPlaintext["FoodLookup"],
	"You can also search, scan a barcode, or manually enter a food without discovery.",
	TestID -> "AddFoodHelpLinks-plaintext-FoodLookup"
];

VerificationTest[
	getCloudPlaintext["FoodEntry"],
	"You can also search, enter a number, or scan a barcode.",
	TestID -> "AddFoodHelpLinks-plaintext-FoodEntry"
];

EndTestSection[];
