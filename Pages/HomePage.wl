ClearAll["Pages`HomePage`*"];
ClearAll["Pages`HomePage`*`*"];

BeginPackage["Pages`HomePage`", {"Utilities`General`"}];

DeployHomePage::usage = "";

Begin["`Private`"];

DeployHomePage[root_, opts: OptionsPattern[]] := CloudDeploy[
	Delayed[homePage[root], CachePersistence -> Quantity[2, "Hours"]],
	FileNameJoin[{root, "Home"}],
	opts
];

homePage[root_] := Module[
	{},
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	GalleryView[
		formatMenuItems @ {
			<|
				"Title" -> "Search for new foods",
				"Icon" -> Entity["Icon", "LaptopComputer"],
				"URL" -> FileNameJoin[{root, "FoodSearch"}]
			|>,
			<|
				"Title" -> "Look up new foods by code",
				"Icon" -> Entity["Icon", "SmartPhone"],
				"URL" -> FileNameJoin[{root, "FoodLookup"}]
			|>,
			<|
				"Title" -> "Add a new food manually",
				"Icon" -> Entity["Icon", "RetailLocation"],
				"URL" -> FileNameJoin[{root, "FoodEntry"}]
			|>,
			<|
				"Title" -> "Add a new meal",
				"Icon" -> Entity["Icon", "GroceryStoreAndSupermarket"],
				"URL" -> FileNameJoin[{root, "MealEntry"}]
			|>,
			
			<|
				"Title" -> "View foods",
				"Icon" -> Entity["Icon", "Store"],
				"URL" -> FileNameJoin[{root, "ViewFood"}]
			|>,
			<|
				"Title" -> "View meals",
				"Icon" -> Entity["Icon", "Library"],
				"URL" -> FileNameJoin[{root, "ViewMeal"}]
			|>,
			<|
				"Title" -> "View history",
				"Icon" -> Entity["Icon", "Watches"],
				"URL" -> FileNameJoin[{root, "ViewHistory"}]
			|>,
			<|
				"Title" -> "Log foods",
				"Icon" -> Entity["Icon", "FastFoodAndTakeOut"],
				"URL" -> FileNameJoin[{root, "ChooseFood"}]
			|>,
			
			
			<|
				"Title" -> "Log breakfast",
				"Icon" -> RandomChoice[mealTypeToIconEntities["Breakfast"]],
				"URL" -> URLBuild[FileNameJoin[{root, "ChooseMeal"}], {"mealType" -> "Breakfast"}]
			|>,
			<|
				"Title" -> "Log lunch",
				"Icon" -> RandomChoice[mealTypeToIconEntities["Lunch"]],
				"URL" -> URLBuild[FileNameJoin[{root, "ChooseMeal"}], {"mealType" -> "Lunch"}]
			|>,
			<|
				"Title" -> "Log dinner",
				"Icon" -> RandomChoice[mealTypeToIconEntities["Dinner"]],
				"URL" -> URLBuild[FileNameJoin[{root, "ChooseMeal"}], {"mealType" -> "Dinner"}]
			|>,
			<|
				"Title" -> "Log a meal",
				"Icon" -> Entity["Icon", "FoodService"],
				"URL" -> FileNameJoin[{root, "ChooseMeal"}]
			|>,
			
			
			<|
				"Title" -> "Scan a barcode",
				"Icon" -> Entity["Icon", "PhotographyStore"],
				"URL" -> FileNameJoin[{root, "ScanBarcode"}]
			|>,
			<|
				"Title" -> "Reminders",
				"Icon" -> Entity["Icon", "VolumeSymbol"],
				"URL" -> FileNameJoin[{root, "Reminders"}]
			|>,
			<|
				"Title" -> "Configure settings",
				"Icon" -> Entity["Icon", "Mechanic"],
				"URL" -> FileNameJoin[{root, "Settings"}]
			|>,
			<|
				"Title" -> "Meal recommendations (beta)",
				"Icon" -> Entity["Icon", "Library"],
				"URL" -> FileNameJoin[{root, "Suggestion"}]
			|>
			
		},
		AppearanceRules -> <|
			"Title" -> "Home Page",
			"Description" -> "Select a choice:"
		|>
	]
];

mealTypeToIconEntities = <|
	"Breakfast" -> {
		Entity["Icon", "Bakery"],
		Entity["Icon", "CoffeeShop"],
		Entity["Icon", "DoughnutShop"],
		Entity["Icon", "TeaShop"]
	},
	"Lunch" -> {
		Entity["Icon", "ChineseFastFoodAndTakeOut"],
		Entity["Icon", "FastFoodAndTakeOut"],
		Entity["Icon", "HamburgerRestaurant"],
		Entity["Icon", "PizzaRestaurant"],
		Entity["Icon", "SandwichShop"],
		Entity["Icon", "SnackBar"]
	},
	"Dinner" -> {
		Entity["Icon", "ChineseRestaurant"],
		Entity["Icon", "ButcherShop"],
		Entity["Icon", "FastFoodAndTakeOut"],
		Entity["Icon", "HamburgerRestaurant"],
		Entity["Icon", "PizzaRestaurant"],
		Entity["Icon", "SnackBar"],
		Entity["Icon", "Steakhouse"]
	},
	"Snack" -> {
		Entity["Icon", "FastFoodAndTakeOut"],
		Entity["Icon", "IceCreamAndFrozenYogurtShop"],
		Entity["Icon", "SnackBar"]
	},
	"Beverage" -> {
		Entity["Icon", "BarAndTavern"],
		Entity["Icon", "Bottles"],
		Entity["Icon", "CansOrBottles"],
		Entity["Icon", "CoffeeShop"],
		Entity["Icon", "DrinkingWater"]
	}
|>;

formatMenuItems[menuItems: {__Association}] := Module[
	{items, icons, iconToImage},
	items = formatMenuItem /@ menuItems;
	icons = DeleteDuplicates @ Cases[items, Entity["Icon", _], Infinity];
	iconToImage = EntityValue[icons, "Image", "EntityAssociation"];
	iconToImage = ReplaceAll[
		iconToImage,
		Graphics[first_, rest___] :> Graphics[
										{Orange, first},
										ImageSize -> {100, 100},
										Background -> None,
										Sequence @@ DeleteCases[{rest}, Rule[ImageSize | Background, _]]
									]
	];
	iconToImage = ExportForm[#, "PNG"]& /@ iconToImage;
	items /. iconToImage
];

formatMenuItem = With[
	{url = URLBuild @ #URL},
	Hyperlink[#, url]& /@ <|
		"Title" -> Style[#Title, Black],
		"Content" -> Lookup[#, "Icon", Entity["Icon", "LaboratoryAndTesting"]]
	|>
]&;



End[];
EndPackage[];