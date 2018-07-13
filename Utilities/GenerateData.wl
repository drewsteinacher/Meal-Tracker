ClearAll["Utilities`GenerateData`*"];
ClearAll["Utilities`GenerateData`*`*"];

BeginPackage["Utilities`GenerateData`", {"Utilities`General`", "Utilities`EntityStore`"}];

GenerateData::usage = "GenerateData[directory_, foodDescriptions:{__String}, nutrients:{__Entity}]";

AddFoodEntry::usage = "AddFoodEntry[root][description, servingSize, nutrientData_Association]";
UpdateFoodEntry::usage = "UpdateFoodEntry[root][entity, description, servingSize, nutrientData_Association]";

AddMealEntry::usage = "AddMealEntry[root][description, mealType, foodToServings_Association]";
UpdateMealEntry::usage = "UpdateMealEntry[root][description, mealType, foodToServings_Association]";

LogMeal::usage = "LogMeal[root, meal_Entity, mealType_String, foodToServings_Association]";

Begin["`Private`"];

GenerateData::noparse = "Could not find a suitable Entity representation for \"``\"";

GenerateData[directory_, foodDescriptions_, nutrients_, servingSizes_: Automatic] := With[
	{fileContents = iGenerateData[foodDescriptions, nutrients, servingSizes]},
	exportFoodFileContents[directory, fileContents]
];


iGenerateData[foodDescription_String, nutrients_, servingSizes_: Automatic] :=
    iGenerateData[{foodDescription}, nutrients, servingSizes];

iGenerateData[foodDescriptions:{__String}, nutrients : {Entity["Nutrient", _String] ..}, servingSizes_: Automatic] := Module[
	{descriptionToEntity, descriptionToServingSize, descriptionToNutrientData},
	
	descriptionToEntity = getFoodRepresentations[foodDescriptions];
	descriptionToServingSize = If[MatchQ[servingSizes, {__Quantity}],
		AssociationThread[foodDescriptions -> servingSizes],
		getServingSizeData[descriptionToEntity]
	];
	descriptionToNutrientData = getNutritionData[descriptionToEntity, descriptionToServingSize, nutrients];
	
	makeFoodFileContents[
		foodDescriptions,
		Lookup[descriptionToEntity, foodDescriptions],
		Lookup[descriptionToServingSize, foodDescriptions],
		Lookup[descriptionToNutrientData, foodDescriptions]
	]
];

AddFoodEntry[root_CloudObject][description_String, args__] := With[
	{food = iAddFoodEntry[root][description, args]},
	food["DateCreated"] = Now;
	food["DateModified"] = Now;
	food
];

UpdateFoodEntry[root_CloudObject][entity: Entity["MyFood", _String], description_String, args__] := With[
	{food = iUpdateFoodEntry[root][entity, description, args]},
	food["DateModified"] = Now;
	food
];

iAddFoodEntry[root_CloudObject][description_String, servingSize_, nutrientData_] :=
    iAddFoodEntry[root][description, servingSize, nutrientData, SafeInterpreter["Food"][description]];

iAddFoodEntry[root_CloudObject][description_String, servingSize_, nutrientData_, entity_] := With[
	{fileContents = makeFoodFileContents[description, entity, servingSize, nutrientData]},
	addEntityDataForType["MyFood", Association @ fileContents];
	Entity["MyFood", ToCamelCase[description]]
];

iUpdateFoodEntry[root_CloudObject][foodEntity_Entity, description_String, servingSize_, nutrientData_, entity_] := With[
	{fileContents = makeFoodFileContents[foodEntity, description, entity, servingSize, nutrientData]},
	addEntityDataForType["MyFood", Association @ fileContents];
	foodEntity
];

