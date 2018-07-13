ClearAll["Utilities`EntityStore`*"];
ClearAll["Utilities`EntityStore`*`*"];

BeginPackage["Utilities`EntityStore`", {"Utilities`General`", "Utilities`GenerateData`"}];


LoadEntityStore::usage = "LoadEntityStore[root, directory] loads and registers the latest EntityStore from the given directory.";
UpdateEntityStore::usage = "UpdateEntityStore[root, directory, store] adds the given EntityStore to the given directory.";

EntityStoreBaseFileName::usage = "EntityStoreBaseFileName[_DateObject] generates a filename-friendly base file name to be used for EntityStores";

GenerateEntityStore::usage = "GenerateFoodEntityStore[root, type] generates a EntityStore from data stored in the type's directory";
StoredEntityFunction::usage = "StoredEntityFunction[f_Function][property] effectively stores the value of f like entity[property] = f[entity] if there are no failures";

Begin["`Private`"];

LoadEntityStore[root_CloudObject, type_String] := Module[
	{entityStoreObject, newStore},
	
	entityStoreObject = GetConfiguration[root, type <> "EntityStore"];
	If[Not @ MatchQ[entityStoreObject, _CloudObject],
		entityStoreObject = Check[
			First @ TakeLargestBy[CloudObjects[FileNameJoin[{root, type}]], FileDate, 1],
			Return[$Failed]
		];
	];
	newStore = Check[Import[entityStoreObject], $Failed];
	
	If[MatchQ[newStore, _EntityStore],
		EntityUnregister[type];
		EntityRegister[newStore],
		$Failed
	]
];


UpdateEntityStore[root_CloudObject, type_String] := UpdateEntityStore[root, type, Entity[type]["EntityStore"]];

UpdateEntityStore[root_CloudObject, type_String, store_EntityStore] := With[
	{
		newEntityStoreObject = CloudExport[
			store,
			"WXF",
			FileNameJoin[{root, type, EntityStoreBaseFileName[] <> ".WXF"}],
			Permissions -> "Public"
		]
	},
	SetConfiguration[root, type <> "EntityStore", newEntityStoreObject];
	newEntityStoreObject
];

EntityStoreBaseFileName[dateTime_DateObject: Now] := StringReplace[
	DateString[dateTime, "ISODateTime"],
	{"T" -> "_", ":" -> "-"}
];

GenerateEntityStore[root_CloudObject, type:"MyFood", descriptions: {__String}] := With[
	{nutrients = Keys @ GetConfiguration[root, "NutritionTargets"]},
	GenerateData[FileNameJoin[{Directory[], "Default", type}], descriptions, nutrients];
	GenerateEntityStore[root, "MyFood"]
];

GenerateEntityStore[root_CloudObject, "MyFood"] := Module[
	{foodData, nutrients},
	
	(* Import data from latest modified file *)
	foodData = Check[
		Import @ First @ TakeLargestBy[FileNames["*.m", {FileNameJoin[{"Default", "MyFood"}]}], FileDate, 1],
		Return[$Failed]
	];
	
	GenerateEntityStore[root, "MyFood", foodData]
];

