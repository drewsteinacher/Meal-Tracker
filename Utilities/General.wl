ClearAll["Utilities`General`*"];
ClearAll["Utilities`General`*`*"];

BeginPackage["Utilities`General`"];

GetConfiguration::usage = "GetConfiguration[root] returns an Association of configuration information
GetConfiguration[root, key] returns the value associated with the given key";
SetConfiguration::usage = "SetConfiguration[root, configuration_Association] replaces the entire configuration with the given Association";

QuantityToString::usage = "QuantityToString[q_Quantity] converts the given quantity to a simple string";
FromCamelCase::usage = "FromCamelCase[s_String] converts a CamelCase string s to a string with spaces, leaving the capitalized words alone.";
ToCamelCase::usage = "ToCamelCase[_String] converts the given string to (Upper) CamelCase";

TimestampString::usage = "TimestampString[time_DateObject:Now] produces an Interpreter-friendly string to be used in forms";
AssociationToDateObject::usage = "AssociationToDateObject[a_Association] creates a DateObject based on the keys in the given association";

$MealTypes = "A list of meal types";
GetMealTypeFromTime::usage = "GetMealTypeFromTime[date_DateObject: Now] returns the meal type for the given time";

GridFormat::usage = "GridFormat[{__Association}] formats the given associations in a nice, easy to read grid with column headers.";

AddFoodHelpLinks::usage = "AddFoodHelpLinks[root] gives a Row object with a nice message and links to food entry pages.";
AddMealHelpLinks::usage = "AddMealHelpLinks[root] gives a Row object with a nice message and links to the meal entry page.";

NewTabHyperlink::usage = "NewTabHyperlink[label, url] gives a hyperlink that will open in a new tab.";

DateToString::usage = "DateToString[date_, format: \"ISODateTime\"] behaves like DateString, but handles Missing better";

ServingSizeHelpMessage::usage = "ServingSizeHelpMessage[] gives a message on how to enter equivalent serving sizes (e.g. \"1 tbsp; 21 g\")";
ServingAmountHelpMessage::usage = "ServingAmountHelpMessage[] gives a message on how to enter serving size amounts (e.g. \"1.5\" or \"4 tbsp\")";

FoodServingSizeHyperlinkGrid::usage = "FoodServingSizeHyperlinkGrid[root][_EntityClass]";

GetServingFactorFromAmountQualifier::usage = "GetServingFactorFromAmountQualifier[entity_, amount_]";

ParseQuantity::usage = "ParseQuantity[s_String] uses a list of shortcuts to improve performance of interpreting quantities";
SafeInterpreter::usage = "SafeInterpreter[type][string] works around inconsistent behavior of Interpreter";

TimeSeriesAccumulate::usage = "TimeSeriesAccumulate[timeSeries, leadTime: Quantity[2, \"Hours\"]] accumulates values";

DateInterpreterSpec::usage = "DateInterpreterSpec[date : _DateObject : Now] gives a CompoundElement for simple input of dates in forms";
HourInterpreterSpec::usage = "HourInterpreterSpec is an Interpreter-friendly spec used to enter hours in a simple way.";
IntegerToOrdinalString::usage = "IntegerToOrdinalString[n] converts 1 -> \"1st\", 2 -> \"2nd\", 3 -> \"3rd\", etc...";

DateObjectToAssociation::usage = "DateObjectToAssociation[_DateObject] converts the DateObject into an Association that matches the format from DateInterpreterSpec";

ValidGTINQ::usage = "ValidGTINQ[_String] returns True if the given GTIN string (e.g. a UPC) has a valid check digit";
GetGTINCheckDigit::usage = "GetGTINCheckDigit[_String] returns the proper check digit for a given GTIN string without a check digit";

Begin["`Private`"];

$MealTypes = {"Breakfast", "Lunch", "Dinner", "Snack"};

GetMealTypeFromTime[date_DateObject: Now] := With[
	{
		hour = DateValue[date, "Hour"]
	},
	Which[
		3  <  hour < 11,    "Breakfast",
		11 <= hour < 15,    "Lunch",
		15 <= hour < 20,    "Dinner",
		True,               "Snack"
	]
];

