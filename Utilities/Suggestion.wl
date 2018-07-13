ClearAll["Utilities`Suggestion`*"];
ClearAll["Utilities`Suggestion`*`*"];

BeginPackage["Utilities`Suggestion`"];

suggestDinner::usage = "suggestDinner[<|\"Breakfast\" -> EntityGroup[{...}], \"Lunch\" -> EntityGroup[{...} |>]
Suggests a dinner based on your remaining dietary needs for the day.";

findDinner::usage = "";

Begin["`Private`"];

suggestDinner::invalidNutrientSpec = "The given nutrient specification was invalid: ``";

nutrientPattern = Entity["Nutrient", _String] | _String;

suggestDinner[a_Association ? validInputQ, dinnerData_Association] := Module[
	{
		nutrientTargets,
		accumulatedNutrition, remainingNutrition
	},

(* Process nutrient specifications given by user *)
(* TODO: Take into account user's age, gender, etc... *)
	nutrientTargets = getNutrientTargets[a["Nutrients"]];
	If[Not @ MatchQ[nutrientTargets, _Association ? (Length[#] > 0 &)],
		Message[suggestDinner::invalidNutrientSpec, a["Nutrients"]];
		Return[$Failed];
	];
	
	(* Get the nutrition from breakfast and lunch *)
	accumulatedNutrition = getNutrition[a, Keys[nutrientTargets]];
	
	(* Determine remaining nutrition for the day *)
	remainingNutrition = nutrientTargets - accumulatedNutrition;
	
	(* TODO: Determine optimal dinner suggestion *)
	getOptimalDinner[
		<|
			"NutritionDeficit" -> remainingNutrition,
			"NutritionTargets" -> nutrientTargets
		|>,
		dinnerData,
		Lookup[a, "Method", "DMcDonald"]
	]
];

suggestDinner[___] := $Failed;


validInputQ[a_Association] := MatchQ[Lookup[a, {"Breakfast", "Lunch"}], {Repeated[EntityGroup[{__EntityInstance}], {2}]}];


getNutrientTargets[nutrientSpec_, dietaryReferenceIntakeType_: "DailyValue"] := Module[
	{
		nutrients = getNutrients[nutrientSpec],
		nutrientTargets
	},
	
	nutrientTargets = Switch[nutrientSpec,
		_Missing | Automatic,
		<||>,
		
		_Association | {(Rule[nutrientPattern, _Quantity] | nutrientPattern)..},
		KeyMap[
			Replace[#, s_String :> Entity["Nutrient", s]]&,
			Association @ Cases[Normal[nutrientSpec], Rule[n:nutrientPattern, q_Quantity] :> Rule[n, q]]
		],
		
		_,
		Return[$Failed];
	];
	
	(* Default calorie target should be added if it isn't given *)
	If[MemberQ[nutrients, Entity["Nutrient", "TotalCalories"]] && KeyFreeQ[nutrientTargets, Entity["Nutrient", "TotalCalories"]],
		AssociateTo[nutrientTargets, Entity["Nutrient", "TotalCalories"] -> Quantity[2000., "LargeCalories" / "Days"]];
	];
	
	(* Get daily recommended values for any remaining nutrient properties *)
	If[Keys[nutrientTargets] =!= nutrients,
		AssociateTo[
			nutrientTargets,
			EntityValue[Complement[nutrients, Keys[nutrientTargets]], dietaryReferenceIntakeType, "EntityAssociation"]
		];
	];
	
	(* Make sure the targets are not in terms of days *)
	Replace[q:Quantity[_?NumberQ, unit_/; Not[FreeQ[unit, "Days"]]] :> q * Quantity[1, "Days"]] /@ nutrientTargets
];

getNutrientTargets[___] := $Failed;



getNutrients[_Missing | Automatic] := Entity["Nutrient", #] & /@ {"TotalCalories", "TotalProtein", "TotalCarbohydrates"};
getNutrients[assoc_Association] := Replace[#, n_String :> Entity["Nutrient", n]]& /@ Keys[assoc];
getNutrients[x_List] := Union[
	Cases[
		x,
		(Rule[n: nutrientPattern, _Quantity] | n: nutrientPattern) :> Replace[n, s_String :> Entity["Nutrient", s]]
	]
];
getNutrients[___] := $Failed;



getNutrition[a_Association, nutrients: {Entity["Nutrient", _String]..}] := With[
	{
		nutritionProperties = ("Absolute" <> # <> "Content") & /@ nutrients[[All, 2]]
	},
	Merge[
		EntityValue[#, nutritionProperties, "PropertyAssociation"] & /@ Lookup[a, {"Breakfast", "Lunch"}],
		Total
	] // KeyMap[Replace[#, s_String :> Entity["Nutrient", StringReplace[s, "Absolute" | "Content" -> ""]]]&]
];
getNutrition[___] := $Failed;




getOptimalDinner[a_Association ? validDinnerArgumentsQ, dinnerData_Association, method_String: "DMcDonald"] := Module[
	{
		deficit = QuantityMagnitude[KeyMap[Last, a["NutritionDeficit"]]]
	},
	
	If[Not @ MatchQ[dinnerData, _Association],
		Return[$Failed];
	];
	
	Switch[method,
		
		"MTrott",
		findDinner[1.1, deficit, QuantityMagnitude[KeyMap[Last, a["NutritionTargets"]]], dinnerData, 0.2],
		
		"DMcDonald" | _,
		selectDinners[dinnerData][deficit, 1., 3]
	]


];

getOptimalDinner[___] := $Failed;


validDinnerArgumentsQ[a_Association] := With[
	{
		arguments = Normal /@ Lookup[a, {"NutritionDeficit", "NutritionTargets"}]
	},
	And[
		SameQ @@ (Union[Keys[#]]& /@ arguments),
		SubsetQ[{"TotalCalories", "TotalFat", "TotalProtein", "TotalCarbohydrates", "TotalSugar", "VitaminC"}, Keys[First @ arguments][[All, 2]]],
		MatchQ[arguments, {Repeated[{Rule[Entity["Nutrient", _String], _Quantity]..}, {2}]}]
	]
];

validDinnerArgumentsQ[___] := False;

(* ****** MTrott's solution, made into a package by AndrewS ****** *)
findDinner[factor_, soFarToday_Association, dra_Association, dinnerData_Association, fuzz_?NumberQ] := Module[
	{
		allNutritionConstraints, res, m, b, coefficients, lp, \[Lambda], counter,
		properties, dinnerBreakdownCounts, pick
	},
	
	(* Work only with properties specified and given in the data *)
	properties = Intersection[Keys[soFarToday], Intersection @@ Keys[Flatten[Values[Values /@ dinnerData]]]];
	
	allNutritionConstraints = makeNutritionConstraint[#, factor, soFarToday, dra, dinnerData, fuzz] & /@ properties;
	allNutritionConstraints = DeleteCases[allNutritionConstraints, True];
	
	coefficients = Cases[allNutritionConstraints, _\[Alpha], \[Infinity]] // Union;
	
	\[Lambda] = Length[coefficients];
	
	m = Join[#, #] &[
		Table[Coefficient[allNutritionConstraints[[k]][[2]], coefficients], {k, Length[allNutritionConstraints]}]
	];
	
	b = Join[
		Table[{allNutritionConstraints[[k]][[1]], 1}, {k, Length[allNutritionConstraints]}],
		Table[{allNutritionConstraints[[k]][[3]], -1}, {k, Length[allNutritionConstraints]}]
	];
	
	counter = 0;
	dinnerBreakdownCounts = Values[Length /@ Reverse[dinnerData]];
	While[
		counter++;
		lp = Quiet[
			Check[
				LinearProgramming[RandomReal[{0, 1}, \[Lambda]], m, b, Table[{0, 1}, \[Lambda]], Integers],
				ConstantArray[0, \[Lambda]]
			],
			{LinearProgramming::lpsnf}
		];
		And[Not[validDinnerQ[lp, dinnerBreakdownCounts]], counter < 20]
	];
	
	If[validDinnerQ[lp, dinnerBreakdownCounts],
		
		res = Pick[coefficients, lp, 1];
		res = res /. {\[Alpha][p_, i_] :> {p, (Keys[dinnerData[p]][[i]])}};
		
		res = Replace[s_String :> Entity["Food", s]] /@ res[[All, 2]];
		res = Replace[l:{__Entity} :> (EntityInstance[#, Quantity[1, "Servings"]]& /@ l)] /@ res;
		res = Replace[l:{__EntityInstance} :> EntityGroup[l]] /@ res;
		,
		
		res = {}
	];
	
	res
];

validDinnerQ[lp_List, breakdown:{__Integer}] := With[
	{
		ranges = ({1, 0} + #) & /@ Partition[Insert[Accumulate[breakdown], 0, 1], 2, 1],
		n = Length[breakdown]
	},
	(* This might be too restrictive since not all meals will be eaten on their own (e.g. sides with meals) *)
	And[
		Total[lp] === n,
		(Union[Take[lp, #]]& /@ ranges) === ConstantArray[{0, 1}, n]
	]
];

makeNutritionConstraint[property_, factor_, soFar_Association, dra_Association, dinnerData_Association, fuzz_?NumberQ] := Module[
	{
		myBounds = First @ bounds[property, factor, soFar, dra, fuzz],
		sum
	},
	sum = Sum[
		Sum[
			\[Alpha][fg, i] * 1.5 * Replace[dinnerData[[fg, i, property]], _Missing -> 0.],
			{i, Length[dinnerData[fg]]}
		],
		{fg, Keys[dinnerData]}
	];
	If[Rationalize[sum] === 0,
		(-Infinity <= sum <= #2)& @@ myBounds,
		(#1 <= sum <= #2)& @@ myBounds
	] (*// Echo[#, property, Replace[LessEqual[a_, _, b_]:>Interval[{a, b}]]]&*)
];

bounds[t_, factor_, soFarToday_Association, dra_Association, fuzz_?NumberQ] := With[
	{
		f = factor (dra[t] - soFarToday[t])
	},
	Interval[
		f * {
			If[MemberQ[{"TotalSugar"}, t], -100, 1 - fuzz],
			If[MemberQ[{"VitaminC", "Protein"}, t], 3, 1 + fuzz]
		}
	]
];

(* ****** DMcDonald's solution ****** *)
selectDinners[foodInfo_][consumedNutrients_, humanFactor_, dinnerCount_: 1, groupToWeight0_Association, nutritionBounds_Association] :=
	Module[{lowerBoundedNutrients, upperBoundedNutrients, numericalLowerBoundedNutrients, numericalUpperBoundedNutrients, numericalFoodInfo,
		nutrientList, calBound,
		foodList, foodCount, dinnerCals, foodFactor, neededLowerBoundedNutrients, allowedUpperBoundedNutrients, typeServingLowerBound, servingLowerBoundList, allowedUpperBoundedNutrientRatio, overConsumedNutrientList, unitCost, unitCostVector, lowerBoundedNutrientList, upperBoundedNutrientList, nutrientsPerServingList, nutrientsPerServingMatrix, matrixBottom, inequalityVector, createServingList, lp, createDinner, generateDinners,
		continueQ,
		propertyList,
		propertyCount,
		groupToWeight = Join[Association @ Thread[Keys[consumedNutrients] -> 1./Length[Keys[consumedNutrients]]], groupToWeight0]
	},
		
		lowerBoundedNutrients = <||>(*(#/100.)& /@ nutritionBounds*)(*<|"TotalCalories" -> Quantity[2000., "LargeCalories"], "TotalProtein" -> Quantity[60., "Grams"], "VitaminC" -> Quantity[70., "Milligrams"], "TotalCarbohydrates" -> Quantity[200., "Grams"]|>*);
		upperBoundedNutrients = <||>(*nutritionBounds*);
		
		nutrientList = Keys[lowerBoundedNutrients] \[Union] Keys[upperBoundedNutrients];
		numericalLowerBoundedNutrients = QuantityMagnitude /@ lowerBoundedNutrients;
		numericalUpperBoundedNutrients = QuantityMagnitude /@ upperBoundedNutrients;
		
		numericalFoodInfo = Map[QuantityMagnitude] /@ (Join @@ Values[foodInfo]);
		
		propertyList = Values[Keys /@ foodInfo];
		propertyCount = Length /@ propertyList;
		
		foodList = Flatten[propertyList];
		foodCount = Length[foodList];
		
		calBound = humanFactor*numericalLowerBoundedNutrients["TotalCalories"];
		dinnerCals = Max[Min[calBound - consumedNutrients["TotalCalories"], calBound*2/3], calBound/4];
		foodFactor = (consumedNutrients["TotalCalories"] + dinnerCals)/numericalLowerBoundedNutrients["TotalCalories"];
		
		neededLowerBoundedNutrients = AssociationMap[Function[nutrient, foodFactor*numericalLowerBoundedNutrients[nutrient] - consumedNutrients[nutrient]], Keys[numericalLowerBoundedNutrients]];
		allowedUpperBoundedNutrients = AssociationMap[Function[nutrient, foodFactor*numericalUpperBoundedNutrients[nutrient] - consumedNutrients[nutrient]], Keys[upperBoundedNutrients]];
		
		typeServingLowerBound[foodTypeList_, factor_] := Function[food, Max[Round[Min[factor*dinnerCals/numericalFoodInfo[food]["TotalCalories"], 4*humanFactor]] - 1, 1]] /@ foodTypeList;
		servingLowerBoundList = Join @@ (typeServingLowerBound[#, Lookup[groupToWeight, #, 1./Length[propertyList]]]& /@ propertyList);
		
		allowedUpperBoundedNutrientRatio[nutrient_] := allowedUpperBoundedNutrients[nutrient]/(foodFactor*numericalUpperBoundedNutrients[nutrient]);
		overConsumedNutrientList = Select[Keys[upperBoundedNutrients], allowedUpperBoundedNutrientRatio[#] < .25 &] \[Union] {"TotalCalories"};
		
		unitCost[food_][overConsumedNutrient_] := N[numericalFoodInfo[food][overConsumedNutrient]/numericalUpperBoundedNutrients[overConsumedNutrient]];
		unitCostVector = Function[food, Total[unitCost[food] /@ overConsumedNutrientList]] /@ foodList;
		
		lowerBoundedNutrientList = Keys[neededLowerBoundedNutrients];
		upperBoundedNutrientList = Complement[Keys[allowedUpperBoundedNutrients], overConsumedNutrientList];
		
		nutrientsPerServingList[food_] := numericalFoodInfo[food] /@ (lowerBoundedNutrientList~Join~upperBoundedNutrientList);
		nutrientsPerServingMatrix = nutrientsPerServingList /@ foodList;
		
		matrixBottom = Transpose[
			Join @@ (MapIndexed[ConstantArray[Insert[ConstantArray[0, Length[propertyCount] - 1], 1, #2[[1]]], #1]& , propertyCount])
		];
		
		inequalityVector = Join[({neededLowerBoundedNutrients[#], 1} & /@ lowerBoundedNutrientList), ({allowedUpperBoundedNutrients[#], -1} & /@ upperBoundedNutrientList), ConstantArray[{1, 0}, 3]];
		
		createServingList := servingLowerBoundList + RandomInteger[2, foodCount];
		lp[servingList_] := LinearProgramming[servingList*unitCostVector, Transpose[servingList*nutrientsPerServingMatrix]~Join~matrixBottom, inequalityVector, ConstantArray[{0, 1}, foodCount], Integers];
		createDinner[servingList_] := With[{servingVector = Quiet[servingList * Check[lp[servingList], ConstantArray[0, foodCount]]]},
			Replace[
				MapThread[
					EntityInstance,
					{
						Entity["Food", #]& /@ Pick[foodList, servingVector, _?Positive],
						Quantity[#, "Servings"]& /@ Select[servingVector, Positive]
					}
				],
				{{} -> Nothing, x: {__EntityInstance} :> EntityGroup[x]}
			]
		];
		
		generateDinners[{dinnerList_, count_}] := {dinnerList \[Union] DeleteCases[{createDinner[createServingList]}, 0], count + 1};
		continueQ[{dinnerList_, count_}] := (Length[dinnerList] < dinnerCount) \[And] (count < 3*dinnerCount);
		First@NestWhile[generateDinners, {{}, 0}, continueQ]
	];

End[];

EndPackage[];