ClearAll["Pages`SuggestionPage`*"];
ClearAll["Pages`SuggestionPage`*`*"];

BeginPackage["Pages`SuggestionPage`", {"Utilities`GenerateData`", "Utilities`General`", "Utilities`Suggestion`", "Utilities`EntityStore`"}];

DeploySuggestionPage::usage = "";

Begin["`Private`"];

DeploySuggestionPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	Delayed[
		Get[FileNameJoin[{root, "Pages", "SuggestionPage.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "GenerateData.wl"}]];
		SuggestionForm[root]
	],
	FileNameJoin[{root, "Suggestion"}],
	opts
];

SuggestionForm[root_CloudObject] := Module[
	{nutritionTargets},
	
	(* TODO: Use remaining nutrition for the day here instead? *)
	nutritionTargets = QuantityMagnitude /@ GetConfiguration[root, "NutritionTargets"];
	nutritionTargets = KeyDrop[nutritionTargets, "TotalProtein"];
	
	(* TODO: Show or allow customization of the limits/targets? *)
	nutritionTargets = KeyValueMap[CanonicalName[#1] -> (CanonicalName[#1]->QuantityMagnitude[#2])&, nutritionTargets];
	
	FormPage[
		{
			"MealTypes" -> <|
				"Interpreter" -> AnySubset[$MealTypes],
				"Label" -> "Meal Types",
				"Input" -> {"Breakfast", "Dinner"},
				"Control" -> TogglerBar
			|>,
			"Nutrients" -> <|
				"Interpreter" -> AnySubset[nutritionTargets],
				"Input" -> Values[KeyTake[nutritionTargets, {"TotalCalories", "TotalProtein"}]],
				"Control" -> TogglerBar
			|>,
			"Fuzz" -> <|
				"Interpreter" -> Restricted["Number", {0, 1}],
				"Input" -> 0.5,
				"Control" -> Slider
			|>
		},
		SuggestionAction[root],
		AppearanceRules -> <|
			"Title" -> "Meal Suggestion",
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]]
				}
			],
			"ItemLayout" -> "Vertical",
			"IncludedJS" -> StringTemplate[
				"
				function logButton(button, url, label) {
					const http = new XMLHttpRequest();
					var message = 'Are you sure you want to log this ';
					message = message.concat(label, '?');
					if (confirm(message)) {
						http.open('GET', url);
						http.send();
						
						button.onclick = '';
						button.style = 'color: black; opacity: 0.6; text-decoration: none;';
						button.innerHTML = 'Logged!';
					}
				}
				"][First[root]]
		|>
	]
];

SuggestionAction[root_] := Module[
	{bin, allData, mealTypeToEffectiveMealNutrition, nutritionTargets},
	
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
	Get[FileNameJoin[{root, "Utilities", "Suggestion.wl"}]];
	
	LoadEntityStore[root, "MyFood"];
	LoadEntityStore[root, "MyMeal"];
	
	nutritionTargets = QuantityMagnitude /@ GetConfiguration[root, "NutritionTargets"];
	nutritionTargets = KeyMap[CanonicalName, nutritionTargets];
	nutritionTargets = KeyTake[nutritionTargets, Keys[#Nutrients]];
	
	bin = GetConfiguration[root, "HistoryDatabin"];
	
	allData = Normal @ Dataset[bin];
	
	(* TODO: Feed meal types to consider? *)
	mealTypeToEffectiveMealNutrition = getEffectiveMealData[allData];
	
	(* TODO: Riffle in meal types? Allow bulk addition of groups of foods? *)
	suggestionLink[root] @ suggestMeals[mealTypeToEffectiveMealNutrition, nutritionTargets, #Fuzz, #MealTypes]
]&;

getEffectiveMealData[allData:{__Association}] := Module[
	{
		groupedData, mealTypeToEffectiveMeals, mealToNutritionData,
		effectiveMealToNutrition, mealTypeToEffectiveMealNutrition
	},
	
	groupedData = GroupBy[allData, {#MealType & -> KeyDrop["MealType"], DateObject[Take[DateList[#Timestamp], 3]] & -> KeyDrop["Timestamp"]}];
	
	mealTypeToEffectiveMeals = Values /@ Map[
		Flatten[#[[All, "Meal"]]] -> N[Total[KeyDrop[#, {"Meal", "TotalFiber"}]] /. _Missing -> 0] &,
		groupedData,
		{2}
	];
	
	mealToNutritionData = Join @@ Values[mealTypeToEffectiveMeals];
	effectiveMealToNutrition = KeyMap[Flatten, GroupBy[mealToNutritionData, normalizeEffectiveMeal[First[#]] & -> Last, First]];
	mealTypeToEffectiveMealNutrition = KeyTake[effectiveMealToNutrition, Replace[#, List[l_List] :> l, 2]] & /@ (normalizeEffectiveMeal /@ Keys[#] & /@ mealTypeToEffectiveMeals);
	
	(* TODO: Clean up the original data rather than this hack *)
	mealTypeToEffectiveMealNutrition = MapAt[
		KeyDrop[{{EntityInstance[Entity["MyFood", "MontereyJackCheese"], Quantity[1.`, "Servings"]], EntityInstance[Entity["MyFood", "NabiscoRitzCrackers"], Quantity[7, "Crackers" "Servings"]]}, {Entity["MyFood", "JustCrackAnEgg"]}}],
		mealTypeToEffectiveMealNutrition,
		{Key["Dinner"]}
	];
	
	mealTypeToEffectiveMealNutrition
];

(* TODO: Clean up the original data instead of this hack *)
myTotal[l : {Quantity[_?NumberQ, _] ..}] := Total[l /. {("Cups"*"Servings" | "Servings"*"Slices") -> "Servings", "Servings"*"Tablespoons" -> "Tablespoons", "Pieces"*"Servings" -> "Pieces"}];

normalizeEffectiveMeal = Replace[x : {EntityInstance[y_, _] ..} :> EntityInstance[y, myTotal[x[[All, 2]]]]] /@ Values[GroupBy[#, Replace[#, EntityInstance[a_, ___] :> a] &]] &;


suggestMeals[mealData_Association, nutritionTargets_Association, fuzz_?NumberQ, meals_List] := Module[
	{},
	(* TODO: In failure case, give a nicer message *)
	(* TODO: Attempt a few things, then give up? *)
	findDinner[
		1,
		(* TODO: Fraction of remaining nutrition or whatever should be a form field? *)
		(* TODO: Hook up leftover amounts for the day? *)
		0.5 * nutritionTargets,
		nutritionTargets,
		QuantityMagnitude[KeyTake[mealData, meals]],
		fuzz
	]
];

suggestionLink[root_CloudObject][l_List] := Grid[{suggestionLink[root][#]} & /@ l, Frame -> All];
suggestionLink[root_CloudObject][EntityGroup[l_List]] := Grid[suggestionLink[root][#] & /@ l];
suggestionLink[root_CloudObject][EntityInstance[e : Entity["MyMeal", meal_String], q : Quantity[s_, "Servings"]]] := Module[
	{url},
	url = URLBuild[
		FileNameJoin[{root, "ChooseMeal"}],
		{"meal" -> meal, "servingCount" -> s, "editQ" -> False}
	];
	{
		QuantityToString[q],
		Replace[e["Label"], Except[_String] -> meal],
		(* TODO: Use a better meal type and pass it at this point? *)
		EmbeddedHTML @ StringTemplate["<a style='cursor:pointer' onclick=\"return logButton(this, '``', 'meal')\">Log</a>"][url <> "&mode=submit"],
		NewTabHyperlink["Edit", url <> "&mode=none"]
	}
];
suggestionLink[root_CloudObject][EntityInstance[e : Entity["MyFood", food_String], q : Quantity[s_, "Servings"]]] := Module[
	{url},
	url = URLBuild[
		FileNameJoin[{root, "ServingSizeEntry"}],
		{
			"meal" -> "",
			"description" -> "Suggested Breakfast",
			(* TODO: Improve this? *)
			"mealType" -> "Breakfast",
			"foodToAmount" -> Compress @ <|e -> q|>,
			"timestamp" -> Compress @ DateObjectToAssociation[Now],
			"action" -> "log"
		}
	];
	{
		QuantityToString[q],
		Replace[e["Label"], Except[_String] -> food],
		EmbeddedHTML @ StringTemplate["<a style='cursor:pointer' onclick=\"return logButton(this, '``', 'food')\">Log</a>"][url<>"&mode=submit"],
		NewTabHyperlink["Edit", url<>"&mode=none"]
	}
];

End[];
EndPackage[];