GetConfiguration[root_CloudObject] := Replace[Get[FileNameJoin[{root, "Configuration.m"}]], Except[_Association] :> $Failed];
GetConfiguration[root_CloudObject, key_String] := With[
	{
		configuration = GetConfiguration[root]
	},
	Lookup[configuration, key]
];

SetConfiguration[root_CloudObject, configuration_Association] := Put[configuration, FileNameJoin[{root, "Configuration.m"}]];
SetConfiguration[root_CloudObject, key_String, value_] := With[
	{
		configuration = GetConfiguration[root]
	},
	Put[Append[configuration, key -> value], FileNameJoin[{root, "Configuration.m"}]]
];

QuantityToString[q_Quantity] := StringReplace[
	ToString[N[q]],
	{
		"dietary Calories" -> "Cal",
		"milligrams" -> "mg",
		"micrograms" -> "\[Micro]g",
		"kilograms" -> "kg",
		"grams" -> "g",
		"tablespoons" -> "tbsp",
		"teaspoons" -> "tsp"
	}
];
QuantityToString[x: _Rational | _?NumberQ] := ToString[N[x]];
QuantityToString[_] := " ";

FromCamelCase[s_String] := StringTrim[StringReplace[s, cap:(Alternatives @@ CharacterRange["A", "Z"]) :> " " <> cap]];
ToCamelCase[s_String] := StringJoin[Capitalize /@ StringSplit[s]];