GenerateEntityStore[root_CloudObject, type:"MyFood", foodData_Association] := With[
	{
		nutrients = Keys @ GetConfiguration[root, "NutritionTargets"]
	},
	EntityStore[
	"MyFood" -> <|
		"BaseEntityType" -> "FoodType",
		"Entities" -> foodData,
		"Properties" -> <|
			
			"Label" -> <|
				"DefaultFunction" -> StoredEntityFunction[FromCamelCase[#["CanonicalName"]]&]["Label"]
			|>,
			"Food" -> <|
				"DefaultFunction" -> StoredEntityFunction[SafeInterpreter["Food"][#["Label"]]&]["Food"]
			|>,
			"DateCreated" -> <||>,
			"DateModified" -> <||>,
			
			"ServingSizes" -> <||>,
			
			"ServingSizeString" -> <|
				"DefaultFunction" -> Function[""]
			|>,
			
			Sequence @@ Flatten[
				Function[{property},
					{
						property -> <|
							"DefaultFunction" -> EntityFramework`EntityPropertySequence["Food", property <> "ContentPerServing"]
						|>,
						{property, "Amount" -> _} -> <|
							"DefaultFunction" -> Function[{ent, quals},
								With[{factor = GetServingFactorFromAmountQualifier[ent, quals["Amount"]]},
									Replace[
										{ent[property], factor},
									(* TODO: Issue a message if amount is invalid? *)
										{{q_Quantity, n_?NumberQ} :> q * n, _ -> Missing["NotAvailable"]}
									]
								]
							]
						|>
					}
				] /@ nutrients[[All, 2]]
			],
			
			"NutritionAssociation" -> <|
				"DefaultFunction" -> Function[{entity},
					KeyMap[
						Last,
						EntityValue[entity, EntityPropertyClass["MyFood", "Nutrition"], "PropertyAssociation"]
					]
				]
			|>,
			{"NutritionAssociation", "Amount" -> _} -> <|
				"DefaultFunction" -> Function[{ent, quals},
					Module[{props},
						props = EntityPropertyClass["MyFood", "Nutrition"]["Properties"];
						props = Append[#, Normal[KeyTake[quals, "Amount"]]]& /@ props;
						EntityValue[ent, props, "PropertyAssociation"] // KeyMap[#[[2]]&]
					]
				]
			|>
		
		|>,
		"PropertyClasses" -> <|
			"Nutrition" -> <|
				"Label" -> "nutrition",
				"Properties" -> nutrients[[All, 2]]
			|>
		|>
	|>
]
];

Options[StoredEntityFunction] = {
	"FailurePattern" -> $Failed | _Failure
};
StoredEntityFunction[f_, OptionsPattern[]][prop_String][ent_Entity] := With[
	{failurePattern = OptionValue["FailurePattern"]},
	Check[Replace[f[ent], x : Except[failurePattern] :> (ent[prop] = x)], $Failed]
];

GenerateEntityStore[root_CloudObject, "MyMeal"] := Module[
	{mealData, nutrients, nutrientProperties},

	(* Import data from latest modified file *)
	mealData = Check[
		Import @ First @ TakeLargestBy[FileNames["*.m", {FileNameJoin[{"Default", "MyMeal"}]}], FileDate, 1],
		Return[$Failed]
	];
	
	nutrients = Keys @ GetConfiguration[root, "NutritionTargets"];
	nutrientProperties = nutrients[[All, 2]];
	
	GenerateEntityStore[root, "MyMeal", mealData]
];

GenerateEntityStore[root_CloudObject, "MyMeal", mealData_Association] := Module[
	{nutrients, nutrientProperties},
	
	nutrients = Keys @ GetConfiguration[root, "NutritionTargets"];
	nutrientProperties = nutrients[[All, 2]];
	
	EntityStore[
		"MyMeal" -> <|
			"BaseEntityType" -> "FoodType",
			"Entities" -> mealData,
			"Properties" -> <|
				"Label" -> <|
					"DefaultFunction" -> StoredEntityFunction[FromCamelCase[#["CanonicalName"]]&]["Label"]
				|>,
				"MealTypes" -> <||>,
				"ServingCount" -> <|
					"DefaultFunction" -> Function[1]
				|>,
				"Food" -> <||>,
				"Ingredients" -> <||>,
				
				Sequence @@ Flatten[
					Function[{property},
						{
							property -> <|
								"Label" -> FromCamelCase[property],
								"DefaultFunction" -> mealNutritionPropertyFunction[property]
							|>,
							{property, "Amounts" -> _} -> <|
								"DefaultFunction" -> Function[{entity, quals},
									Module[
										{amounts, ingredients, servingCount},
										
										servingCount = entity["ServingCount"];
										ingredients = entity["Ingredients"];
										If[Length[ingredients] < 1, Return[$Failed]];
										
										amounts = Replace[quals["Amounts"], a_Association :> Normal[a]];
										
										Switch[amounts,
											_?NumberQ | Quantity[_?NumberQ, "Servings"],
											amounts = Thread[
												Rule[
													ingredients[[All, 1]],
													ConstantArray[
														Replace[amounts, q_Quantity :> QuantityMagnitude[q]],
														Length[ingredients]
													]
												]
											];
											,
											
											{Rule[_String | Entity["MyFood", _String], _Quantity | _?NumberQ]...},
										(* Determine new factors *)
											amounts = With[
												{ent = Replace[#1, s_String :> Entity["MyFood", s]]},
												ent -> GetServingFactorFromAmountQualifier[ent, #2]
											]& @@@ amounts;
											
											(* Add in existing factors in case some are not specified *)
											amounts = Join[
												Cases[amounts, HoldPattern @ Rule[_, _?NumberQ]],
												Rule[#1, QuantityMagnitude[#2]]& @@@ ingredients
											] // DeleteDuplicatesBy[#, First]&;
											,
											
											_,
											Missing["NotAvailable"]
										];
										
										If[Not @ MatchQ[amounts, {Rule[_Entity, _?NumberQ]..}],
											Missing["NotAvailable"]
											,
											Total[DeleteMissing[#1[property, "Amount" -> #2]& @@@ amounts]] / servingCount
										]
									
									]
								]
							|>
						}
					] /@ nutrientProperties
				],
				
				"NutritionAssociation" -> <|
					"DefaultFunction" -> Function[{entity},
						KeyMap[
							Last,
							EntityValue[entity, EntityPropertyClass["MyMeal", "Nutrition"], "PropertyAssociation"]
						]
					]
				|>,
				{"NutritionAssociation", "Amounts" -> _} -> <|
					"DefaultFunction" -> Function[{ent, quals},
						Module[{props},
							props = EntityPropertyClass["MyMeal", "Nutrition"]["Properties"];
							props = Append[#, Normal[KeyTake[quals, "Amounts"]]]& /@ props;
							EntityValue[ent, props, "PropertyAssociation"] // KeyMap[#[[2]]&]
						]
					]
				|>
			|>,
			"PropertyClasses" -> <|
				"Nutrition" -> <|
					"Label" -> "nutrition",
					"Properties" -> nutrientProperties
				|>
			|>
		|>
	]
];

mealNutritionPropertyFunction[property_String] := Function[{meal},
	With[
		{
			ingredients = meal["Ingredients"],
			servingCount = Replace[meal["ServingCount"], Except[_?NumberQ] -> 1]
		},
		If[Length[ingredients] < 1,
			Return[Missing["NotApplicable"]]
		];
		Total[
			Times[
				EntityValue[ingredients[[All, 1]], property],
				Replace[
					{
						EntityInstance[ent_, Quantity[n_?NumberQ, "Servings"]] :> n,
						EntityInstance[ent_, q_Quantity] :> GetServingFactorFromAmountQualifier[ent, q]
					}
				] /@ ingredients
			] //  DeleteMissing[#, 1, 2]&
		] / servingCount
	]
];

GenerateEntityStore[root_CloudObject, ___] := $Failed;

End[];
EndPackage[];
