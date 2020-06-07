<?php 

$index = [];
$buffer = getDirIndex('./repo');
foreach ($buffer as $category) {
	$buffer[$category] = getDirIndex('./repo/'.$category);
	foreach ($buffer[$category] as $package) {
		$buffer[$category][$package] = getDirIndex('./repo/'.$category.'/'.$package);
		foreach ($buffer[$category][$package] as $version) {
			if (is_dir('./repo/'.$category.'/'.$package.'/'.$version)) {
				$index[$category][$package][$version] = getDirIndex('./repo/'.$category.'/'.$package.'/'.$version);
			}
		}
	}
}
unset($buffer);


?>