TimestampString[time_DateObject: Now] := StringReplace[DateString[time, "ISODateTime"], {"T" -> " "}];
AssociationToDateObject[a_Association] := DateObject[
	Lookup[a, #, DateValue[#]]& /@ {"Year", "Month", "Day"},
	TimeObject[Lookup[a, #, DateValue[#]]& /@ {"Hour", "Minute", "Second"}]
];
TimestampString[a_Association] := TimestampString @ AssociationToDateObject @ a;

GridFormat[data: {__Association}] := Module[
	{headers, values},
	headers = Keys[First @ data];
	values = Values[KeyTake[data, headers]];
	PrependTo[values, headers];
	Grid[values, Frame -> All, Background -> {Automatic, {Red}}]
];

AddFoodHelpLinks[root_CloudObject, "MealEntryPage" | "ChooseFoodPage"] := Row[
	{
		"Missing a food? Add one by",
		Spacer[1],
		Hyperlink["searching", FileNameJoin[{root, "FoodSearch"}]],
		",",
		Spacer[2],
		Hyperlink["entering a code", FileNameJoin[{root, "FoodLookup"}]],
		",",
		Spacer[2],
		Hyperlink["scanning a barcode", FileNameJoin[{root, "ScanBarcode"}]],
		", or ",
		Spacer[1],
		Hyperlink["adding it manually", FileNameJoin[{root, "FoodEntry"}]],
		"."
	}
];

AddFoodHelpLinks[root_CloudObject, page_String] := With[
	{
		choices = Flatten @ {
			If[page =!= "FoodSearch",
				{Hyperlink["search", FileNameJoin[{root, "FoodSearch"}]]},
				{}
			],
			If[page =!= "FoodLookup",
				{Hyperlink["enter a number", FileNameJoin[{root, "FoodLookup"}]]},
				{}
			],
			If[page =!= "ScanBarcode",
				{Hyperlink["scan a barcode", FileNameJoin[{root, "ScanBarcode"}]]},
				{}
			],
			If[page =!= "FoodEntry",
				{Hyperlink["manually enter a food without discovery", FileNameJoin[{root, "FoodEntry"}]]},
				{}
			]
		}
	},
	Row[
		Flatten @ {
			{"You can also", Spacer[1]},
			MapIndexed[
				{
					#1,
					Switch[#2,
						{Length[choices] - 1}, {",", Spacer[1], "or", Spacer[1]},
						{Length[choices]}, {},
						_, {",", Spacer[1]}
					]
				}&,
				choices
			],
			{"."}
		}
	]
];

AddMealHelpLinks[root_CloudObject] := Row[
	{
		"Missing a meal?",
		Spacer[1],
		Hyperlink["Click here to add one", FileNameJoin[{root, "MealEntry"}]],
		"."
	}
];

NewTabHyperlink[label_String, url_String] := EmbeddedHTML[StringTemplate["<a href=\"``\" target=\"_blank\">``</a>"][url, label]];

DateToString[date_DateObject, format: "ISODateTime"] := DateString[date, format];
DateToString[__] := "";

ServingSizeHelpMessage[] := Column[
	{
		"Enter all equivalent measures for the given nutrition information, separated by semicolons.",
		"E.g. \"1/8 tsp; 0.6g\" or \"1 oz; 28g; 1/8 package\" or \"1 cup; 240 mL\""
	}
];

ServingAmountHelpMessage[] := Column[
	{
		"Enter the servings for each food.",
		"Use numbers to multiply the default serving sizes listed (e.g. \"0.5\", \"2\", \"1.3\").",
		"Alternatively, enter a specific (compatible) amount (e.g. \"1.33 cups\", \"0.5 slice\", \"3 tbsp\")."
	}
];

foodServingSizeHyperlinkGridFailureString = "No foods were found.";

Options[FoodServingSizeHyperlinkGrid] = {
	"ImplicitEntityLabel" -> None,
	"IncludeImplicitEntity" -> False,
	"MaxNumber" -> Infinity,
	"ResubmitPage" -> "FoodSearch"
};
FoodServingSizeHyperlinkGrid[root_][e_Entity, rest___] := FoodServingSizeHyperlinkGrid[root][EntityClass @@ e, rest];
FoodServingSizeHyperlinkGrid[root_CloudObject][implicitEntity: EntityClass[_, {__Rule}], opts:OptionsPattern[]] := Module[
	{data0, data, implicitEntityLabel, implicitEntityQ, properties, resubmitPage},
	
	implicitEntityLabel = OptionValue[FoodServingSizeHyperlinkGrid, {opts}, "ImplicitEntityLabel"];
	implicitEntityQ = TrueQ @ OptionValue[FoodServingSizeHyperlinkGrid, {opts}, "IncludeImplicitEntity"];
	resubmitPage = OptionValue[FoodServingSizeHyperlinkGrid, {opts}, "ResubmitPage"];
	
	properties = {"Name", "ConsumptionMasses"};
	
	data0 = EntityValue[implicitEntity, properties, "EntityPropertyAssociation"];
	
	
	
	If[MatchQ[data0, _Association] && Length[data0] > 0,
		data = KeyValueMap[
			Function[{entity, propAssociation},
				MapAt[servingSizeGrid[root, entity["Name"], entity, resubmitPage], propAssociation, {Key["ConsumptionMasses"]}]
			],
			data0
		];
		If[implicitEntityQ,
			PrependTo[data,
				<|
					"Name" -> implicitEntityLabel,
					"ConsumptionMasses" -> servingSizeGrid[root, implicitEntityLabel, Entity @@ implicitEntity, resubmitPage][
						consumptionMassesAggregationFunction[DeleteMissing @ Values @ data0[[All, "ConsumptionMasses"]]]
					]
				|>
			];
		];
		data = KeyMap[Replace["ConsumptionMasses" -> "Serving Sizes"]] /@ data;
		GridFormat[data]
		,
		foodServingSizeHyperlinkGridFailureString
	]
];

FoodServingSizeHyperlinkGrid[___][___] = foodServingSizeHyperlinkGridFailureString;

$DefaultServingSizeAssociation = <|Quantity[1, "Servings"] -> Quantity[100, "Grams"]|>;
servingSizeGrid[root_CloudObject, label_String, entity_, resubmitPage_String][consumptionMasses_Association] := Module[{},
	Column[
		Join[
			KeyValueMap[
				customServingSizeHyperlink[root, label, entity, resubmitPage],
				If[Length[consumptionMasses] > 0,
					consumptionMasses[[ ;; 1]],
					$DefaultServingSizeAssociation
				]
			],
			KeyValueMap[
				nutritionServingSizeHyperlink[root, label, entity, resubmitPage],
				consumptionMasses
			]
		]
	]
];

servingSizeGrid[root_CloudObject, label_String, entity_, resubmitPage_String][_] := servingSizeGrid[root, label, entity, resubmitPage][
	$DefaultServingSizeAssociation
];

customServingSizeHyperlink[args1___][args2___] := iServingSizeHyperlink[args1]["ServingSizeMultiplication", "Custom Serving Size", args2];
nutritionServingSizeHyperlink[args1___][size_, mass_] := With[
	{
		servingSizeStrings = QuantityToString /@ {size, mass}
	},
	iServingSizeHyperlink[args1]["NutritionEntry", StringTemplate["`` (``)"] @@ servingSizeStrings, size, mass]
];

iServingSizeHyperlink[root_CloudObject, label_String, entity_, resubmitPage_String][page_String, linkLabel_String, size_, mass_] := With[
	{
		servingSizeStrings = QuantityToString /@ {size, mass}
	},
	Hyperlink[
		linkLabel,
		URLBuild[
			FileNameJoin[{root, page}],
			{
				"description" -> label,
				"entity" -> Compress[entity],
				"servingSizeString" -> StringRiffle[servingSizeStrings, "; "],
				"servingSizeMass" -> Compress[mass],
				"action" -> "new",
				"resubmitPage" -> resubmitPage
			}
		]
	]
];

consumptionMassesAggregationFunction[consumptionMasses_] := Module[
	{groupedByServingUnit, normalizedByServingUnit},
	groupedByServingUnit = GroupBy[Flatten[Normal /@ consumptionMasses], QuantityUnit[First[#]] &];
	groupedByServingUnit = Reverse @ SortBy[groupedByServingUnit, Length];
	normalizedByServingUnit = Map[normalizeServingSize] /@ groupedByServingUnit;
	normalizedByServingUnit // Map[Median] // KeyMap[Quantity]
];

normalizeServingSize = Replace[
	Rule[
		Quantity[unitCount_?NumberQ, unit_],
		Quantity[gramsCount_?NumberQ, gramsUnit_]
	] :> Quantity[gramsCount / unitCount, gramsUnit]
];

GetServingFactorFromAmountQualifier[_, n_?NumberQ] := n;
GetServingFactorFromAmountQualifier[_, Quantity[n_?NumberQ, "Servings"]] := n;
GetServingFactorFromAmountQualifier[e_Entity, q_Quantity] :=
	Quiet[
		Check[
			q / SelectFirst[e["ServingSizes"], CompatibleUnitQ[#, q]&],
			$Failed
		]
	];

SafeInterpreter[type_String][s:{__String}] := SafeInterpreter[type] /@ s;
SafeInterpreter[type_String][s_String] := Module[
	{result},
	Do[
		result = Interpreter[type][s];
		If[MatchQ[result, _Failure],
			Internal`ClearEntityValueCache[type],
			Break[]
		],
		{3}
	];
	result
];

$CommonUnitStringToUnit = Association @ Flatten[
	{
		Thread[{"g", "gram", "grams"} -> "Grams"],
		Thread[{"mg", "milligram", "milligrams"} -> "Milligrams"],
		Thread[{"item", "count", "items", "counts", "ct"} -> "Items"],
		Thread[{"slice", "slices"} -> "Slices"],
		Thread[{"cup", "cups"} -> "Cups"],
		Thread[{"tsp", "teaspoon", "teaspoon"} -> "Teaspoons"],
		Thread[{"tbsp", "Tbsp", "TBSP", "tablespoon", "tablespoons"} -> "Tablespoons"],
		Thread[{"Cal", "cal", "calories", "Calories"} -> "LargeCalories"],
		Thread[{"oz", "ounce", "ounces"} -> "Ounces"]
	}
];

ParseQuantity[s: {__String}] := ParseQuantity /@ s;
ParseQuantity[s_String] := With[
	{splitStrings = StringSplit[StringReplace[s, ns : NumberString ~~ lc : LetterCharacter :> ns <> " " <> lc]]},
	iParseQuantity @@ StringTrim[splitStrings]
];

iParseQuantity[
	number_String /; StringMatchQ[number, NumberString | (NumberString ~~ "/" ~~ NumberString)],
	unit_ /; KeyMemberQ[$CommonUnitStringToUnit, unit]
	] := Quantity[ToExpression[number], $CommonUnitStringToUnit[unit]];

iParseQuantity[s___String] := SafeInterpreter["Quantity"][StringRiffle[s]];

TimeSeriesAccumulate[td_TemporalData, leadTime_Quantity: Quantity[2, "Hours"]] := TimeSeriesAccumulate[td, td["FirstDate"] - leadTime];
TimeSeriesAccumulate[td_TemporalData, leadTime_DateObject] := iTimeSeriesAccumulate[td, leadTime];

iTimeSeriesAccumulate[td_TemporalData, leadTime_DateObject] := iTimeSeriesAccumulate[td, leadTime, Replace[td["FirstValue"], {Quantity[_, unit_] :> Quantity[0, unit], _ -> 0}]];
iTimeSeriesAccumulate[td_TemporalData, leadTime_DateObject, startValue: _?NumberQ | _Quantity] := Accumulate[TimeSeriesInsert[td, List @ {leadTime, startValue}]];
iTimeSeriesAccumulate[___] := $Failed;

Options[DateInterpreterSpec] = {
	"AutoSubmitting" -> {"Hour"}
};
DateInterpreterSpec[date : _DateObject : Now, OptionsPattern[]] := With[
	{
		autoSubmittingFields = Replace[
			OptionValue["AutoSubmitting"],
			{
				s_String :> {s},
				Except[_List] -> {}
			}
		]
	},
	CompoundElement[
		{
			"Year" -> <|
				"Interpreter" :> yearInterpreterSpec,
				"Input" :> DateValue[date, "Year"],
				"Default" :> DateValue[date, "Year"],
				"AutoSubmitting" -> MemberQ[autoSubmittingFields, "Year"]
			|>,
			"Month" -> <|
				"Interpreter" :> monthInterpreterSpec,
				"Input" :> DateValue[date, "Month"],
				"Default" :> DateValue[date, "Month"],
				"AutoSubmitting" -> MemberQ[autoSubmittingFields, "Month"]
			|>,
			"Day" -> <|
				"Interpreter" -> dayInterpreterSpec,
				"Input" :> DateValue[date, "Day"],
				"Default" :> DateValue[date, "Day"],
				"AutoSubmitting" -> MemberQ[autoSubmittingFields, "Day"]
			|>,
			"Hour" -> <|
				"Interpreter" -> HourInterpreterSpec,
				"Control" -> PopupMenu,
				"Input" :> DateValue[date, "Hour"],
				"Default" :> DateValue[date, "Hour"],
				"AutoSubmitting" -> MemberQ[autoSubmittingFields, "Hour"]
			|>
		}
	]
];


yearInterpreterSpec := Rule[ToString[#, InputForm], #] & /@ (DateValue["Year"] + {-1, 0, 1});

monthInterpreterSpec = Map[
	Rule[DateString[DateObject[{DateValue["Year"], #}], "MonthNameShort"], #] &,
	Range[1, 12]
];

dayInterpreterSpec = Rule[IntegerToOrdinalString[#], #]& /@ Range[1, 31];
IntegerToOrdinalString[n_Integer] := With[
	{
		suffix = Which[
			MatchQ[Mod[n, 100], 11 | 12 | 13],  "th",
			Mod[n, 10] === 1,   "st",
			Mod[n, 10] === 2,   "nd",
			Mod[n, 10] === 3,   "rd",
			True,               "th"
		]
	},
	ToString[n] <> suffix
];

HourInterpreterSpec = Map[
	Rule[StringTemplate["`` ``"][Replace[Mod[#, 12], 0 -> 12], If[# > 11, "PM", "AM"]], #]&,
	RotateLeft @ Range[0, 23]
];

DateObjectToAssociation[d_DateObject] := With[
	{keys = {"Year", "Month", "Day", "Hour"}},
	AssociationThread[keys -> DateValue[d, keys]]
];


ValidGTINQ[s_Integer] := ValidGTINQ[ToString[s]];
ValidGTINQ[s_String] /; StringMatchQ[s, Repeated[DigitCharacter, {3, Infinity}]] := With[
	{beforeCheckDigit = StringTake[s, ;; -2]},
	s === beforeCheckDigit <> GetGTINCheckDigit[beforeCheckDigit]
];
ValidGTINQ[_] := $Failed;

GetGTINCheckDigit[s_Integer] := GetGTINCheckDigit[ToString[s]];
GetGTINCheckDigit[s_String] /; StringMatchQ[s, Repeated[DigitCharacter, {2, Infinity}]] := Module[
	{digits, multTable},
	digits = ToExpression /@ Characters[s];
	multTable = Table[If[EvenQ[i], 1, 3], {i, Length[digits]}];
	ToString[Replace[10 - Mod[Reverse[digits] . multTable, 10], 10 -> 0]]
];
GetGTINCheckDigit[_] := $Failed;

End[];
EndPackage[];
