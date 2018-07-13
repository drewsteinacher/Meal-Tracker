ClearAll["Pages`ViewFoodPage`*"];
ClearAll["Pages`ViewFoodPage`*`*"];

BeginPackage["Pages`ViewFoodPage`", {"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`"}];

DeployViewFoodPage::usage = "";

Begin["`Private`"];

DeployViewFoodPage[root_, opts : OptionsPattern[]] := CloudDeploy[
	Delayed[
		Get[FileNameJoin[{root, "MealTrackerApp.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
		Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
		foodGalleryView[root]
	],
	FileNameJoin[{root, "ViewFood"}],
	opts
];

foodGalleryView[root_] := Module[
	{foodData, nutritionProperties},
	
	LoadEntityStore[root, "MyFood"];
	nutritionProperties = Keys[GetConfiguration[root, "NutritionTargets"]][[All, 2]];
	
	foodData = EntityValue["MyFood", Join[{"Label", "ServingSizes", "DateModified"}, nutritionProperties], "EntityPropertyAssociation"];
	
	GalleryView[
		KeyValueMap[
			Function[{food, foodAssociation},
				Grid[
					List /@ {
						editHyperlink[root][food, #Label],
						Row[QuantityToString /@ #ServingSizes],
						Grid[
							KeyValueMap[
								{
									FromCamelCase[#1],
									QuantityToString[#2]
								}&,
								KeyTake[#, nutritionProperties]
							],
							Frame -> All
						],
						DateToString[#DateModified, "ISODateTime"],
						deleteFoodHyperlink[food]
					},
					Alignment -> Center,
					Frame -> True
				]&[foodAssociation]
			],
			foodData
		],
		AppearanceRules -> <|
			"Title" -> "View Foods",
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]],
					"Click on the food names to edit their information.",
					EmbeddedHTML[
						StringTemplate["
				<script>
				function confirmFoodRemoval(canonicalName) {
                    if (confirm('Are you sure you want to remove this food? This operation cannot be undone.')) {
                        var url = '``';
                        location.href = url.concat('&entity=', canonicalName);
                    }
				}
				</script>"][URLBuild[FileNameJoin[{root, "RemoveEntity"}], {"type" -> "MyFood"}]]
					]
				}
			]
		|>,
		Pagination -> {6, 2}
	]
];

editHyperlink[root_CloudObject][food : Entity["MyFood", _], label_String: "Click here to edit"] :=
	Hyperlink[
		label,
		URLBuild[
			FileNameJoin[{root, "NutritionEntry"}],
			<|
				"description" -> food["Label"],
				"entity" -> Compress[food],
				"servingSizeString" -> StringRiffle[QuantityToString /@ food["ServingSizes"], "; "],
				"action" -> "update"
			|> // DeleteMissing
		]
	
	];

deleteFoodHyperlink[Entity["MyFood", canonicalName_String]] :=
	EmbeddedHTML[
		StringTemplate[
			"<a style=\"cursor:pointer;\" onclick = \"confirmFoodRemoval('``')\">Delete</a>"
		][canonicalName]
	];

End[];
EndPackage[];