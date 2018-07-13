BeginTestSection["EntityStore"];

VerificationTest[
	Get["EntityStore.wl"],
	Null,
	TestID -> "Load-package"
];

VerificationTest[
	EntityStoreBaseFileName[DateObject[{2018, 3, 13, 11, 45, 20.7121412}, "Instant", "Gregorian", -5.]],
	"2018-03-13_11-45-20",
	TestID -> "EntityStoreBaseFileName-basic"
];

EndTestSection[];