getFoodRepresentations[s: {__String}] := Module[
	{representations},
	representations = SafeInterpreter["Food"][s];
	representations = AssociationThread[s -> representations];
	KeyValueMap[
		If[Not[validFoodEntityQ[#2]], Message[GenerateData::noparse, #1]]&,
		representations
	];
	Replace[Except[_Entity] -> Missing["NotAvailable"]] /@ representations
];

servingSizeDefault = Quantity[100, "Grams"];

getServingSizeData[descriptionToEntity_Association] := Module[
	{groupedByValidQ, validFoods, invalidFoods, servingSizeData},
	groupedByValidQ = GroupBy[descriptionToEntity, validFoodEntityQ];
	{validFoods, invalidFoods} = Lookup[groupedByValidQ, #, <||>]& /@ {True, False};
	servingSizeData = Join[
		AssociationThread[Keys[validFoods] -> EntityValue[Values @ validFoods, "DefaultServingSizeMass"]],
		AssociationThread[Keys[invalidFoods] -> ConstantArray[servingSizeDefault, Length[invalidFoods]]]
	];
	Replace[#, {Except[_Quantity] -> servingSizeDefault}]& /@ KeyTake[servingSizeData, Keys[descriptionToEntity]]
];

validFoodEntityQ[Entity["Food", _]] = True;
validFoodEntityQ[_] = False;


getNutritionData[descriptionToEntity_, descriptionToServingSize_, nutrients_] := Module[
	{propertyToNutrient, properties, entityInstances, nutritionData, groupedByValidQ, validFoods, invalidFoods, entityToDescription},
	
	propertyToNutrient = AssociationMap[EntityProperty["Food", "Absolute" <> # <> "Content"]&, nutrients[[All, 2]]];
	propertyToNutrient = AssociationMap[Reverse, propertyToNutrient];
	
	entityInstances = KeyValueMap[
		EntityInstance[#2, descriptionToServingSize @ #1]&,
		descriptionToEntity
	];
	
	groupedByValidQ = GroupBy[descriptionToEntity, validFoodEntityQ];
	{validFoods, invalidFoods} = Lookup[groupedByValidQ, #, <||>]& /@ {True, False};
	
	entityToDescription = AssociationMap[Reverse, descriptionToEntity];
	
	nutritionData = Join[
		KeyMap[
			Lookup[entityToDescription, First[#], #]&,
			EntityValue[
				KeyValueMap[EntityInstance[#2, descriptionToServingSize @ #1]&, validFoods],
				Keys[propertyToNutrient],
				"EntityPropertyAssociation"
			]
		],
		AssociationMap[AssociationThread[Keys[propertyToNutrient] -> Missing["NotAvailable"]]&, Keys[invalidFoods]]
	];
	nutritionData = KeyMap[propertyToNutrient] /@ nutritionData;
	
	nutritionData

];

makeFoodFileContents[foodDescriptions: {__String}, rest___] :=  Association[MapThread[makeFoodFileContents, {foodDescriptions, rest}]];
makeFoodFileContents[foodDescription_String, entity_, servingSize_, nutritionData_] := Rule[
	ToCamelCase[foodDescription],
	iMakeFoodFileContents[foodDescription, entity, servingSize, nutritionData]
];
makeFoodFileContents[foodEntity_Entity, foodDescription_String, entity_, servingSize_, nutritionData_] := Rule[
	CanonicalName[foodEntity],
	iMakeFoodFileContents[foodDescription, entity, servingSize, nutritionData]
];

iMakeFoodFileContents[foodDescription_String, entity_, servingSize_, nutritionData_] := <|
	"Label" -> foodDescription,
	"Food" -> entity,
	"ServingSizeString" -> servingSize,
	"ServingSizes" -> getServingSizesFromString[servingSize],
	Sequence @@ Normal[MapIndexed[processNutrientAmount, nutritionData]]
|>;

getServingSizesFromString[s_String] := Cases[ParseQuantity[StringSplit[s, ";"]], _Quantity];
getServingSizesFromString[x_Quantity] := {x};
getServingSizesFromString[n_?NumberQ] := {Quantity[n, "Servings"]};

(* TODO: Store the DailyValues away to avoid EntityValue call? *)
(* TODO: Handle user's qualifiers to get more accurate results *)
processNutrientAmount[Quantity[percent_?NumberQ, "Percent"], {Key[nutrient_String]}] := Replace[
	EntityValue[Entity["Nutrient", nutrient], "DailyValue"],
	{
		q_Quantity :> q * (percent / 100.) * Quantity[1, "Days"],
		_ -> Missing["NotAvailable"]
	}
];
processNutrientAmount[amount_, {Key[nutrient_String]}] := amount;


makeFoodID[s_String] := With[
	{
		baseFileName = StringReplace[ToLowerCase[s], Whitespace -> "-"],
		timeString = StringReplace[DateString["ISODateTime"], {"T" -> "_", ":" -> "-"}]
	},
	baseFileName <> "_" <> timeString <> ".m"
];

exportFoodFileContents[dir_, r_Rule] := exportFoodFileContents[dir, Association[r]];
exportFoodFileContents[dir_, fileContents_Association] :=
    Export[FileNameJoin[{dir, EntityStoreBaseFileName[] <> ".m"}], fileContents];

AddMealEntry[root_CloudObject][description_String, mealTypes_, servingCount_, foodToServings_Association] := With[
	{meal = iAddMealEntry[root][description, mealTypes, servingCount, foodToServings]},
	meal["DateCreated"] = Now;
	meal["DateModified"] = Now;
	meal
];

iAddMealEntry[root_CloudObject][description_String, mealTypes_, servingCount_, foodToServings_Association] := Module[
	{mealEntity, mealContents},
	
	mealEntity = Entity["MyMeal", ToCamelCase[description]];
	mealContents = makeMealFileContents[mealEntity, description, mealTypes, servingCount, foodToServings];
	
	addEntityDataForType["MyMeal", Association[Last[mealEntity] -> mealContents]];
	mealEntity
];


makeMealFileContents[mealEntity_Entity, description_String, mealTypes_List, servingCount_, foodToServings_Association] := <|
	"Label" -> description,
	"MealTypes" -> mealTypes,
	"ServingCount" -> servingCount,
	"Ingredients" -> KeyValueMap[
		EntityInstance[
			Entity["MyFood", #1],
			Quantity[GetServingFactorFromAmountQualifier[Entity["MyFood", #1], #2], "Servings"]
		]&,
		foodToServings
	]
|>;


addEntityDataForType[type_String, entityPropertyAssociation_Association] := KeyValueMap[
	Function[{ent, propertyAssociation},
		KeyValueMap[
			Function[{property, value},
				If[Not @ MatchQ[value, $Failed | _Failure],
					Entity[type, ent][property] = value;
					Entity[type, ent][property]
					,
					$Failed
				]
			],
			propertyAssociation
		]
	],
	entityPropertyAssociation
];

UpdateMealEntry[root_CloudObject][entity: Entity["MyMeal", _String], description_String, mealTypes_, servingCount_, foodToServings_Association] := With[
	{meal = iUpdateMealEntry[root][entity, description, mealTypes, servingCount, foodToServings]},
	meal["DateModified"] = Now;
	meal
];

iUpdateMealEntry[root_CloudObject][mealEntity_Entity, description_String, mealTypes_, servingCount_, foodToServings_Association] := With[
	{fileContents = makeMealFileContents[mealEntity, description, mealTypes, servingCount, foodToServings]},
	addEntityDataForType["MyMeal", Association[CanonicalName[mealEntity] -> fileContents]];
	mealEntity
];

LogMeal::invalidBin = "Invalid databin: ``";
LogMeal::invalidData = "Unable to add the following data: ``";

LogMeal[root_, foods_, servingCount_, mealType_, time_Association, rest___] :=
	LogMeal[root, foods, servingCount, mealType, AssociationToDateObject[time], rest];

LogMeal[root_CloudObject, mealEntity_String, rest___] := LogMeal[root, Entity["MyMeal", mealEntity], rest];

LogMeal[root_CloudObject, mealEntity : Entity["MyMeal", _], servingCount: _?NumberQ : 1, mealType_String : GetMealTypeFromTime[], time_DateObject : Now, foodToServings_Association : <||>] :=
	With[
		{
			historyBin = getHistoryBin[root],
			nutritionData = mealEntity["NutritionAssociation", "Amounts" -> Normal[foodToServings]]
		},
		logNutritionData[historyBin, mealEntity, mealType, Replace[q_Quantity :> q * servingCount] /@ nutritionData, time]
	];

LogMeal[root_CloudObject, foods : {Entity["MyFood", _]..}, servingCount: _?NumberQ: 1, mealType_String : GetMealTypeFromTime[], time_DateObject : Now] :=
	Module[
		{
			historyBin = getHistoryBin[root],
			nutritionData = EntityValue[foods, "NutritionAssociation"] // ReplaceAll[_Missing -> 0]
								// Merge[Total] // Map[Replace[0 -> Missing["NotAvailable"]]]
		},
		logNutritionData[historyBin, foods, mealType, Replace[q_Quantity :> q * servingCount] /@ nutritionData, time]
	];

LogMeal[root_CloudObject, foods : {Entity["MyFood", _]..}, servingCount: _?NumberQ : 1, mealType_String : GetMealTypeFromTime[], time_DateObject : Now, foodToServings_Association] :=
	Module[
		{
			historyBin = getHistoryBin[root],
			nutritionData = KeyValueMap[Entity["MyFood", #1]["NutritionAssociation", "Amount" -> #2]&, foodToServings]
								// ReplaceAll[_Missing -> 0] // Merge[Total] // Map[Replace[0 -> Missing["NotAvailable"]]]
		},
		logNutritionData[historyBin,
			KeyValueMap[
				With[{ent = Entity["MyFood", #1]},
					EntityInstance[ent, Quantity[GetServingFactorFromAmountQualifier[ent, #2], "Servings"]]
				]&,
				foodToServings
			],
			mealType,
			Replace[q_Quantity :> q * servingCount] /@ nutritionData, time]
	];

getHistoryBin[root_CloudObject] := With[
	{bin = GetConfiguration[root, "HistoryDatabin"]},
	If[Not @ MatchQ[bin, _Databin],
		Message[LogMeal::invalidBin, bin];
		Return[$Failed]
	];
	bin
];

logNutritionData[bin_Databin, meal_, mealType_, nutritionData_Association, time_DateObject] := With[
	{},
	Databin;
	DataDropClient`$JavaCompatibleQ = False;
    DatabinAdd[bin,
	    Join[
		    <|"Meal" -> meal, "MealType" -> mealType, "Timestamp" -> time|>,
		    Replace[Except[_Quantity] -> Missing["NotAvailable"]] /@ nutritionData
	    ]
    ]
];
logNutritionData[_, _, _, nutritionData_, _] := (Message[LogMeal::invalidData, nutritionData]; $Failed);

End[];

EndPackage[];
