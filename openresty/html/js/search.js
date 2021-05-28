function search() {
	var input, filter, packagesList, packages, mercuryPackage, i, text;
	input = document.getElementById("searchBar");
	filter = input.value.toUpperCase();
	packagesList = document.getElementById("packagesList");
	packages = packagesList.getElementsByTagName("li");
	// Loop through all list items, and hide those who don't match the search query
	for (i = 0; i < packages.length; i++) {
		mercuryPackage = packages[i].getElementsByClassName("uk-card-title")[0];
		text = mercuryPackage.textContent || mercuryPackage.innerText;
		if (text.toUpperCase().indexOf(filter) > -1) {
			packages[i].style.display = "";
		} else {
			packages[i].style.display = "none";
		}
	}
}
